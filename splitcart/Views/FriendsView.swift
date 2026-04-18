import SwiftUI

struct FriendsView: View {
    let friends: [ReceiptFriendProfile]
    let latestReceipt: ReceiptScanResponse?
    let onAddFriend: (String, String) -> Void

    @State private var newFriendName = ""
    @State private var newFriendVibe = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                FriendsHeaderCard(
                    latestReceipt: latestReceipt,
                    totalOutstanding: totalOutstanding,
                    friendsWithBalances: friendsWithBalances
                )

                AddFriendCard(
                    newFriendName: $newFriendName,
                    newFriendVibe: $newFriendVibe,
                    onAdd: addFriend
                )

                if let latestReceipt {
                    LatestSplitCard(
                        receipt: latestReceipt,
                        totalOutstanding: totalOutstanding
                    )

                    VStack(spacing: 12) {
                        ForEach(latestReceipt.friends.sorted { $0.amount > $1.amount }) { friend in
                            FriendBalanceCard(
                                friend: friend,
                                currencyCode: latestReceipt.currencyCode
                            )
                        }
                    }
                } else {
                    EmptyReceiptStateCard(friendCount: friends.count)
                }

                RosterCard(
                    friends: friends,
                    latestReceipt: latestReceipt
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 130)
        }
    }

    private var totalOutstanding: Double {
        latestReceipt?.friends.reduce(0) { $0 + $1.amount } ?? 0
    }

    private var friendsWithBalances: Int {
        latestReceipt?.friends.filter { $0.amount > 0.01 }.count ?? 0
    }

    private func addFriend() {
        let trimmedName = newFriendName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let trimmedVibe = newFriendVibe.trimmingCharacters(in: .whitespacesAndNewlines)
        let vibe = trimmedVibe.isEmpty ? "Flexible split partner" : trimmedVibe
        onAddFriend(trimmedName, vibe)
        newFriendName = ""
        newFriendVibe = ""
    }
}

private struct FriendsHeaderCard: View {
    let latestReceipt: ReceiptScanResponse?
    let totalOutstanding: Double
    let friendsWithBalances: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Friends")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("Track who still owes from the latest split and keep your crew ready for the next receipt.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(red: 0.99, green: 0.78, blue: 0.36))
            }

            HStack(spacing: 10) {
                SummaryPill(
                    value: latestReceipt.map { ReceiptFormatting.amount(totalOutstanding, currencyCode: $0.currencyCode) } ?? "$0",
                    label: "still owed"
                )
                SummaryPill(
                    value: "\(friendsWithBalances)",
                    label: "open balances"
                )
            }
        }
        .padding(20)
        .background(friendsPanelBackground)
    }
}

private struct AddFriendCard: View {
    @Binding var newFriendName: String
    @Binding var newFriendVibe: String
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add to Splitcart")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                FriendsTextField(
                    title: "Friend name",
                    text: $newFriendName,
                    prompt: "Jordan"
                )

                FriendsTextField(
                    title: "Vibe",
                    text: $newFriendVibe,
                    prompt: "Late-night snacks and shared apps"
                )
            }

            Button(action: onAdd) {
                HStack {
                    Label("Add Friend", systemImage: "plus")
                        .font(.system(size: 15, weight: .heavy))
                    Spacer()
                    Text("Ready for the next split")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.65))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.78, blue: 0.35),
                                    Color(red: 0.98, green: 0.56, blue: 0.21)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(friendsPanelBackground)
    }
}

private struct LatestSplitCard: View {
    let receipt: ReceiptScanResponse
    let totalOutstanding: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest receipt")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.62))

                    Text(receipt.store)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(receipt.date)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text(receipt.summary)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.76))

            HStack(spacing: 10) {
                SummaryPill(
                    value: ReceiptFormatting.amount(receipt.total, currencyCode: receipt.currencyCode),
                    label: "receipt total"
                )
                SummaryPill(
                    value: ReceiptFormatting.amount(totalOutstanding, currencyCode: receipt.currencyCode),
                    label: "friends owe"
                )
            }
        }
        .padding(20)
        .background(friendsPanelBackground)
    }
}

private struct FriendBalanceCard: View {
    let friend: ReceiptFriendSplit
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(avatarGradient(for: friend.id))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Text(String(friend.name.prefix(1)))
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.black.opacity(0.76))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(friend.name)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)

                    Text(friend.vibe)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(ReceiptFormatting.amount(friend.amount, currencyCode: currencyCode))
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.37))

                    Text("still owes")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(friend.items.count) items routed")
                    Spacer()
                    Text("Tax \(ReceiptFormatting.amount(friend.tax, currencyCode: currencyCode))")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))

                if let firstItem = friend.items.first {
                    Text("Top line: \(firstItem.name) for \(ReceiptFormatting.amount(firstItem.amount, currencyCode: currencyCode))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.74))
                }
            }
        }
        .padding(18)
        .background(friendsPanelBackground)
    }
}

private struct EmptyReceiptStateCard: View {
    let friendCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No receipt split yet")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)

            Text("Scan a receipt from the center action, then come back here to see what each friend still owes.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            SummaryPill(value: "\(friendCount)", label: "friends ready")
        }
        .padding(20)
        .background(friendsPanelBackground)
    }
}

private struct RosterCard: View {
    let friends: [ReceiptFriendProfile]
    let latestReceipt: ReceiptScanResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Crew activity")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                ForEach(friends) { friend in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(avatarGradient(for: friend.id))
                            .frame(width: 38, height: 38)
                            .overlay {
                                Text(String(friend.name.prefix(1)))
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundStyle(.black.opacity(0.78))
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)

                            Text(friend.vibe)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(statusText(for: friend))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(statusColor(for: friend))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(statusColor(for: friend).opacity(0.12))
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(friendsPanelBackground)
    }

    private func statusText(for friend: ReceiptFriendProfile) -> String {
        guard let latestReceipt else { return "Ready" }
        return latestReceipt.friends.contains(where: { $0.id == friend.id }) ? "Has balance" : "Next split"
    }

    private func statusColor(for friend: ReceiptFriendProfile) -> Color {
        guard let latestReceipt else { return Color(red: 0.42, green: 0.92, blue: 0.74) }
        return latestReceipt.friends.contains(where: { $0.id == friend.id })
            ? Color(red: 1.0, green: 0.78, blue: 0.37)
            : Color(red: 0.42, green: 0.92, blue: 0.74)
    }
}

private struct FriendsTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.56))

            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(.white.opacity(0.28)))
                .textInputAutocapitalization(.words)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.06))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        }
    }
}

private struct SummaryPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)

            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }
}

private var friendsPanelBackground: some View {
    RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(Color.white.opacity(0.06))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
}

private func avatarGradient(for id: String) -> LinearGradient {
    let colors: [Color]
    switch id {
    case "maya":
        colors = [Color(red: 0.42, green: 0.92, blue: 0.74), Color(red: 0.98, green: 0.79, blue: 0.37)]
    case "theo":
        colors = [Color(red: 1.0, green: 0.55, blue: 0.26), Color(red: 0.95, green: 0.27, blue: 0.28)]
    case "riley":
        colors = [Color(red: 0.96, green: 0.48, blue: 0.64), Color(red: 0.99, green: 0.8, blue: 0.46)]
    case "nova":
        colors = [Color(red: 0.39, green: 0.78, blue: 0.97), Color(red: 0.46, green: 0.93, blue: 0.64)]
    default:
        colors = [Color(red: 0.88, green: 0.72, blue: 0.98), Color(red: 0.51, green: 0.83, blue: 0.98)]
    }

    return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
}
