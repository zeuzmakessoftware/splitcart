import SwiftUI

struct TagChip: View, Identifiable {
    let id = UUID()
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.white.opacity(0.96))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.black.opacity(0.55))
                .overlay {
                    Capsule().stroke(.white.opacity(0.08), lineWidth: 1)
                }
        )
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }
}

#Preview {
    ContentView()
}
