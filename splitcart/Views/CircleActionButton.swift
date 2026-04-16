import SwiftUI

struct CircleActionButton: View {
    let systemName: String
    let diameter: CGFloat
    var fill: Color = .black.opacity(0.82)

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .overlay {
                    Circle().stroke(.white.opacity(0.06), lineWidth: 1)
                }
            Image(systemName: systemName)
                .font(.system(size: diameter * 0.34, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 7)
    }
}
