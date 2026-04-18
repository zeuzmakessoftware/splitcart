import SwiftUI

struct TopBar: View {
    @Binding var selectedCategory: SwipeCategory
    let likedCount: Int
    let remainingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                CircleIconButton(
                    systemName: "slider.horizontal.3",
                    size: 28,
                    background: .white.opacity(0.08)
                )

                Text("Splitcart")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    statPill(value: "\(likedCount)", label: "likes")
                    statPill(value: "\(remainingCount)", label: "left")
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SwipeCategory.allCases) { category in
                        let selected = category == selectedCategory

                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: selected ? .semibold : .medium))
                                .foregroundStyle(selected ? .black : .white.opacity(0.78))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(
                                            selected
                                            ? Color(red: 0.97, green: 0.65, blue: 0.27)
                                            : .white.opacity(0.08)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statPill(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .tracking(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }
}
