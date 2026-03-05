import SwiftUI

// MARK: - CreditsView

struct CreditsView: View {

    @Environment(\.dismiss) private var dismiss

    private let datasetLinks: [CreditLink] = [
        CreditLink(
            icon: "tray.full.fill",
            titleKey: "credits.dataset.1.title",
            detailKey: "credits.dataset.1.detail",
            url: "https://www.kaggle.com/datasets/sumn2u/garbage-classification-v2"
        ),
        CreditLink(
            icon: "tray.full.fill",
            titleKey: "credits.dataset.2.title",
            detailKey: "credits.dataset.2.detail",
            url: "https://www.kaggle.com/datasets/asdasdasasdas/garbage-classification"
        ),
        CreditLink(
            icon: "tray.full.fill",
            titleKey: "credits.dataset.3.title",
            detailKey: "credits.dataset.3.detail",
            url: "https://www.kaggle.com/datasets/mostafaabla/garbage-classification"
        ),
        CreditLink(
            icon: "tray.full.fill",
            titleKey: "credits.dataset.4.title",
            detailKey: "credits.dataset.4.detail",
            url: "https://www.kaggle.com/datasets/vencerlanz09/plastic-paper-garbage-bag-synthetic-images"
        ),
        CreditLink(
            icon: "tray.full.fill",
            titleKey: "credits.dataset.5.title",
            detailKey: "credits.dataset.5.detail",
            url: "https://www.kaggle.com/datasets/farzadnekouei/trash-type-image-dataset"
        ),
        CreditLink(
            icon: "tray.full.fill",
            titleKey: "credits.dataset.6.title",
            detailKey: "credits.dataset.6.detail",
            url: "https://www.kaggle.com/datasets/hassnainzaidi/garbage-classification"
        ),
        CreditLink(
            icon: "tray.full.fill",
            titleKey: "credits.dataset.7.title",
            detailKey: "credits.dataset.7.detail",
            url: "https://www.kaggle.com/datasets/manonstr/tipe-webscraping"
        ),
    ]

    private let projectLinks: [CreditLink] = [
        CreditLink(
            icon: "hammer.fill",
            titleKey: "credits.project.repo.title",
            detailKey: "credits.project.repo.detail",
            url: "https://github.com/celiobjunior/EcoScanner"
        ),
    ]

    private let socialLinks: [CreditLink] = [
        CreditLink(
            icon: "person.crop.circle.fill",
            titleKey: "credits.social.github.title",
            detailKey: "credits.social.github.detail",
            url: "https://github.com/celiobjunior"
        ),
        CreditLink(
            icon: "link.circle.fill",
            titleKey: "credits.social.beacons.title",
            detailKey: "credits.social.beacons.detail",
            url: "https://beacons.ai/devcelio"
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ecoInk.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .center, spacing: .spacing.x4) {
                        Text("credits.thanks".localized)
                            .font(.system(size: .fontSize.title, weight: .bold))
                            .foregroundColor(.ecoSmoke)
                            .frame(maxWidth: .infinity)

                        Image("EcoScannerLogoNoBg")
                            .resizable()
                            .scaledToFit()
                            .frame(height: .size.creditsLogo)

                        Text("credits.intro".localized)
                            .font(.system(size: .fontSize.small))
                            .foregroundColor(.ecoSmoke.opacity(Double.opacity.textSecondary))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        linksSection(titleKey: "credits.section.datasets", links: datasetLinks)
                        linksSection(titleKey: "credits.section.project", links: projectLinks)
                        linksSection(titleKey: "credits.section.social", links: socialLinks)
                    }
                    .padding(.horizontal, .spacing.x6)
                    .padding(.vertical, .spacing.x6)
                    .frame(maxWidth: .maxWidth.creditsContent)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("credits.title".localized)
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
        }
    }
}

// MARK: - UI

private extension CreditsView {

    func linksSection(titleKey: String, links: [CreditLink]) -> some View {
        VStack(alignment: .leading, spacing: .spacing.x3) {
            Text(titleKey.localized)
                .font(.system(size: .fontSize.medium, weight: .bold))
                .foregroundColor(.ecoSmoke)

            ForEach(links) { link in
                linkRow(link)
            }
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

    @ViewBuilder
    func linkRow(_ link: CreditLink) -> some View {
        if let url = URL(string: link.url) {
            Link(destination: url) {
                linkRowContent(link)
            }
            .buttonStyle(.plain)
        } else {
            linkRowContent(link)
        }
    }

    func linkRowContent(_ link: CreditLink) -> some View {
        HStack(alignment: .top, spacing: .spacing.x3) {
            Image(systemName: link.icon)
                .font(.system(size: .fontSize.small, weight: .semibold))
                .foregroundColor(.ecoPrimary)
                .frame(width: .size.creditsCardIconSlot)

            VStack(alignment: .leading, spacing: .spacing.micro) {
                Text(link.titleKey.localized)
                    .font(.system(size: .fontSize.small, weight: .bold))
                    .foregroundColor(.ecoSmoke)

                Text(link.detailKey.localized)
                    .font(.system(size: .fontSize.xsmall))
                    .foregroundColor(.ecoSmoke.opacity(Double.opacity.textSubdued))
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.up.right.square")
                .font(.system(size: .iconSize.xsmall, weight: .semibold))
                .foregroundColor(.ecoLight)
        }
        .padding(.spacing.x3)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.medium)
                .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.medium)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
    }
}

// MARK: - Model

private struct CreditLink: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let detailKey: String
    let url: String
}
