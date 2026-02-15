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
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing.x4) {
                        Text("help.intro".localized)
                            .font(.system(size: .fontSize.medium))
                            .foregroundColor(.ecoSmoke.opacity(0.86))
                            .lineSpacing(3)

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
                    .frame(maxWidth: 780)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("help.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
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
                .frame(width: 26)

            VStack(alignment: .leading, spacing: .spacing.base) {
                Text(title)
                    .font(.system(size: .fontSize.medium, weight: .bold))
                    .foregroundColor(.ecoSmoke)

                Text(body)
                    .font(.system(size: .fontSize.small))
                    .foregroundColor(.ecoSmoke.opacity(0.84))
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(.spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
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
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            Text("help.revisit_hint".localized)
                .font(.system(size: 11))
                .foregroundColor(.ecoSmoke.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}
