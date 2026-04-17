import SwiftUI

struct PageDots: View {
    let count: Int
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == activeIndex ? .white : .white.opacity(0.24))
                    .frame(width: index == activeIndex ? 22 : 8, height: 4)
            }
        }
    }
}

#Preview {
    ContentView()
}
