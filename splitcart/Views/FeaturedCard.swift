import SwiftUI

struct FeaturedCard: View {
    let item: FoodSwipeItem
    let currentImageIndex: Int
    let isSaved: Bool
    let dragOffset: CGSize
    let onAdvanceImage: (Bool) -> Void
    let onUndo: () -> Void
    let onToggleSave: () -> Void
    let onFeedback: (SwipeFeedback) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                RemoteImageBackground(
                    imageURLs: item.imageURLs,
                    currentIndex: currentImageIndex
                )

                LinearGradient(
                    colors: [
                        .clear,
                        .clear,
                        .black.opacity(0.24),
                        .black.opacity(0.80),
                        .black.opacity(0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                PageDots(count: item.imageURLs.count, activeIndex: currentImageIndex)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    Text(item.restaurant.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                        .tracking(1.6)

                    Text(item.name)
                        .font(.system(size: 27, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 3)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Image(systemName: "basket.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.88))

                        Text("\(item.neighborhood) • \(item.priceText) • Match \(item.matchScore)%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text(item.detail)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                }
                .padding(.horizontal, 20)

                WrapChips(tags: item.tags)
                    .padding(.horizontal, 18)

                Text(item.note)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(.horizontal, 20)
                    .lineLimit(3)

                ActionButtonsRow(
                    onUndo: onUndo,
                    onPass: { onFeedback(.pass) },
                    onLove: { onFeedback(.love) },
                    onLike: { onFeedback(.like) },
                    onSave: onToggleSave,
                    isSaved: isSaved
                )
                    .padding(.horizontal, 18)
                    .padding(.top, 2)
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            swipeBadge(text: "PASS", color: .red, angle: -10)
                .opacity(dragOffset.width < 0 ? min(abs(dragOffset.width) / 120, 1) : 0)
                .padding(.leading, 24)
                .padding(.top, 66)
        }
        .overlay(alignment: .topTrailing) {
            swipeBadge(text: "LIKE", color: Color(red: 0.42, green: 0.92, blue: 0.48), angle: 10)
                .opacity(dragOffset.width > 0 ? min(abs(dragOffset.width) / 120, 1) : 0)
                .padding(.trailing, 24)
                .padding(.top, 66)
        }
        .overlay(alignment: .bottomTrailing) {
            CircleIconButton(
                systemName: isSaved ? "bookmark.fill" : "bookmark",
                size: 42,
                background: .black.opacity(0.38)
            )
                .padding(.trailing, 14)
                .padding(.bottom, 200)
                .onTapGesture(perform: onToggleSave)
        }
        .overlay {
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onAdvanceImage(false)
                    }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onAdvanceImage(true)
                    }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.bottom, 208)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 18)
    }

    private func swipeBadge(text: String, color: Color, angle: Double) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.black.opacity(0.45))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(color, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .rotationEffect(.degrees(angle))
    }
}

#Preview {
    ContentView()
}
