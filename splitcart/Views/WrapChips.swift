import SwiftUI

struct WrapChips: View {
    let tags: [FoodTag]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 132), spacing: 10, alignment: .leading)],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(tags) { tag in
                TagChip(icon: tag.icon, text: tag.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
