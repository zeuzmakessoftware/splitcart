import SwiftUI

struct CardStack: View {
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let items: [FoodSwipeItem]
    let savedItemIDs: Set<FoodSwipeItem.ID>
    let imageIndexes: [FoodSwipeItem.ID: Int]
    let onImageAdvance: (FoodSwipeItem, Bool) -> Void
    let onUndo: () -> Void
    let onToggleSave: (FoodSwipeItem) -> Void
    let onFeedback: (SwipeFeedback, FoodSwipeItem) -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Group {
            if let item = items.first {
                FeaturedCard(
                    item: item,
                    currentImageIndex: imageIndexes[item.id, default: 0],
                    isSaved: savedItemIDs.contains(item.id),
                    dragOffset: dragOffset,
                    onAdvanceImage: { forward in
                        onImageAdvance(item, forward)
                    },
                    onUndo: onUndo,
                    onToggleSave: {
                        onToggleSave(item)
                    },
                    onFeedback: { feedback in
                        triggerFeedback(feedback, for: item, in: cardWidth)
                    }
                )
                .frame(
                    width: cardWidth,
                    height: cardHeight + 67
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(x: dragOffset.width)
                .rotationEffect(.degrees(Double(dragOffset.width / 22)))
                .gesture(swipeGesture(for: item, width: cardWidth))
            } else {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: cardHeight + 67)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color(red: 0.97, green: 0.65, blue: 0.27))

            Text("Training queue complete")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Switch categories or undo a swipe to keep refining the recommendation model.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        )
    }

    private func swipeGesture(for item: FoodSwipeItem, width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let translation = value.translation.width
                let threshold = width * 0.24

                if translation > threshold {
                    triggerFeedback(.like, for: item, in: width)
                } else if translation < -threshold {
                    triggerFeedback(.pass, for: item, in: width)
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func triggerFeedback(_ feedback: SwipeFeedback, for item: FoodSwipeItem, in width: CGFloat) {
        let exitOffset = CGSize(
            width: feedback == .pass ? -(width * 1.15) : width * 1.15,
            height: 60
        )

        withAnimation(.easeIn(duration: 0.22)) {
            dragOffset = exitOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            onFeedback(feedback, item)
            dragOffset = .zero
        }
    }
}

#Preview {
    ContentView()
}
