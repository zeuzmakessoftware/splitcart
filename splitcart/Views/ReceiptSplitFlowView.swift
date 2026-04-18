import PhotosUI
import SwiftUI
import UIKit

private enum ReceiptFlowStage {
    case intro
    case preview
    case scanning
    case results
    case failure
}

private enum ReceiptScanStep: Int, CaseIterable, Identifiable {
    case upload
    case extract
    case split

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .upload:
            return "Upload"
        case .extract:
            return "Gemini Parse"
        case .split:
            return "Taste Split"
        }
    }

    var subtitle: String {
        switch self {
        case .upload:
            return "Lock the image and send it to the backend."
        case .extract:
            return "Extract line items, tags, and shareability hints."
        case .split:
            return "Route each item to the strongest swipe profile."
        }
    }
}

struct ReceiptSplitFlowView: View {
    let groupBias: SwipePreferenceBias
    let friends: [ReceiptFriendProfile]
    let onScanComplete: (ReceiptScanResponse) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriendIDs: Set<String>
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var stage: ReceiptFlowStage = .intro
    @State private var previewImage: UIImage?
    @State private var uploadData: Data?
    @State private var response: ReceiptScanResponse?
    @State private var errorMessage = ""
    @State private var activeStepIndex = 0

    private let client = ReceiptScannerClient()

    init(
        groupBias: SwipePreferenceBias,
        friends: [ReceiptFriendProfile],
        onScanComplete: @escaping (ReceiptScanResponse) -> Void = { _ in }
    ) {
        self.groupBias = groupBias
        self.friends = friends
        self.onScanComplete = onScanComplete
        _selectedFriendIDs = State(initialValue: Set(friends.map(\.id)))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.04),
                    Color.black,
                    Color(red: 0.12, green: 0.08, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.98, green: 0.55, blue: 0.18).opacity(0.16))
                        .frame(width: 240, height: 240)
                        .blur(radius: 70)
                        .offset(x: 120, y: -240)

                    Circle()
                        .fill(Color(red: 0.16, green: 0.67, blue: 0.98).opacity(0.12))
                        .frame(width: 260, height: 260)
                        .blur(radius: 80)
                        .offset(x: -140, y: 120)
                }
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                    stageContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 110)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                await handlePhotoSelection(newValue)
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Receipt Split")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)

                Text("Scan a receipt and split it instantly.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer(minLength: 20)

            Button {
                dismiss()
            } label: {
                CircleIconButton(
                    systemName: "xmark",
                    size: 42,
                    background: .white.opacity(0.08)
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        switch stage {
        case .intro:
            introView
                .transition(.move(edge: .bottom).combined(with: .opacity))
        case .preview:
            previewView
                .transition(.scale(scale: 0.95).combined(with: .opacity))
        case .scanning:
            scanningView
                .transition(.move(edge: .bottom).combined(with: .opacity))
        case .results:
            resultsView
                .transition(.move(edge: .bottom).combined(with: .opacity))
        case .failure:
            failureView
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var introView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 14) {
                FriendSelectionStrip(
                    friends: friends,
                    selectedFriendIDs: selectedFriendIDs,
                    onToggle: toggleFriendSelection
                )

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    PrimaryReceiptButton(
                        title: "Upload Receipt",
                        subtitle: "Choose a photo after picking friends."
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(panelBackground)
            
            Image("receiptflow2")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 16)
                .contrast(1.1)
        }
    }

    private var previewView: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 360)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 16)
            }

            Text("Preparing scan...")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scanningView: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                ScanningOrb()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Scanning")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("Parsing and splitting.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            HStack(spacing: 10) {
                ForEach(Array(ReceiptScanStep.allCases.enumerated()), id: \.element.id) { index, step in
                    SlimScanStep(
                        title: step.title,
                        status: index < activeStepIndex ? .done : (index == activeStepIndex ? .active : .idle)
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(panelBackground)
    }

    private var failureView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Scan failed", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Color(red: 0.99, green: 0.63, blue: 0.32))

            Text(errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                PrimaryReceiptButton(
                    title: "Try Another Receipt",
                    subtitle: "Pick a different photo."
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let response {
                ReceiptSummaryCard(response: response)

                VStack(spacing: 10) {
                    ForEach(response.friends) { friend in
                        FriendSplitRow(
                            friend: friend,
                            currencyCode: response.currencyCode
                        )
                    }
                }
                .padding(18)
                .background(panelBackground)

                VStack(spacing: 10) {
                    ForEach(response.matchedItems) { item in
                        MatchedReceiptItemRow(
                            item: item,
                            currencyCode: response.currencyCode
                        )
                    }
                }
                .padding(18)
                .background(panelBackground)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    PrimaryReceiptButton(
                        title: "Scan Another Receipt",
                        subtitle: "Run it again."
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        do {
            guard let rawData = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: rawData),
                  let jpegData = image.jpegData(compressionQuality: 0.9)
            else {
                throw ReceiptScannerClientError.invalidPayload
            }

            await MainActor.run {
                previewImage = image
                uploadData = jpegData
                response = nil
                errorMessage = ""
                withAnimation(.spring(response: 0.46, dampingFraction: 0.88)) {
                    stage = .preview
                }
            }

            try? await Task.sleep(for: .milliseconds(450))
            await startScan()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
                    stage = .failure
                }
            }
        }
    }

    private func startScan() async {
        guard let uploadData else { return }

        let progressTask = Task {
            await animateProgress()
        }

        await MainActor.run {
            withAnimation(.spring(response: 0.44, dampingFraction: 0.9)) {
                stage = .scanning
                activeStepIndex = 0
            }
        }

        do {
            let payload = ReceiptScanRequestPayload(
                friends: selectedFriends,
                groupBias: groupBias
            )
            let result = try await client.scanReceipt(imageData: uploadData, payload: payload)
            progressTask.cancel()

            await MainActor.run {
                response = result
                onScanComplete(result)
                activeStepIndex = ReceiptScanStep.allCases.count - 1
                withAnimation(.spring(response: 0.46, dampingFraction: 0.9)) {
                    stage = .results
                }
            }
        } catch {
            progressTask.cancel()

            await MainActor.run {
                errorMessage = error.localizedDescription
                withAnimation(.spring(response: 0.44, dampingFraction: 0.88)) {
                    stage = .failure
                }
            }
        }
    }

    private var selectedFriends: [ReceiptFriendProfile] {
        let filtered = friends.filter { selectedFriendIDs.contains($0.id) }
        return filtered.isEmpty ? friends : filtered
    }

    private func toggleFriendSelection(_ friend: ReceiptFriendProfile) {
        if selectedFriendIDs.contains(friend.id) {
            guard selectedFriendIDs.count > 1 else { return }
            selectedFriendIDs.remove(friend.id)
        } else {
            selectedFriendIDs.insert(friend.id)
        }
    }

    private func animateProgress() async {
        let checkpoints = ReceiptScanStep.allCases.indices.map { $0 }

        for index in checkpoints {
            if Task.isCancelled { return }

            await MainActor.run {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                    activeStepIndex = index
                }
            }

            let delay: Duration = index == checkpoints.last ? .seconds(1.2) : .milliseconds(900)
            try? await Task.sleep(for: delay)
        }
    }

}

private struct PrimaryReceiptButton: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 52, height: 52)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.black)
            }
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.79, blue: 0.37),
                                Color(red: 0.97, green: 0.54, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.black)

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.7))
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.black.opacity(0.72))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.77, blue: 0.34),
                            Color(red: 0.98, green: 0.57, blue: 0.21)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

private struct FriendSelectionStrip: View {
    let friends: [ReceiptFriendProfile]
    let selectedFriendIDs: Set<String>
    let onToggle: (ReceiptFriendProfile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Split with")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                        .tracking(0.8)

                    Text("\(selectedFriendIDs.count) selected")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 0)

                Text("Tap to toggle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(spacing: 10) {
                ForEach(friends) { friend in
                    Button {
                        onToggle(friend)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(avatarGradient(for: friend.id))
                                    .frame(width: 54, height: 54)
                                    .overlay {
                                        Text(String(friend.name.prefix(1)))
                                            .font(.system(size: 18, weight: .heavy))
                                            .foregroundStyle(.black.opacity(0.82))
                                    }
                                    .overlay {
                                        Circle()
                                            .strokeBorder(
                                                selectedFriendIDs.contains(friend.id)
                                                ? Color.white.opacity(0.92)
                                                : Color.black.opacity(0.55),
                                                lineWidth: selectedFriendIDs.contains(friend.id) ? 2.5 : 1.5
                                            )
                                    }
                                    .shadow(
                                        color: selectedFriendIDs.contains(friend.id)
                                            ? .white.opacity(0.16)
                                            : .black.opacity(0.18),
                                        radius: 8,
                                        x: 0,
                                        y: 5
                                    )

                                if selectedFriendIDs.contains(friend.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                        .symbolRenderingMode(.palette)
                                        .symbolVariant(.fill)
                                }
                            }

                            Text(friend.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(selectedFriendIDs.contains(friend.id) ? 0.95 : 0.55))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selectedFriendIDs.contains(friend.id) ? Color.white.opacity(0.08) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(friend.name)
                    .accessibilityValue(selectedFriendIDs.contains(friend.id) ? "Selected" : "Not selected")
                }
            }
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
        default:
            colors = [Color(red: 0.39, green: 0.78, blue: 0.97), Color(red: 0.46, green: 0.93, blue: 0.64)]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct ScanningOrb: View {
    @State private var pulse = false
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 132, height: 132)

            Circle()
                .trim(from: 0.12, to: 0.92)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.99, green: 0.76, blue: 0.35),
                            Color(red: 0.99, green: 0.58, blue: 0.23),
                            Color(red: 0.31, green: 0.82, blue: 0.98),
                            Color(red: 0.99, green: 0.76, blue: 0.35)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 8])
                )
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(spin ? 360 : 0))

            Circle()
                .fill(Color(red: 0.99, green: 0.62, blue: 0.24).opacity(0.18))
                .frame(width: pulse ? 124 : 88, height: pulse ? 124 : 88)
                .blur(radius: 10)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.74, blue: 0.33),
                            Color(red: 0.98, green: 0.5, blue: 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 84, height: 84)

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(.black.opacity(0.76))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulse = true
            }
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
    }
}

private enum ScanStepStatus {
    case idle
    case active
    case done
}

private struct SlimScanStep: View {
    let title: String
    let status: ScanStepStatus

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(fillColor)
                .frame(width: 12, height: 12)

            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(status == .idle ? 0.48 : 0.82))
        }
        .frame(maxWidth: .infinity)
    }

    private var fillColor: Color {
        switch status {
        case .idle:
            return .white.opacity(0.08)
        case .active:
            return Color(red: 0.99, green: 0.63, blue: 0.24)
        case .done:
            return Color(red: 0.38, green: 0.92, blue: 0.65)
        }
    }
}

private struct ReceiptSummaryCard: View {
    let response: ReceiptScanResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(response.store.isEmpty ? "Receipt scanned" : response.store)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)

                    if !response.date.isEmpty {
                        Text(response.date)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                        .tracking(1.2)

                    Text(ReceiptFormatting.amount(response.total, currencyCode: response.currencyCode))
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(Color(red: 0.98, green: 0.79, blue: 0.36))
                }
            }

            HStack(spacing: 10) {
                SummaryStatPill(
                    label: "Items",
                    value: "\(response.matchedItems.count)"
                )
                SummaryStatPill(
                    label: "Split",
                    value: "\(response.friends.count)"
                )
                SummaryStatPill(
                    label: "Tax",
                    value: ReceiptFormatting.amount(response.tax, currencyCode: response.currencyCode)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.12, blue: 0.1),
                            Color(red: 0.3, green: 0.15, blue: 0.09)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SummaryStatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))
                .tracking(1.0)

            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }
}

private struct FriendSplitRow: View {
    let friend: ReceiptFriendSplit
    let currencyCode: String

    var body: some View {
        HStack(spacing: 14) {
            Text(friend.name)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)

            Spacer(minLength: 10)

            Text(friend.items.prefix(2).map(\.name).joined(separator: ", "))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)

            Text(ReceiptFormatting.amount(friend.amount, currencyCode: currencyCode))
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Color(red: 0.98, green: 0.79, blue: 0.36))
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
    }
}

private struct MatchedReceiptItemRow: View {
    let item: ReceiptMatchedItem
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)

                    Text(item.assignedTo.map(\.name).joined(separator: ", "))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Text(ReceiptFormatting.amount(item.price, currencyCode: currencyCode))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

#Preview {
    ContentView()
}
