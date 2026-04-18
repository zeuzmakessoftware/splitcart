import Foundation

struct SwipePreferenceBias: Codable, Hashable {
    let categoryWeights: [String: Double]
    let tagWeights: [String: Double]

    static let neutral = SwipePreferenceBias(categoryWeights: [:], tagWeights: [:])

    static func from(history: [SwipeHistoryEntry], items: [FoodSwipeItem]) -> SwipePreferenceBias {
        guard !history.isEmpty else {
            return .neutral
        }

        let itemLookup = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        var categoryScores: [String: Double] = [:]
        var tagScores: [String: Double] = [:]

        for entry in history {
            guard let item = itemLookup[entry.itemID] else { continue }
            let delta = entry.feedback.biasDelta

            for category in item.categories where category != .all {
                let key = Self.normalize(category.rawValue)
                categoryScores[key, default: 0] += delta
            }

            for tag in item.tags {
                let key = Self.normalize(tag.text)
                tagScores[key, default: 0] += delta
            }
        }

        return SwipePreferenceBias(
            categoryWeights: normalizePositiveScores(categoryScores),
            tagWeights: normalizePositiveScores(tagScores)
        )
    }

    private static func normalizePositiveScores(_ scores: [String: Double]) -> [String: Double] {
        var normalized: [String: Double] = [:]

        for (key, value) in scores {
            let boosted = max(0, value)
            guard boosted > 0 else { continue }
            normalized[key] = min(1.25, round(boosted * 100) / 100)
        }

        return normalized
    }

    static func normalize(_ raw: String) -> String {
        let lowercased = raw.lowercased()
        let allowed = lowercased.map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            return "-"
        }
        var collapsed = String(allowed)
        while collapsed.contains("--") {
            collapsed = collapsed.replacingOccurrences(of: "--", with: "-")
        }
        collapsed = collapsed
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return collapsed.isEmpty ? "other" : collapsed
    }
}

extension SwipeFeedback {
    var biasDelta: Double {
        switch self {
        case .pass:
            return -0.65
        case .like:
            return 0.8
        case .love:
            return 1.2
        }
    }
}

struct ReceiptFriendProfile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let vibe: String
    let insight: String
    let categoryWeights: [String: Double]
    let tagWeights: [String: Double]
    let shareAffinity: Double

    static func demoCrew(adjustedBy bias: SwipePreferenceBias) -> [ReceiptFriendProfile] {
        baseCrew.map { profile in
            profile.applying(bias: bias)
        }
    }

    private func applying(bias: SwipePreferenceBias) -> ReceiptFriendProfile {
        ReceiptFriendProfile(
            id: id,
            name: name,
            vibe: vibe,
            insight: insight,
            categoryWeights: applying(categoryBias: bias.categoryWeights, to: categoryWeights, scale: 0.26),
            tagWeights: applying(categoryBias: bias.tagWeights, to: tagWeights, scale: 0.22),
            shareAffinity: min(1.2, shareAffinity + ((bias.tagWeights["shareable"] ?? 0) * 0.15))
        )
    }

    private func applying(categoryBias: [String: Double], to source: [String: Double], scale: Double) -> [String: Double] {
        var adjusted = source

        for (key, value) in categoryBias {
            adjusted[key, default: 0.18] = min(1.5, adjusted[key, default: 0.18] + (value * scale))
        }

        return adjusted
    }

    private static let baseCrew: [ReceiptFriendProfile] = [
        ReceiptFriendProfile(
            id: "maya",
            name: "Maya",
            vibe: "Fresh plates and lighter proteins",
            insight: "The swipe model keeps routing clean proteins, veggie-heavy sides, and lighter mains to Maya.",
            categoryWeights: [
                "produce": 1.15,
                "protein": 1.1,
                "organic": 0.95,
                "drinks": 0.45
            ],
            tagWeights: [
                "fresh": 1.2,
                "light": 1.05,
                "protein-forward": 1.0,
                "plant-forward": 0.85
            ],
            shareAffinity: 0.45
        ),
        ReceiptFriendProfile(
            id: "theo",
            name: "Theo",
            vibe: "Savory comfort orders",
            insight: "Theo absorbs the richer swipe signals: grilled mains, savory sides, and heavy comfort-food tags.",
            categoryWeights: [
                "protein": 1.25,
                "pantry": 0.95,
                "snacks": 0.8,
                "shared": 0.4
            ],
            tagWeights: [
                "savory": 1.15,
                "comfort-food": 1.1,
                "indulgent": 0.95,
                "grilled": 0.8
            ],
            shareAffinity: 0.6
        ),
        ReceiptFriendProfile(
            id: "riley",
            name: "Riley",
            vibe: "Snacks, sweets, and splitables",
            insight: "Riley gets the snacky side of the graph: desserts, share plates, caffeinated add-ons, and fun extras.",
            categoryWeights: [
                "snacks": 1.25,
                "dessert": 1.2,
                "drinks": 0.9,
                "shared": 1.0
            ],
            tagWeights: [
                "snacky": 1.2,
                "sweet": 1.1,
                "shareable": 1.15,
                "caffeinated": 0.75
            ],
            shareAffinity: 1.0
        ),
        ReceiptFriendProfile(
            id: "nova",
            name: "Nova",
            vibe: "Plant-forward and flexible",
            insight: "Nova is the safety valve for produce-heavy, organic, and plant-forward items that do not clearly belong elsewhere.",
            categoryWeights: [
                "produce": 1.0,
                "organic": 1.1,
                "frozen": 0.7,
                "shared": 0.65
            ],
            tagWeights: [
                "plant-forward": 1.15,
                "fresh": 0.95,
                "light": 0.8,
                "shareable": 0.55
            ],
            shareAffinity: 0.75
        )
    ]
}

struct ReceiptScanRequestPayload: Codable {
    let friends: [ReceiptFriendProfile]
    let groupBias: SwipePreferenceBias
}

struct ReceiptScanResponse: Codable, Hashable {
    let store: String
    let date: String
    let currency: String
    let items: [ReceiptLineItem]
    let matchedItems: [ReceiptMatchedItem]
    let friends: [ReceiptFriendSplit]
    let subtotal: Double
    let tax: Double
    let total: Double
    let summary: String
    let fairnessNotes: [String]

    var currencyCode: String {
        currency.isEmpty ? "USD" : currency.uppercased()
    }
}

struct ReceiptLineItem: Codable, Hashable, Identifiable {
    let name: String
    let price: Double
    let quantity: Int
    let category: String
    let preferenceTags: [String]
    let shareable: Bool

    var id: String {
        "\(name)-\(price)-\(quantity)"
    }
}

struct ReceiptMatchedItem: Codable, Hashable, Identifiable {
    let name: String
    let price: Double
    let quantity: Int
    let category: String
    let preferenceTags: [String]
    let shareable: Bool
    let assignedTo: [ReceiptItemAssignment]

    var id: String {
        "\(name)-\(price)-\(quantity)-matched"
    }
}

struct ReceiptItemAssignment: Codable, Hashable, Identifiable {
    let friendId: String
    let name: String
    let amount: Double
    let fraction: Double
    let reason: String

    var id: String {
        "\(friendId)-\(name)-\(amount)"
    }
}

struct ReceiptFriendSplit: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let vibe: String
    let insight: String
    let subtotal: Double
    let tax: Double
    let amount: Double
    let items: [ReceiptFriendAssignedItem]
}

struct ReceiptFriendAssignedItem: Codable, Hashable, Identifiable {
    let name: String
    let amount: Double
    let fraction: Double
    let reason: String

    var id: String {
        "\(name)-\(amount)"
    }
}

enum ReceiptFormatting {
    static func amount(_ value: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }
}
