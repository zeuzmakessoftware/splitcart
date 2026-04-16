import SwiftUI

struct BackgroundLayer: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.05, blue: 0.03),
                Color.black,
                Color(red: 0.12, green: 0.06, blue: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.14))
                    .frame(width: 240, height: 240)
                    .blur(radius: 70)
                    .offset(x: 40, y: -300)

                Circle()
                    .fill(Color.pink.opacity(0.10))
                    .frame(width: 200, height: 200)
                    .blur(radius: 90)
                    .offset(x: -120, y: 160)
            }
        }
    }
}
