import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var gradientAngle: Double = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            AngularGradient(
                colors: [.ecoDark, .ecoPrimary, .ecoLight, .ecoPrimary, .ecoDark],
                center: .center,
                angle: .degrees(gradientAngle)
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                    gradientAngle = 360
                }
            }

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page, isFirst: index == 0)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: currentPage)
        }
        .safeAreaInset(edge: .bottom) {
            controls
                .padding(.horizontal, .spacing.x8)
                .padding(.bottom, .spacing.x10)
        }
    }
}

// MARK: - UI

private extension OnboardingView {

    func pageView(_ page: OnboardingPage, isFirst: Bool) -> some View {
        VStack(spacing: .spacing.x5) {
            Spacer(minLength: .spacing.x8)

            heroView(isFirst: isFirst, systemImage: page.systemImage)

            VStack(spacing: .spacing.x2) {
                Text(page.titleKey.localized)
                    .font(.system(size: .fontSize.huge, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.ecoSmoke)

                Text(page.subtitleKey.localized)
                    .font(.system(size: .fontSize.medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.ecoSmoke.opacity(0.9))
                    .lineSpacing(4)
            }
            .frame(maxWidth: 620)

            VStack(spacing: .spacing.x3) {
                ForEach(page.cards) { card in
                    onboardingCard(card)
                }
            }
            .frame(maxWidth: 680)

            Spacer(minLength: .spacing.x8)
        }
        .padding(.horizontal, .spacing.x6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func heroView(isFirst: Bool, systemImage: String) -> some View {
        if isFirst {
            Image("EcoScannerLogoNoBg")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .shadow(color: .white.opacity(0.25), radius: 26, y: 8)
        } else {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)
                    .overlay(Circle().stroke(Color.surfaceStroke, lineWidth: 1))

                Image(systemName: systemImage)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.ecoSmoke)
            }
        }
    }

    func onboardingCard(_ card: OnboardingCard) -> some View {
        HStack(alignment: .top, spacing: .spacing.x3) {
            Image(systemName: card.systemImage)
                .font(.system(size: .fontSize.large, weight: .semibold))
                .foregroundColor(.ecoSmoke)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: .spacing.base) {
                Text(card.titleKey.localized)
                    .font(.system(size: .fontSize.small, weight: .bold))
                    .foregroundColor(.ecoSmoke)

                Text(card.bodyKey.localized)
                    .font(.system(size: .fontSize.small))
                    .foregroundColor(.ecoSmoke.opacity(0.85))
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(.spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.surfaceStroke, lineWidth: 1)
                )
        )
    }

    var controls: some View {
        VStack(spacing: .spacing.x5) {
            HStack(spacing: .spacing.x2) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.ecoSmoke : Color.white.opacity(0.35))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            HStack(spacing: .spacing.x4) {
                if currentPage < pages.count - 1 {
                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        HStack(spacing: .spacing.x2) {
                            Text("onboarding.skip".localized)
                                .font(.system(size: .fontSize.medium, weight: .bold))
                            Image(systemName: "xmark")
                                .font(.system(size: .fontSize.medium, weight: .bold))
                        }
                        .foregroundColor(.ecoInk)
                        .padding(.vertical, .spacing.x4)
                        .padding(.horizontal, .spacing.x6)
                        .background(Capsule().fill(.white))
                    }
                }

                Spacer()

                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            currentPage += 1
                        }
                    } else {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    HStack(spacing: .spacing.x2) {
                        Text(currentPage < pages.count - 1 ? "onboarding.next".localized : "onboarding.start_button".localized)
                            .font(.system(size: .fontSize.medium, weight: .bold))
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "leaf.fill")
                            .font(.system(size: .fontSize.medium, weight: .bold))
                    }
                    .foregroundColor(.ecoInk)
                    .padding(.vertical, .spacing.x4)
                    .padding(.horizontal, .spacing.x8)
                    .background(Capsule().fill(.white))
                }
            }
        }
    }
}

// MARK: - Model

private struct OnboardingPage {
    let systemImage: String
    let titleKey: String
    let subtitleKey: String
    let cards: [OnboardingCard]

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "globe.americas.fill",
            titleKey: "onboarding.page1.title",
            subtitleKey: "onboarding.page1.subtitle",
            cards: [
                OnboardingCard(
                    id: "p1-card-1",
                    systemImage: "person.3.fill",
                    titleKey: "onboarding.page1.card1.title",
                    bodyKey: "onboarding.page1.card1.body"
                ),
                OnboardingCard(
                    id: "p1-card-2",
                    systemImage: "building.2.fill",
                    titleKey: "onboarding.page1.card2.title",
                    bodyKey: "onboarding.page1.card2.body"
                ),
            ]
        ),
        OnboardingPage(
            systemImage: "camera.viewfinder",
            titleKey: "onboarding.page2.title",
            subtitleKey: "onboarding.page2.subtitle",
            cards: [
                OnboardingCard(
                    id: "p2-card-1",
                    systemImage: "sparkles",
                    titleKey: "onboarding.page2.card1.title",
                    bodyKey: "onboarding.page2.card1.body"
                ),
                OnboardingCard(
                    id: "p2-card-2",
                    systemImage: "checkmark.seal.fill",
                    titleKey: "onboarding.page2.card2.title",
                    bodyKey: "onboarding.page2.card2.body"
                ),
            ]
        ),
        OnboardingPage(
            systemImage: "arrow.3.trianglepath",
            titleKey: "onboarding.page3.title",
            subtitleKey: "onboarding.page3.subtitle",
            cards: [
                OnboardingCard(
                    id: "p3-card-1",
                    systemImage: "chart.bar.fill",
                    titleKey: "onboarding.page3.card1.title",
                    bodyKey: "onboarding.page3.card1.body"
                ),
                OnboardingCard(
                    id: "p3-card-2",
                    systemImage: "person.2.fill",
                    titleKey: "onboarding.page3.card2.title",
                    bodyKey: "onboarding.page3.card2.body"
                ),
            ]
        ),
        OnboardingPage(
            systemImage: "chart.line.uptrend.xyaxis",
            titleKey: "onboarding.page4.title",
            subtitleKey: "onboarding.page4.subtitle",
            cards: [
                OnboardingCard(
                    id: "p4-card-1",
                    systemImage: "globe.americas.fill",
                    titleKey: "onboarding.page4.card1.title",
                    bodyKey: "onboarding.page4.card1.body"
                ),
                OnboardingCard(
                    id: "p4-card-2",
                    systemImage: "leaf.arrow.circlepath",
                    titleKey: "onboarding.page4.card2.title",
                    bodyKey: "onboarding.page4.card2.body"
                ),
            ]
        ),
    ]
}

private struct OnboardingCard: Identifiable {
    let id: String
    let systemImage: String
    let titleKey: String
    let bodyKey: String
}
