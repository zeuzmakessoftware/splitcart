import SwiftUI

struct WrapChips: View {
    let tags: [FoodTag]

    var body: some View {
        WrappingHStack(itemSpacing: 8, lineSpacing: 8) {
            ForEach(tags) { tag in
                TagChip(icon: tag.icon, text: tag.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WrappingHStack: Layout {
    var itemSpacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let availableWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentRowWidth == 0
                ? size.width
                : currentRowWidth + itemSpacing + size.width

            if nextWidth > availableWidth, currentRowWidth > 0 {
                maxRowWidth = max(maxRowWidth, currentRowWidth)
                totalHeight += currentRowHeight + lineSpacing
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth = nextWidth
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }

        maxRowWidth = max(maxRowWidth, currentRowWidth)
        totalHeight += currentRowHeight

        return CGSize(
            width: proposal.width ?? maxRowWidth,
            height: totalHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextX = x == bounds.minX ? x + size.width : x + itemSpacing + size.width

            if nextX > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }

            let originX = x == bounds.minX ? x : x + itemSpacing
            subview.place(
                at: CGPoint(x: originX, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x = originX + size.width
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    ContentView()
}
