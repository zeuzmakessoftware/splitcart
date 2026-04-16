import SwiftUI

struct TopBar: View {
    @Binding var selectedCategory: SwipeCategory
    let likedCount: Int
    let remainingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                CircleIconButton(systemName: "slider.horizontal.3", size: 44, background: .white.opacity(0.08))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Splitcart")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Swipe dishes to train your food algorithm")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 6) {
                    statPill(value: "\(likedCount)", label: "likes")
                    statPill(value: "\(remainingCount)", label: "left")
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SwipeCategory.allCases) { category in
                        let selected = category == selectedCategory
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.rawValue)
                                .font(.system(size: 15, weight: selected ? .semibold : .medium))
                                .foregroundStyle(selected ? .black : .white.opacity(0.78))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selected ? Color(red: 0.97, green: 0.65, blue: 0.27) : .white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .tracking(1.2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }
}
