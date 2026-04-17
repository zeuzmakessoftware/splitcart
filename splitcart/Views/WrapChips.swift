import SwiftUI

struct WrapChips: View {
    let tags: [FoodTag]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 102), spacing: 1, alignment: .leading)],
            alignment: .leading,
            spacing: 1
        ) {
            ForEach(tags) { tag in
                TagChip(icon: tag.icon, text: tag.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
