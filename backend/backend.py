import os
import json
from pathlib import Path

from dotenv import load_dotenv
from PIL import Image
from google import genai
from google.genai import types


def itemize_receipt(receipt_path: str):
    load_dotenv(Path(__file__).with_name(".env"))

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("Missing GEMINI_API_KEY in .env")

    receipt_file = Path(receipt_path)
    if not receipt_file.exists():
        raise FileNotFoundError(f"Receipt file not found: {receipt_path}")

    image = Image.open(receipt_file)
    client = genai.Client(api_key=api_key)

    schema = {
    "type": "object",
    "properties": {
        "store": {"type": "string"},
        "date": {"type": "string"},
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "price": {"type": "number"},
                    "quantity": {"type": "integer"},
                },
                "required": ["name", "price", "quantity"],
            },
        },
        "subtotal": {"type": "number"},
        "tax": {"type": "number"},
        "total": {"type": "number"},
    },
    "required": ["store", "date", "items", "subtotal", "tax", "total"],
}

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            """Extract the receipt into JSON.

Rules:
- Return only the JSON object.
- Use the provided schema exactly.
- quantity is the number shown before the item name if present.
- If store is missing, return "".
- If date is missing, return "".
- If subtotal/tax are missing, return 0.
- Prices must be numbers, not strings.
- Ignore CASH and CHANGE as purchased items.
""",
            image,
        ],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=schema,
            temperature=0,
        ),
    )

    return json.loads(response.text)


def main():
    test_receipt = "receipt.jpg"

    try:
        result = itemize_receipt(test_receipt)
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()