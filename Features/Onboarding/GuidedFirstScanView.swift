import SwiftUI

// MARK: - GuidedFirstScanView

struct GuidedFirstScanView: View {

    @AppStorage("hasCompletedFirstGuidedScan") private var hasCompletedFirstGuidedScan = false
    @State private var hasCompletedGuidedStep = false

    var body: some View {
        if hasCompletedGuidedStep {
            GuidedCompletionView {
                hasCompletedFirstGuidedScan = true
            }
        } else {
            ScannerView(isGuidedMode: true) {
                hasCompletedGuidedStep = true
            }
        }
    }
}

// MARK: - GuidedCompletionView

private struct GuidedCompletionView: View {

    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: .spacing.x5) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.ecoPrimary)

                Text("guided.completion.title".localized)
                    .font(.system(size: .fontSize.big, weight: .bold))
                    .foregroundColor(.ecoSmoke)
                    .multilineTextAlignment(.center)

                Text("guided.completion.body".localized)
                    .font(.system(size: .fontSize.medium))
                    .foregroundColor(.ecoSmoke.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 620)

                Button {
                    onContinue()
                } label: {
                    Text("guided.completion.button".localized)
                        .font(.system(size: .fontSize.medium, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, .spacing.x3)
                        .padding(.horizontal, .spacing.x8)
                        .background(Capsule().fill(Color.ecoSmoke))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, .spacing.x6)
        }
    }
}
