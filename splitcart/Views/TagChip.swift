import SwiftUI

struct TagChip: View, Identifiable {
    let id = UUID()
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.12), lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
        .lineLimit(1)
    }
}
