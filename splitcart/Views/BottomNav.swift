import SwiftUI

enum BottomTab {
    case swipe
    case likes
    case saved
    case friends
}

struct BottomNav: View {
    let selectedTab: BottomTab
    let remainingCount: Int
    let likedCount: Int
    let savedCount: Int
    let friendsCount: Int
    let onTabSelected: (BottomTab) -> Void
    let onScanTap: () -> Void

    @State private var pulse = false

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 8) {
                BottomNavItem(
                    icon: "hand.draw.fill",
                    title: "Swipe",
                    selected: selectedTab == .swipe,
                    badge: "\(remainingCount)",
                    action: { onTabSelected(.swipe) }
                )
                BottomNavItem(
                    icon: "heart.fill",
                    title: "Likes",
                    selected: selectedTab == .likes,
                    badge: likedCount == 0 ? nil : "\(likedCount)",
                    action: { onTabSelected(.likes) }
                )
                Color.clear.frame(width: 78)
                BottomNavItem(
                    icon: "bookmark.fill",
                    title: "Saved",
                    selected: selectedTab == .saved,
                    badge: savedCount == 0 ? nil : "\(savedCount)",
                    action: { onTabSelected(.saved) }
                )
                BottomNavItem(
                    icon: "person.crop.circle",
                    title: "Friends",
                    selected: selectedTab == .friends,
                    badge: friendsCount == 0 ? nil : "\(friendsCount)",
                    action: { onTabSelected(.friends) }
                )
            }
            .padding(.horizontal, 10)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.black.opacity(0.74))
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
            )

            Button(action: onScanTap) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.98, green: 0.53, blue: 0.2).opacity(pulse ? 0.16 : 0))
                            .frame(width: pulse ? 22 : 74, height: pulse ? 22 : 74)
                            .blur(radius: 10)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.78, blue: 0.36),
                                        Color(red: 0.97, green: 0.53, blue: 0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(0.28), lineWidth: 1)
                            }

                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.black.opacity(0.78))
                    }
                    .frame(width: 66, height: 66)
                    .shadow(color: .black.opacity(0.36), radius: 14, x: 0, y: 10)

                    Text("Scan")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -16)
        }
        .padding(.top, 12)
        .onAppear {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

#Preview {
    ContentView()
}
