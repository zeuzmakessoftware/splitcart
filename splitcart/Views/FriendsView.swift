import SwiftUI

struct FriendsView: View {
    let friends: [ReceiptFriendProfile]
    let latestReceipt: ReceiptScanResponse?
    let onAddFriend: (String, String) -> Void

    @State private var newFriendName = ""
    @State private var newFriendVibe = ""
    @State private var activePaymentRequest: DemoPaybackRequest?
    @State private var hasPaidDemoRequest = false
    @State private var completedPaymentMethod: DemoPaybackMethod = .applePay

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

                IncomingPaybackRequestCard(
                    request: .sample,
                    isPaid: hasPaidDemoRequest,
                    paidMethod: hasPaidDemoRequest ? completedPaymentMethod : nil,
                    onTap: presentDemoPaymentRequest
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $activePaymentRequest) { request in
            DemoPaybackFlowSheet(
                request: request,
                startsPaid: hasPaidDemoRequest,
                initialMethod: completedPaymentMethod,
                onPaymentSuccess: { method in
                    hasPaidDemoRequest = true
                    completedPaymentMethod = method
                }
            )
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

    private func presentDemoPaymentRequest() {
        activePaymentRequest = .sample
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

private struct IncomingPaybackRequestCard: View {
    let request: DemoPaybackRequest
    let isPaid: Bool
    let paidMethod: DemoPaybackMethod?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Incoming request")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)

                        Text(isPaid ? "A mock payback was completed. Tap to replay the success state." : "")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 10)

                    Text(isPaid ? "PAID" : "NEW")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(isPaid ? Color(red: 0.42, green: 0.92, blue: 0.74) : Color(red: 1.0, green: 0.78, blue: 0.37))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill((isPaid ? Color(red: 0.42, green: 0.92, blue: 0.74) : Color(red: 1.0, green: 0.78, blue: 0.37)).opacity(0.14))
                        )
                }

                HStack(spacing: 12) {
                    Circle()
                        .fill(avatarGradient(for: request.senderID))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Text(String(request.senderName.prefix(1)))
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundStyle(.black.opacity(0.8))
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.senderName)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(.white)

                        Text(request.contextLine)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(ReceiptFormatting.amount(request.amount, currencyCode: request.currencyCode))
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.37))

                        Text(request.sentAtText.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(0.8)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(request.note)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: 8) {
                        RequestCapabilityPill(
                            title: "Apple Pay ready",
                            systemImage: "applelogo",
                            tint: Color(red: 0.95, green: 0.95, blue: 0.95)
                        )

                        if let paidMethod, isPaid {
                            RequestCapabilityPill(
                                title: "Paid with \(paidMethod.shortTitle)",
                                systemImage: paidMethod.systemImage,
                                tint: Color(red: 0.42, green: 0.92, blue: 0.74)
                            )
                        } else {
                            RequestCapabilityPill(
                                title: "Tap to pay back",
                                systemImage: "arrow.up.circle.fill",
                                tint: Color(red: 1.0, green: 0.78, blue: 0.37)
                            )
                        }
                    }
                }
            }
            .padding(20)
            .background(friendsPanelBackground)
        }
        .buttonStyle(.plain)
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

private struct DemoPaybackFlowSheet: View {
    let request: DemoPaybackRequest
    let onPaymentSuccess: (DemoPaybackMethod) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: DemoPaybackMethod
    @State private var stage: DemoPaybackStage

    init(
        request: DemoPaybackRequest,
        startsPaid: Bool,
        initialMethod: DemoPaybackMethod,
        onPaymentSuccess: @escaping (DemoPaybackMethod) -> Void
    ) {
        self.request = request
        self.onPaymentSuccess = onPaymentSuccess
        _selectedMethod = State(initialValue: initialMethod)
        _stage = State(initialValue: startsPaid ? .success : .review)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.09, blue: 0.08),
                    Color.black,
                    Color(red: 0.13, green: 0.08, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pay back")
                                .font(.system(size: 30, weight: .heavy))
                                .foregroundStyle(.white)

                            Text("Mock flow for settling an incoming split request.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.68))
                        }

                        Spacer(minLength: 12)

                        Button {
                            dismiss()
                        } label: {
                            CircleIconButton(
                                systemName: "xmark",
                                size: 40,
                                background: .white.opacity(0.08)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    switch stage {
                    case .review:
                        reviewState
                    case .processing:
                        processingState
                    case .success:
                        successState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 36)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var reviewState: some View {
        VStack(alignment: .leading, spacing: 18) {
            paymentRequestHeader

            VStack(alignment: .leading, spacing: 14) {
                Text("Choose how to pay")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)

                VStack(spacing: 10) {
                    ForEach(request.supportedMethods) { method in
                        PaymentMethodRow(
                            method: method,
                            isSelected: selectedMethod == method,
                            action: { selectedMethod = method }
                        )
                    }
                }
            }
            .padding(18)
            .background(friendsPanelBackground)

            VStack(alignment: .leading, spacing: 12) {
                Button(action: runMockPayment) {
                    HStack {
                        Text(selectedMethod.callToAction)
                            .font(.system(size: 16, weight: .heavy))
                        Spacer()
                        Text(ReceiptFormatting.amount(request.amount, currencyCode: request.currencyCode))
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(selectedMethod == .applePay ? .white : .black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(primaryActionBackground)
                }
                .buttonStyle(.plain)

                Text("Demo only. No real charge is created, but the flow behaves like a one-tap payback.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.56))
            }
        }
    }

    private var processingState: some View {
        VStack(alignment: .center, spacing: 18) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(selectedMethod == .applePay ? .white : Color.black)
                .scaleEffect(1.35)

            Text(selectedMethod.processingTitle)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)

            Text("Sending \(ReceiptFormatting.amount(request.amount, currencyCode: request.currencyCode)) to \(request.senderName) for \(request.venue).")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .padding(.horizontal, 20)
        .background(friendsPanelBackground)
    }

    private var successState: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.42, green: 0.92, blue: 0.74).opacity(0.16))
                        .frame(width: 96, height: 96)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 58, weight: .bold))
                        .foregroundStyle(Color(red: 0.42, green: 0.92, blue: 0.74))
                }

                Text("Paid back")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)

                Text("\(request.senderName) received your mock payment via \(selectedMethod.shortTitle).")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 18)
            .background(friendsPanelBackground)

            VStack(alignment: .leading, spacing: 12) {
                SuccessDetailRow(
                    title: "Amount",
                    value: ReceiptFormatting.amount(request.amount, currencyCode: request.currencyCode)
                )
                SuccessDetailRow(
                    title: "To",
                    value: request.senderName
                )
                SuccessDetailRow(
                    title: "Method",
                    value: selectedMethod.successLabel
                )
                SuccessDetailRow(
                    title: "Speed",
                    value: selectedMethod == .applePay ? "Instant payback demo" : "Mock transfer completed"
                )
            }
            .padding(18)
            .background(friendsPanelBackground)

            Button {
                dismiss()
            } label: {
                HStack {
                    Text("Done")
                        .font(.system(size: 16, weight: .heavy))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.42, green: 0.92, blue: 0.74),
                                    Color(red: 0.16, green: 0.72, blue: 0.96)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var paymentRequestHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(avatarGradient(for: request.senderID))
                    .frame(width: 54, height: 54)
                    .overlay {
                        Text(String(request.senderName.prefix(1)))
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(.black.opacity(0.8))
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.senderName)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("requested your split for \(request.venue)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()
            }

            Text(ReceiptFormatting.amount(request.amount, currencyCode: request.currencyCode))
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text(request.note)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 8) {
                    RequestCapabilityPill(
                        title: request.sentAtText,
                        systemImage: "clock.fill",
                        tint: Color.white.opacity(0.9)
                    )
                    RequestCapabilityPill(
                        title: "Apple Pay compatible",
                        systemImage: "applelogo",
                        tint: Color.white.opacity(0.9)
                    )
                }
            }
        }
        .padding(20)
        .background(friendsPanelBackground)
    }

    @ViewBuilder
    private var primaryActionBackground: some View {
        if selectedMethod == .applePay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.78, blue: 0.36),
                            Color(red: 0.97, green: 0.53, blue: 0.18)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    private func runMockPayment() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
            stage = .processing
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_150_000_000)
            await MainActor.run {
                onPaymentSuccess(selectedMethod)
                withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                    stage = .success
                }
            }
        }
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

private struct PaymentMethodRow: View {
    let method: DemoPaybackMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(method.tint.opacity(0.18))
                        .frame(width: 42, height: 42)

                    Image(systemName: method.systemImage)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(method.tint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(method.title)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)

                    Text(method.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? method.tint : .white.opacity(0.28))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.09) : .white.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RequestCapabilityPill: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
            )
    }
}

private struct SuccessDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.9)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
        }
    }
}

private enum DemoPaybackStage {
    case review
    case processing
    case success
}

private enum DemoPaybackMethod: String, CaseIterable, Identifiable {
    case applePay
    case splitcartBalance
    case debitCard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .applePay:
            return "Apple Pay"
        case .splitcartBalance:
            return "Splitcart Balance"
        case .debitCard:
            return "Debit Card"
        }
    }

    var shortTitle: String {
        switch self {
        case .applePay:
            return "Apple Pay"
        case .splitcartBalance:
            return "Balance"
        case .debitCard:
            return "Card"
        }
    }

    var subtitle: String {
        switch self {
        case .applePay:
            return "Fastest option for one-tap paybacks."
        case .splitcartBalance:
            return "Use stored funds already in the app."
        case .debitCard:
            return "Fallback if Apple Pay is unavailable."
        }
    }

    var systemImage: String {
        switch self {
        case .applePay:
            return "applelogo"
        case .splitcartBalance:
            return "sparkles"
        case .debitCard:
            return "creditcard.fill"
        }
    }

    var tint: Color {
        switch self {
        case .applePay:
            return .white
        case .splitcartBalance:
            return Color(red: 1.0, green: 0.78, blue: 0.37)
        case .debitCard:
            return Color(red: 0.42, green: 0.92, blue: 0.74)
        }
    }

    var callToAction: String {
        switch self {
        case .applePay:
            return "Pay with Apple Pay"
        case .splitcartBalance:
            return "Pay from Splitcart Balance"
        case .debitCard:
            return "Pay with Debit Card"
        }
    }

    var processingTitle: String {
        switch self {
        case .applePay:
            return "Authorizing Apple Pay"
        case .splitcartBalance:
            return "Moving Splitcart funds"
        case .debitCard:
            return "Authorizing card"
        }
    }

    var successLabel: String {
        switch self {
        case .applePay:
            return "Apple Pay"
        case .splitcartBalance:
            return "Splitcart Balance"
        case .debitCard:
            return "Debit Card"
        }
    }
}

private struct DemoPaybackRequest: Identifiable, Hashable {
    let id: String
    let senderID: String
    let senderName: String
    let contextLine: String
    let venue: String
    let amount: Double
    let currencyCode: String
    let sentAtText: String
    let note: String
    let supportedMethods: [DemoPaybackMethod]

    static let sample = DemoPaybackRequest(
        id: "camila-payback-demo",
        senderID: "camila",
        senderName: "Camila R.",
        contextLine: "Covered checkout and requested your share.",
        venue: "Palma Pasta Bar",
        amount: 24.80,
        currencyCode: "USD",
        sentAtText: "2 min ago",
        note: "Your split for vodka rigatoni, half the burrata, and sparkling water.",
        supportedMethods: [.applePay, .splitcartBalance, .debitCard]
    )
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
    case "eva":
        colors = [Color(red: 0.42, green: 0.92, blue: 0.74), Color(red: 0.98, green: 0.79, blue: 0.37)]
    case "idan":
        colors = [Color(red: 1.0, green: 0.55, blue: 0.26), Color(red: 0.95, green: 0.27, blue: 0.28)]
    case "purnima":
        colors = [Color(red: 0.96, green: 0.48, blue: 0.64), Color(red: 0.99, green: 0.8, blue: 0.46)]
    case "aanya":
        colors = [Color(red: 0.39, green: 0.78, blue: 0.97), Color(red: 0.46, green: 0.93, blue: 0.64)]
    default:
        colors = [Color(red: 0.88, green: 0.72, blue: 0.98), Color(red: 0.51, green: 0.83, blue: 0.98)]
    }

    return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
}

#Preview {
    ContentView()
}
