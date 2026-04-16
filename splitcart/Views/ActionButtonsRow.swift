import SwiftUI

struct ActionButtonsRow: View {
    let onUndo: () -> Void
    let onPass: () -> Void
    let onLove: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void
    let isSaved: Bool

    var body: some View {
        HStack(spacing: 14) {
            button(systemName: "arrow.counterclockwise", diameter: 48, fill: .black.opacity(0.82), action: onUndo)
            button(systemName: "xmark", diameter: 54, fill: Color(red: 0.95, green: 0.28, blue: 0.34), action: onPass)
            button(systemName: "flame.fill", diameter: 54, fill: Color(red: 1.0, green: 0.55, blue: 0.17), action: onLove)
            button(systemName: "heart.fill", diameter: 54, fill: Color(red: 0.42, green: 0.92, blue: 0.48), action: onLike)
            button(
                systemName: isSaved ? "bookmark.fill" : "bookmark",
                diameter: 48,
                fill: Color(red: 0.14, green: 0.65, blue: 1.0),
                action: onSave
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func button(systemName: String, diameter: CGFloat, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            CircleActionButton(systemName: systemName, diameter: diameter, fill: fill)
        }
        .buttonStyle(.plain)
    }
}
