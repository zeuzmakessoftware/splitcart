import SwiftUI

struct BottomNav: View {
    let remainingCount: Int
    let likedCount: Int
    let savedCount: Int
    let passedCount: Int

    var body: some View {
        HStack(spacing: 0) {
            BottomNavItem(icon: "hand.draw.fill", title: "Swipe", selected: true, badge: "\(remainingCount)")
            BottomNavItem(icon: "heart.fill", title: "Likes", selected: false, badge: likedCount == 0 ? nil : "\(likedCount)")
            BottomNavItem(icon: "bookmark.fill", title: "Saved", selected: false, badge: savedCount == 0 ? nil : "\(savedCount)")
            BottomNavItem(icon: "xmark.bin.fill", title: "Pass", selected: false, badge: passedCount == 0 ? nil : "\(passedCount)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.black.opacity(0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        )
    }
}
