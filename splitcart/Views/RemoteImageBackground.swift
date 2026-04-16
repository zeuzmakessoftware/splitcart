import SwiftUI

struct RemoteImageBackground: View {
    let imageURLs: [String]
    let currentIndex: Int

    var body: some View {
        AsyncImage(url: currentURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color(red: 0.36, green: 0.20, blue: 0.09).opacity(0.55),
                                .clear,
                                .clear,
                                Color(red: 0.22, green: 0.08, blue: 0.10).opacity(0.40)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            case .failure(_):
                fallbackView
            case .empty:
                fallbackView.redacted(reason: .placeholder)
            @unknown default:
                fallbackView
            }
        }
    }

    private var currentURL: URL? {
        guard imageURLs.indices.contains(currentIndex) else { return nil }
        return URL(string: imageURLs[currentIndex])
    }

    private var fallbackView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.22, blue: 0.12),
                    Color(red: 0.11, green: 0.08, blue: 0.07),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(red: 0.18, green: 0.13, blue: 0.09))
                    .frame(height: 180)
                    .blur(radius: 2)
            }

            VStack {
                Spacer()
                ZStack {
                    Ellipse()
                        .fill(Color(red: 0.84, green: 0.80, blue: 0.74))
                        .frame(width: 240, height: 130)
                        .blur(radius: 0.3)
                        .offset(y: 60)

                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.88, green: 0.48, blue: 0.62))
                                .frame(width: 114, height: 114)

                            Circle()
                                .fill(Color(red: 0.94, green: 0.61, blue: 0.71))
                                .frame(width: 94, height: 94)
                                .offset(x: 8, y: -4)
                        }

                        HStack(spacing: 12) {
                            Circle().fill(Color.red.opacity(0.85)).frame(width: 14, height: 14)
                            Circle().fill(Color.red.opacity(0.95)).frame(width: 12, height: 12)
                            Circle().fill(Color.red.opacity(0.88)).frame(width: 13, height: 13)
                        }
                    }
                    .offset(y: 42)
                }
                .padding(.bottom, 70)
            }

            VStack {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.8))
                        .frame(width: 38, height: 56)
                        .offset(x: -100, y: 120)
                        .blur(radius: 0.5)
                }
                Spacer()
            }
        }
    }
}
