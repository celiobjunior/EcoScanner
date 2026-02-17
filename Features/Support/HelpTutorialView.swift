import SwiftUI

// MARK: - HelpTutorialView

struct HelpTutorialView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("hasCompletedFirstGuidedScan") private var hasCompletedFirstGuidedScan = true

    @State private var showCredits = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ecoInk.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing.x4) {
                        Text("help.intro".localized)
                            .font(.system(size: .fontSize.medium))
                            .foregroundColor(.ecoSmoke.opacity(Double.opacity.textPrimary))
                            .lineSpacing(.lineSpacing.compact)

                        simpleCard(
                            icon: "target",
                            title: "help.card.objective.title".localized,
                            body: "help.card.objective.body".localized
                        )

                        simpleCard(
                            icon: "list.number",
                            title: "help.card.howto.title".localized,
                            body: "help.card.howto.body".localized
                        )

                        simpleCard(
                            icon: "square.grid.2x2.fill",
                            title: "help.card.categories.title".localized,
                            body: "help.card.categories.body".localized
                        )

                        actionButtons
                    }
                    .padding(.horizontal, .spacing.x6)
                    .padding(.vertical, .spacing.x6)
                    .frame(maxWidth: .maxWidth.helpContent)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("help.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.ecoInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("help.close".localized) {
                        dismiss()
                    }
                    .foregroundColor(.ecoLight)
                }
            }
            .sheet(isPresented: $showCredits) {
                CreditsView()
            }
        }
    }
}

// MARK: - UI

private extension HelpTutorialView {

    func simpleCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: .spacing.x3) {
            Image(systemName: icon)
                .font(.system(size: .fontSize.medium, weight: .semibold))
                .foregroundColor(.ecoPrimary)
                .frame(width: .size.supportCardIconSlot)

            VStack(alignment: .leading, spacing: .spacing.base) {
                Text(title)
                    .font(.system(size: .fontSize.medium, weight: .bold))
                    .foregroundColor(.ecoSmoke)

                Text(body)
                    .font(.system(size: .fontSize.small))
                    .foregroundColor(.ecoSmoke.opacity(Double.opacity.textBody))
                    .lineSpacing(.lineSpacing.compact)
            }

            Spacer(minLength: 0)
        }
        .padding(.spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.large)
                .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.large)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
    }

    var actionButtons: some View {
        VStack(alignment: .leading, spacing: .spacing.x3) {
            Button {
                showCredits = true
            } label: {
                HStack(spacing: .spacing.x2) {
                    Image(systemName: "heart.text.square.fill")
                    Text("help.open_credits".localized)
                        .font(.system(size: .fontSize.small, weight: .bold))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right.square")
                }
                .foregroundColor(.black)
                .padding(.vertical, .spacing.x3)
                .padding(.horizontal, .spacing.x4)
                .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)

            Button {
                hasCompletedFirstGuidedScan = false
                hasCompletedOnboarding = false
                dismiss()
            } label: {
                HStack(spacing: .spacing.x2) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("help.revisit_onboarding".localized)
                        .font(.system(size: .fontSize.small, weight: .bold))
                }
                .foregroundColor(.ecoSmoke)
                .padding(.vertical, .spacing.x3)
                .padding(.horizontal, .spacing.x4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(Double.opacity.strokeSoft), lineWidth: .lineWidth.hairline)
                        )
                )
            }
            .buttonStyle(.plain)

            Text("help.revisit_hint".localized)
                .font(.system(size: .fontSize.caption))
                .foregroundColor(.ecoSmoke.opacity(Double.opacity.textDim))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.large)
                .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.large)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
    }
}
