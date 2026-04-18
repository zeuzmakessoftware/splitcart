import json
import os
import re
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from google import genai
from google.genai import types
from PIL import Image

RECEIPT_SCHEMA = {
    "type": "object",
    "properties": {
        "store": {"type": "string"},
        "date": {"type": "string"},
        "currency": {"type": "string"},
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "price": {"type": "number"},
                    "quantity": {"type": "integer"},
                    "category": {"type": "string"},
                    "preference_tags": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                    "shareable": {"type": "boolean"},
                },
                "required": [
                    "name",
                    "price",
                    "quantity",
                    "category",
                    "preference_tags",
                    "shareable",
                ],
            },
        },
        "subtotal": {"type": "number"},
        "tax": {"type": "number"},
        "total": {"type": "number"},
    },
    "required": ["store", "date", "currency", "items", "subtotal", "tax", "total"],
}

RECEIPT_PROMPT = """
Extract the receipt into JSON.

Rules:
- Return only a JSON object that matches the provided schema exactly.
- `price` is the full line-item amount charged for that row, not the single-unit price.
- `quantity` defaults to 1 when it is missing.
- `category` should be a short lowercase label that reflects the food type or order style.
- `preference_tags` should be 1-4 short lowercase habit descriptors such as `protein-forward`, `fresh`, `sweet`, `savory`, `shareable`, `plant-forward`, `snacky`, `comfort-food`, `caffeinated`, `indulgent`, or `light`.
- `shareable` should be true for platters, sides, appetizers, pitchers, combos, tasting portions, or anything that obviously feels shared.
- If store/date/currency are missing, return empty strings.
- If subtotal/tax/total are missing, return 0.
- Prices must be numbers, not strings.
- Ignore payment lines, discounts, taxes, cash, change, and tips as purchased items.
"""


def _load_client() -> genai.Client:
    load_dotenv(Path(__file__).with_name(".env"))

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("Missing GEMINI_API_KEY in .env")

    return genai.Client(api_key=api_key)


def _normalize_key(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-") or "other"


def _coerce_amount(value: Any) -> float:
    if isinstance(value, (int, float)):
        return round(float(value), 2)

    if isinstance(value, str):
        cleaned = value.replace("$", "").replace(",", "").strip()
        if not cleaned:
            return 0.0
        try:
            return round(float(cleaned), 2)
        except ValueError:
            return 0.0

    return 0.0


def _to_cents(value: float) -> int:
    return int(round(value * 100))


def _from_cents(value: int) -> float:
    return round(value / 100, 2)


def _split_cents(total_cents: int, parts: int) -> list[int]:
    if parts <= 0:
        return []

    base = total_cents // parts
    remainder = total_cents % parts
    return [base + (1 if index < remainder else 0) for index in range(parts)]


def _sanitize_receipt(payload: dict[str, Any]) -> dict[str, Any]:
    items: list[dict[str, Any]] = []

    for raw_item in payload.get("items", []):
        name = str(raw_item.get("name") or "").strip() or "Unknown item"

        try:
            quantity = max(int(raw_item.get("quantity") or 1), 1)
        except (TypeError, ValueError):
            quantity = 1

        price = max(_coerce_amount(raw_item.get("price")), 0.0)
        category = _normalize_key(str(raw_item.get("category") or "other"))

        tags: list[str] = []
        for raw_tag in raw_item.get("preference_tags") or []:
            normalized_tag = _normalize_key(str(raw_tag))
            if normalized_tag not in tags:
                tags.append(normalized_tag)

        shareable = bool(raw_item.get("shareable")) or quantity > 1 or category == "shared"

        items.append(
            {
                "name": name,
                "price": price,
                "quantity": quantity,
                "category": category,
                "preference_tags": tags,
                "shareable": shareable,
            }
        )

    subtotal = max(_coerce_amount(payload.get("subtotal")), 0.0)
    if subtotal == 0.0 and items:
        subtotal = round(sum(item["price"] for item in items), 2)

    tax = max(_coerce_amount(payload.get("tax")), 0.0)
    total = max(_coerce_amount(payload.get("total")), 0.0)
    if total == 0.0:
        total = round(subtotal + tax, 2)

    return {
        "store": str(payload.get("store") or "").strip(),
        "date": str(payload.get("date") or "").strip(),
        "currency": str(payload.get("currency") or "").strip(),
        "items": items,
        "subtotal": subtotal,
        "tax": tax,
        "total": total,
    }


def _normalize_weights(payload: dict[str, Any] | None) -> dict[str, float]:
    normalized: dict[str, float] = {}

    if not payload:
        return normalized

    for key, value in payload.items():
        try:
            numeric_value = max(float(value), 0.0)
        except (TypeError, ValueError):
            continue
        normalized[_normalize_key(str(key))] = round(numeric_value, 3)

    return normalized


def _normalize_friend_profiles(friends: list[dict[str, Any]]) -> list[dict[str, Any]]:
    normalized: list[dict[str, Any]] = []

    for index, friend in enumerate(friends):
        normalized.append(
            {
                "id": str(friend.get("id") or f"friend-{index + 1}"),
                "name": str(friend.get("name") or f"Friend {index + 1}"),
                "vibe": str(friend.get("vibe") or "").strip(),
                "insight": str(friend.get("insight") or "").strip(),
                "category_weights": _normalize_weights(friend.get("category_weights")),
                "tag_weights": _normalize_weights(friend.get("tag_weights")),
                "share_affinity": max(float(friend.get("share_affinity") or 0.4), 0.0),
            }
        )

    if not normalized:
        raise ValueError("At least one friend profile is required")

    return normalized


def _normalize_group_bias(payload: dict[str, Any] | None) -> dict[str, dict[str, float]]:
    return {
        "category_weights": _normalize_weights((payload or {}).get("category_weights")),
        "tag_weights": _normalize_weights((payload or {}).get("tag_weights")),
    }


def itemize_receipt(receipt_path: str) -> dict[str, Any]:
    receipt_file = Path(receipt_path)
    if not receipt_file.exists():
        raise FileNotFoundError(f"Receipt file not found: {receipt_path}")

    client = _load_client()
    image = Image.open(receipt_file)

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[RECEIPT_PROMPT, image],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=RECEIPT_SCHEMA,
            temperature=0,
        ),
    )

    return _sanitize_receipt(json.loads(response.text))


def _score_friend_for_item(
    item: dict[str, Any],
    friend: dict[str, Any],
    group_bias: dict[str, dict[str, float]],
    current_subtotal_cents: int,
) -> float:
    category = item["category"]
    tags = item["preference_tags"]

    category_weight = friend["category_weights"].get(category, 0.15)
    tag_score = sum(friend["tag_weights"].get(tag, 0.0) for tag in tags)
    group_boost = category_weight * group_bias["category_weights"].get(category, 0.0) * 0.45
    tag_boost = sum(
        friend["tag_weights"].get(tag, 0.0) * group_bias["tag_weights"].get(tag, 0.0) * 0.28
        for tag in tags
    )
    share_bonus = friend["share_affinity"] * 0.3 if item["shareable"] else 0.0
    balance_penalty = current_subtotal_cents / 6000.0

    return round(1.0 + (category_weight * 1.6) + (tag_score * 1.1) + group_boost + tag_boost + share_bonus - balance_penalty, 4)


def _match_reason(item: dict[str, Any], friend: dict[str, Any]) -> str:
    reasons: list[str] = []

    category = item["category"]
    if friend["category_weights"].get(category, 0.0) >= 0.85:
        reasons.append(category.replace("-", " "))

    strong_tags = [
        tag.replace("-", " ")
        for tag in item["preference_tags"]
        if friend["tag_weights"].get(tag, 0.0) >= 0.75
    ]
    reasons.extend(strong_tags[:2])

    if item["shareable"] and not reasons:
        reasons.append("shareable order")

    if not reasons:
        reasons.append("overall swipe fit")

    return "Matched on " + ", ".join(reasons[:2])


def _group_friend_items(assignments: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, dict[str, Any]] = {}

    for assignment in assignments:
        bucket = grouped.setdefault(
            assignment["name"],
            {
                "name": assignment["name"],
                "amount_cents": 0,
                "fraction": 0.0,
                "reason": assignment["reason"],
            },
        )
        bucket["amount_cents"] += assignment["amount_cents"]
        bucket["fraction"] += assignment["fraction"]

    result: list[dict[str, Any]] = []
    for bucket in grouped.values():
        result.append(
            {
                "name": bucket["name"],
                "amount": _from_cents(bucket["amount_cents"]),
                "fraction": round(min(bucket["fraction"], 1.0), 2),
                "reason": bucket["reason"],
            }
        )

    return sorted(result, key=lambda entry: entry["amount"], reverse=True)


def _distribute_proportionally(total_cents: int, weights: list[int]) -> list[int]:
    if total_cents <= 0 or not weights:
        return [0 for _ in weights]

    total_weight = sum(weights)
    if total_weight <= 0:
        return _split_cents(total_cents, len(weights))

    raw_values = [(total_cents * weight) / total_weight for weight in weights]
    floors = [int(value) for value in raw_values]
    remainder = total_cents - sum(floors)

    ranked_remainders = sorted(
        range(len(raw_values)),
        key=lambda index: raw_values[index] - floors[index],
        reverse=True,
    )

    for index in ranked_remainders[:remainder]:
        floors[index] += 1

    return floors


def split_receipt_by_preferences(
    receipt: dict[str, Any],
    friends: list[dict[str, Any]],
    group_bias: dict[str, Any] | None = None,
) -> dict[str, Any]:
    normalized_friends = _normalize_friend_profiles(friends)
    normalized_bias = _normalize_group_bias(group_bias)

    allocations: dict[str, dict[str, Any]] = {
        friend["id"]: {
            "subtotal_cents": 0,
            "items": [],
        }
        for friend in normalized_friends
    }

    matched_items: list[dict[str, Any]] = []

    for item in receipt["items"]:
        line_total_cents = _to_cents(item["price"])
        if line_total_cents <= 0:
            continue

        line_assignments: dict[str, dict[str, Any]] = {}

        if item["shareable"] and item["quantity"] == 1 and len(normalized_friends) > 1:
            ranked = sorted(
                normalized_friends,
                key=lambda friend: _score_friend_for_item(
                    item,
                    friend,
                    normalized_bias,
                    allocations[friend["id"]]["subtotal_cents"],
                ),
                reverse=True,
            )
            share_count = min(2, len(ranked))
            share_cents = _split_cents(line_total_cents, share_count)

            for friend, amount_cents in zip(ranked[:share_count], share_cents):
                reason = _match_reason(item, friend)
                allocations[friend["id"]]["subtotal_cents"] += amount_cents
                allocations[friend["id"]]["items"].append(
                    {
                        "name": item["name"],
                        "amount_cents": amount_cents,
                        "fraction": round(amount_cents / line_total_cents, 2),
                        "reason": reason,
                    }
                )
                line_assignments[friend["id"]] = {
                    "friend_id": friend["id"],
                    "name": friend["name"],
                    "amount": _from_cents(amount_cents),
                    "fraction": round(amount_cents / line_total_cents, 2),
                    "reason": reason,
                }
        else:
            unit_amounts = _split_cents(line_total_cents, max(item["quantity"], 1))

            for unit_cents in unit_amounts:
                ranked = sorted(
                    normalized_friends,
                    key=lambda friend: _score_friend_for_item(
                        item,
                        friend,
                        normalized_bias,
                        allocations[friend["id"]]["subtotal_cents"],
                    ),
                    reverse=True,
                )
                chosen_friend = ranked[0]
                reason = _match_reason(item, chosen_friend)
                allocations[chosen_friend["id"]]["subtotal_cents"] += unit_cents
                allocations[chosen_friend["id"]]["items"].append(
                    {
                        "name": item["name"],
                        "amount_cents": unit_cents,
                        "fraction": round(unit_cents / line_total_cents, 2),
                        "reason": reason,
                    }
                )

                if chosen_friend["id"] in line_assignments:
                    line_assignments[chosen_friend["id"]]["amount"] = round(
                        line_assignments[chosen_friend["id"]]["amount"] + _from_cents(unit_cents),
                        2,
                    )
                    line_assignments[chosen_friend["id"]]["fraction"] = round(
                        min(line_assignments[chosen_friend["id"]]["fraction"] + (unit_cents / line_total_cents), 1.0),
                        2,
                    )
                else:
                    line_assignments[chosen_friend["id"]] = {
                        "friend_id": chosen_friend["id"],
                        "name": chosen_friend["name"],
                        "amount": _from_cents(unit_cents),
                        "fraction": round(unit_cents / line_total_cents, 2),
                        "reason": reason,
                    }

        matched_items.append(
            {
                "name": item["name"],
                "price": item["price"],
                "quantity": item["quantity"],
                "category": item["category"],
                "preference_tags": item["preference_tags"],
                "shareable": item["shareable"],
                "assigned_to": list(line_assignments.values()),
            }
        )

    subtotal_weights = [allocations[friend["id"]]["subtotal_cents"] for friend in normalized_friends]
    tax_distribution = _distribute_proportionally(_to_cents(receipt["tax"]), subtotal_weights)

    friend_summaries: list[dict[str, Any]] = []
    for index, friend in enumerate(normalized_friends):
        subtotal_cents = allocations[friend["id"]]["subtotal_cents"]
        tax_cents = tax_distribution[index]
        friend_summaries.append(
            {
                "id": friend["id"],
                "name": friend["name"],
                "vibe": friend["vibe"],
                "insight": friend["insight"],
                "subtotal": _from_cents(subtotal_cents),
                "tax": _from_cents(tax_cents),
                "amount": _from_cents(subtotal_cents + tax_cents),
                "items": _group_friend_items(allocations[friend["id"]]["items"]),
            }
        )

    shared_items = sum(1 for item in matched_items if len(item["assigned_to"]) > 1)
    summary = (
        f"Matched {len(matched_items)} receipt lines to {len(friend_summaries)} swipe profiles"
        f" with {shared_items} shared item{'s' if shared_items != 1 else ''}."
    )

    fairness_notes = [
        "Tax is distributed in proportion to each person's assigned subtotal.",
        "Shared items are split across the strongest matching diners instead of forcing one owner.",
    ]

    result = dict(receipt)
    result["matched_items"] = matched_items
    result["friends"] = friend_summaries
    result["summary"] = summary
    result["fairness_notes"] = fairness_notes
    return result


def scan_and_split_receipt(
    receipt_path: str,
    friends: list[dict[str, Any]],
    group_bias: dict[str, Any] | None = None,
) -> dict[str, Any]:
    receipt = itemize_receipt(receipt_path)
    return split_receipt_by_preferences(receipt, friends=friends, group_bias=group_bias)


def main() -> None:
    test_receipt = "receipt.jpg"

    try:
        result = itemize_receipt(test_receipt)
        print(json.dumps(result, indent=2))
    except Exception as exc:
        print(f"Error: {exc}")


if __name__ == "__main__":
    main()
