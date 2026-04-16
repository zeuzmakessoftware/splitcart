import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    let size: CGFloat
    var background: Color = .black.opacity(0.45)
    var foreground: Color = .white

    var body: some View {
        ZStack {
            Circle()
                .fill(background)
                .overlay {
                    Circle().stroke(.white.opacity(0.08), lineWidth: 1)
                }
            Image(systemName: systemName)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(foreground)
        }
        .frame(width: size, height: size)
    }
}
