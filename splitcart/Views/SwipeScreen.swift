import SwiftUI

enum SwipeCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case produce = "Produce"
    case protein = "Protein"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case snacks = "Snacks"
    case organic = "Organic"

    var id: String { rawValue }
}

struct FoodTag: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let text: String
}

struct FoodSwipeItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let restaurant: String
    let neighborhood: String
    let detail: String
    let priceText: String
    let matchScore: Int
    let imageURLs: [String]
    let tags: [FoodTag]
    let categories: [SwipeCategory]
    let note: String
}

enum SwipeFeedback {
    case pass
    case like
    case love
}

struct SwipeHistoryEntry {
    let itemID: FoodSwipeItem.ID
    let feedback: SwipeFeedback
}

struct SwipeScreen: View {
    @State private var selectedCategory: SwipeCategory = .all
    @State private var swipedItemIDs: [FoodSwipeItem.ID] = []
    @State private var likedItemIDs: Set<FoodSwipeItem.ID> = []
    @State private var lovedItemIDs: Set<FoodSwipeItem.ID> = []
    @State private var passedItemIDs: Set<FoodSwipeItem.ID> = []
    @State private var savedItemIDs: Set<FoodSwipeItem.ID> = []
    @State private var imageIndexes: [FoodSwipeItem.ID: Int] = [:]
    @State private var history: [SwipeHistoryEntry] = []
    @State private var isShowingReceiptFlow = false

    private let items = FoodSwipeItem.sampleData

    private var availableItems: [FoodSwipeItem] {
        items.filter { item in
            !swipedItemIDs.contains(item.id) &&
            (selectedCategory == .all || item.categories.contains(selectedCategory))
        }
    }

    private var remainingCount: Int {
        availableItems.count
    }

    private var likedCount: Int {
        likedItemIDs.count + lovedItemIDs.count
    }

    private var swipeBias: SwipePreferenceBias {
        SwipePreferenceBias.from(history: history, items: items)
    }

    private var demoCrew: [ReceiptFriendProfile] {
        ReceiptFriendProfile.demoCrew(adjustedBy: swipeBias)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundLayer()

                VStack(spacing: 18) {
                    TopBar(
                        selectedCategory: $selectedCategory,
                        likedCount: likedCount,
                        remainingCount: remainingCount
                    )
                    .padding(.top, 18)
                    .padding(.horizontal, 18)

                    CardStack(
                        cardWidth: min((geo.size.width - 36) * 0.74, 264),
                        cardHeight: min(geo.size.height * 0.61, 560),
                        items: Array(availableItems.prefix(1)),
                        savedItemIDs: savedItemIDs,
                        imageIndexes: imageIndexes,
                        onImageAdvance: advanceImage,
                        onUndo: undoLastSwipe,
                        onToggleSave: toggleSaved,
                        onFeedback: registerFeedback
                    )
                    .padding(.horizontal, 18)
                    .frame(maxHeight: .infinity)

                    BottomNav(
                        remainingCount: remainingCount,
                        likedCount: likedCount,
                        savedCount: savedItemIDs.count,
                        passedCount: passedItemIDs.count,
                        onScanTap: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                                isShowingReceiptFlow = true
                            }
                        }
                    )
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingReceiptFlow) {
            ReceiptSplitFlowView(
                groupBias: swipeBias,
                friends: demoCrew
            )
        }
    }

    private func advanceImage(for item: FoodSwipeItem, forward: Bool) {
        guard item.imageURLs.count > 1 else { return }
        let currentIndex = imageIndexes[item.id, default: 0]
        let nextIndex = forward
            ? min(currentIndex + 1, item.imageURLs.count - 1)
            : max(currentIndex - 1, 0)
        imageIndexes[item.id] = nextIndex
    }

    private func toggleSaved(for item: FoodSwipeItem) {
        if savedItemIDs.contains(item.id) {
            savedItemIDs.remove(item.id)
        } else {
            savedItemIDs.insert(item.id)
        }
    }

    private func registerFeedback(_ feedback: SwipeFeedback, for item: FoodSwipeItem) {
        guard !swipedItemIDs.contains(item.id) else { return }

        swipedItemIDs.append(item.id)
        history.append(SwipeHistoryEntry(itemID: item.id, feedback: feedback))

        switch feedback {
        case .pass:
            passedItemIDs.insert(item.id)
        case .like:
            likedItemIDs.insert(item.id)
        case .love:
            lovedItemIDs.insert(item.id)
        }
    }

    private func undoLastSwipe() {
        guard let lastEntry = history.popLast() else { return }

        swipedItemIDs.removeAll { $0 == lastEntry.itemID }

        switch lastEntry.feedback {
        case .pass:
            passedItemIDs.remove(lastEntry.itemID)
        case .like:
            likedItemIDs.remove(lastEntry.itemID)
        case .love:
            lovedItemIDs.remove(lastEntry.itemID)
        }
    }
}

extension FoodSwipeItem {
    static let sampleData: [FoodSwipeItem] = [
        FoodSwipeItem(
            name: "Organic Strawberries",
            restaurant: "Berry Ridge Farms",
            neighborhood: "Produce",
            detail: "2 lb clamshell, peak-season sweetness, ready to snack",
            priceText: "$6.49",
            matchScore: 94,
            imageURLs: [
                "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1518635017480-c9f5da2751e0?auto=format&fit=crop&w=1200&q=80"
            ],
            tags: [
                FoodTag(icon: "leaf.fill", text: "Organic"),
                FoodTag(icon: "heart.fill", text: "Sweet"),
                FoodTag(icon: "bolt.fill", text: "Vitamin C")
            ],
            categories: [.all, .produce, .organic],
            note: "A like here teaches the model you lean toward fresh fruit over packaged sweets."
        ),
        FoodSwipeItem(
            name: "Grass-Fed Ribeye",
            restaurant: "Butcher's Reserve",
            neighborhood: "Protein",
            detail: "14 oz cut with heavy marbling for high-heat searing",
            priceText: "$18.99",
            matchScore: 91,
            imageURLs: [
                "https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=1200&q=80"
            ],
            tags: [
                FoodTag(icon: "flame.fill", text: "Grill Ready"),
                FoodTag(icon: "figure.strengthtraining.traditional", text: "High Protein"),
                FoodTag(icon: "snowflake", text: "Fresh Cut")
            ],
            categories: [.all, .protein],
            note: "Useful for separating shoppers who prioritize premium proteins from lighter staples."
        ),
        FoodSwipeItem(
            name: "Roasted Garlic Pasta Sauce",
            restaurant: "Via Verona",
            neighborhood: "Pantry",
            detail: "24 oz glass jar, slow-cooked tomatoes, no added sugar",
            priceText: "$7.29",
            matchScore: 88,
            imageURLs: [
                "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80"
            ],
            tags: [
                FoodTag(icon: "shippingbox.fill", text: "Shelf Stable"),
                FoodTag(icon: "fork.knife", text: "Dinner Base"),
                FoodTag(icon: "carrot.fill", text: "Clean Label")
            ],
            categories: [.all, .pantry],
            note: "This helps the model learn whether you prefer practical pantry staples with a premium angle."
        ),
        FoodSwipeItem(
            name: "Frozen Mango Chunks",
            restaurant: "North Coast Freezer",
            neighborhood: "Frozen",
            detail: "Resealable bag, smoothie-ready, no sugar added",
            priceText: "$5.99",
            matchScore: 86,
            imageURLs: [
                "https://images.unsplash.com/photo-1638176066666-ffb2f013c7dd?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?auto=format&fit=crop&w=1200&q=80"
            ],
            tags: [
                FoodTag(icon: "snowflake", text: "Frozen"),
                FoodTag(icon: "cup.and.saucer.fill", text: "Smoothies"),
                FoodTag(icon: "leaf.fill", text: "No Sugar Added")
            ],
            categories: [.all, .frozen],
            note: "A positive swipe pushes recommendations toward easy-prep fruit and freezer staples."
        ),
        FoodSwipeItem(
            name: "Sea Salt Kettle Chips",
            restaurant: "Crave Works",
            neighborhood: "Snacks",
            detail: "Thick-cut potato chips with simple oil and sea salt",
            priceText: "$4.79",
            matchScore: 90,
            imageURLs: [
                "https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1585238342024-78d387f4a707?auto=format&fit=crop&w=1200&q=80"
            ],
            tags: [
                FoodTag(icon: "sparkles", text: "Crunchy"),
                FoodTag(icon: "bag.fill", text: "Party Snack"),
                FoodTag(icon: "drop.fill", text: "Classic Salted")
            ],
            categories: [.all, .snacks],
            note: "This clarifies whether your shopping pattern includes classic savory snacks."
        ),
        FoodSwipeItem(
            name: "Greek Yogurt Cups",
            restaurant: "Peak Culture",
            neighborhood: "Protein",
            detail: "12-pack sampler with vanilla, strawberry, and blueberry",
            priceText: "$9.49",
            matchScore: 95,
            imageURLs: [
                "https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1571212515416-fef01fc43637?auto=format&fit=crop&w=1200&q=80"
            ],
            tags: [
                FoodTag(icon: "figure.strengthtraining.traditional", text: "Protein"),
                FoodTag(icon: "heart.fill", text: "Breakfast"),
                FoodTag(icon: "cart.fill", text: "Family Pack")
            ],
            categories: [.all, .protein],
            note: "Helpful for learning whether you bias toward healthy repeat-buy staples."
        ),
        FoodSwipeItem(
            name: "Baby Spinach",
            restaurant: "Greenhouse Co-op",
            neighborhood: "Produce",
            detail: "Triple-washed clamshell for salads, smoothies, and sautés",
            priceText: "$3.99",
            matchScore: 89,
            imageURLs: [
                "https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1200&q=80"
            ],
            tags: [
                FoodTag(icon: "leaf.fill", text: "Fresh"),
                FoodTag(icon: "carrot.fill", text: "Salad Base"),
                FoodTag(icon: "heart.text.square.fill", text: "Everyday Buy")
            ],
            categories: [.all, .produce, .organic],
            note: "This gives the algorithm a signal about routine health-focused grocery choices."
        )
    ]
}
