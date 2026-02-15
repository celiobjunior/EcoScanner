import SwiftUI

// MARK: - CreditsView

struct CreditsView: View {

    @Environment(\.dismiss) private var dismiss

    private let datasetLinks: [CreditLink] = [
        CreditLink(
            icon: "tray.full.fill",
            titleKey: "credits.dataset.one.title",
            detailKey: "credits.dataset.one.detail",
            url: "https://humansintheloop.org/resources/datasets/recycling-dataset/"
        ),
        CreditLink(
            icon: "shippingbox.fill",
            titleKey: "credits.dataset.two.title",
            detailKey: "credits.dataset.two.detail",
            url: "https://data.mendeley.com/datasets/z732f9pwxt/1"
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
                    VStack(alignment: .leading, spacing: .spacing.x4) {
                        Text("credits.intro".localized)
                            .font(.system(size: .fontSize.medium))
                            .foregroundColor(.ecoSmoke.opacity(0.86))
                            .lineSpacing(3)

                        linksSection(titleKey: "credits.section.datasets", links: datasetLinks)
                        linksSection(titleKey: "credits.section.project", links: projectLinks)
                        linksSection(titleKey: "credits.section.social", links: socialLinks)
                    }
                    .padding(.horizontal, .spacing.x6)
                    .padding(.vertical, .spacing.x6)
                    .frame(maxWidth: 840)
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
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
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(link.titleKey.localized)
                    .font(.system(size: .fontSize.small, weight: .bold))
                    .foregroundColor(.ecoSmoke)

                Text(link.detailKey.localized)
                    .font(.system(size: .fontSize.xsmall))
                    .foregroundColor(.ecoSmoke.opacity(0.74))
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.ecoLight)
        }
        .padding(.spacing.x3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
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
