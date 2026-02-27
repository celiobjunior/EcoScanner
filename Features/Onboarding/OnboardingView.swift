import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            movingOceanGradient
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page, isFirst: index == 0)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: Double.duration.short), value: currentPage)
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

    var movingOceanGradient: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let wave = time * 0.28

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: .ecoSeaDeep, location: 0.0),
                        .init(color: .ecoSeaDeep.opacity(Double.opacity.nearOpaque), location: 0.38),
                        .init(color: .ecoSeaShore.opacity(Double.opacity.textEmphasis), location: 0.82),
                        .init(color: .ecoLight.opacity(Double.opacity.textLow), location: 1.0),
                    ],
                    startPoint: UnitPoint(
                        x: 0.18 + (0.09 * sin(wave * 0.55)),
                        y: 0.02 + (0.05 * cos(wave * 0.38))
                    ),
                    endPoint: UnitPoint(
                        x: 0.82 + (0.09 * cos(wave * 0.47)),
                        y: 0.98 + (0.05 * sin(wave * 0.43))
                    )
                )

                RadialGradient(
                    colors: [
                        Color.ecoLight.opacity(Double.opacity.strokeSoft),
                        .clear,
                    ],
                    center: UnitPoint(
                        x: 0.18 + (0.2 * sin(wave * 0.75)),
                        y: 0.22 + (0.12 * cos(wave * 0.52))
                    ),
                    startRadius: 8,
                    endRadius: 460
                )

                RadialGradient(
                    colors: [
                        Color.ecoSeaShore.opacity(Double.opacity.surfaceMuted),
                        Color.ecoSeaDeep.opacity(Double.opacity.surfaceSubtle),
                        .clear,
                    ],
                    center: UnitPoint(
                        x: 0.82 + (0.18 * cos(wave * 0.61)),
                        y: 0.82 + (0.14 * sin(wave * 0.49))
                    ),
                    startRadius: 6,
                    endRadius: 520
                )
            }
        }
    }

    func pageView(_ page: OnboardingPage, isFirst: Bool) -> some View {
        ScrollView(showsIndicators: false) {
            GlassEffectContainer {
            VStack(spacing: .spacing.x5) {
                heroView(isFirst: isFirst, systemImage: page.systemImage)

                VStack(spacing: .spacing.x2) {
                    Text(page.titleKey.localized)
                        .font(.system(size: .fontSize.huge, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.ecoSmoke)

                    Text(page.subtitleKey.localized)
                        .font(.system(size: .fontSize.medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.ecoSmoke.opacity(Double.opacity.textEmphasis))
                        .lineSpacing(.lineSpacing.regular)
                }
                .frame(maxWidth: .maxWidth.onboardingText)

                if !page.cards.isEmpty {
                    VStack(spacing: .spacing.x3) {
                        ForEach(page.cards) { card in
                            onboardingCard(card)
                        }
                    }
                    .frame(maxWidth: .maxWidth.onboardingCards)
                }

                if page.showsCategories {
                    categoriesSection
                        .frame(maxWidth: .maxWidth.onboardingCards)
                }

                if let tutorialAssetName = page.tutorialImageAssetName {
                    tutorialImageSection(assetName: tutorialAssetName)
                    .frame(maxWidth: .maxWidth.onboardingTutorial)
                }
            }
            .padding(.horizontal, .spacing.x6)
            .padding(.vertical, .spacing.x8)
            .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func heroView(isFirst: Bool, systemImage: String) -> some View {
        if isFirst {
            Image("EcoScannerLogoNoBg2")
                .resizable()
                .scaledToFit()
                .frame(width: .size.onboardingHeroLogo, height: .size.onboardingHeroLogo)
                .shadow(
                    color: .white.opacity(Double.opacity.glow),
                    radius: .shadow.heroRadius,
                    y: .shadow.mediumYOffset
                )
        } else {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: .size.onboardingSecondaryHero, height: .size.onboardingSecondaryHero)
                    .overlay(Circle().stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline))

                Image(systemName: systemImage)
                    .font(.system(size: .iconSize.jumbo, weight: .light))
                    .foregroundColor(.ecoSmoke)
            }
        }
    }

    func onboardingCard(_ card: OnboardingCard) -> some View {
        HStack(alignment: .top, spacing: .spacing.x3) {
            Image(systemName: card.systemImage)
                .font(.system(size: .fontSize.large, weight: .semibold))
                .foregroundColor(.ecoSmoke)
                .frame(width: .size.categoryBadgeIconSlot)

            VStack(alignment: .leading, spacing: .spacing.base) {
                Text(card.titleKey.localized)
                    .font(.system(size: .fontSize.small, weight: .bold))
                    .foregroundColor(.ecoSmoke)

                Text(card.bodyKey.localized)
                    .font(.system(size: .fontSize.small))
                    .foregroundColor(.ecoSmoke.opacity(Double.opacity.textHeadline))
                    .lineSpacing(.lineSpacing.compact)
            }
            Spacer(minLength: 0)
        }
        .padding(.spacing.x4)
        .glassEffect(.clear, in: .rect(cornerRadius: .borderRadius.large))
    }

    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: .spacing.x3) {
            VStack(alignment: .leading, spacing: .spacing.base) {
                Text("onboarding.categories.title".localized)
                    .font(.system(size: .fontSize.small, weight: .bold))
                    .foregroundColor(.ecoSmoke)

                Text("onboarding.categories.subtitle".localized)
                    .font(.system(size: .fontSize.small))
                    .foregroundColor(.ecoSmoke.opacity(Double.opacity.textHeadline))
                    .lineSpacing(.lineSpacing.compact)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: .spacing.x2),
                    GridItem(.flexible(), spacing: .spacing.x2),
                ],
                spacing: .spacing.x2
            ) {
                ForEach(WasteCategory.modelSupportedCases) { category in
                    categoryBadge(category)
                }
            }
        }
        .padding(.spacing.x4)
        .glassEffect(.clear, in: .rect(cornerRadius: .borderRadius.large))
    }

    func categoryBadge(_ category: WasteCategory) -> some View {
        HStack(spacing: .spacing.x2) {
            Image(systemName: category.systemImage)
                .font(.system(size: .fontSize.small, weight: .semibold))
                .foregroundColor(.white)

            Text(category.displayName)
                .font(.system(size: .fontSize.small, weight: .semibold))
                .foregroundColor(.ecoSmoke)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, .spacing.x2)
        .padding(.horizontal, .spacing.x3)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.smallPlus)
                .fill(category.color.opacity(Double.opacity.glow))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.smallPlus)
                        .stroke(category.color.opacity(Double.opacity.pageIndicator), lineWidth: .lineWidth.hairline)
                )
        )
    }

    func tutorialImageSection(assetName: String) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: .borderRadius.largePlus))
            .overlay(
                RoundedRectangle(cornerRadius: .borderRadius.largePlus)
                    .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
            )
    }

    var controls: some View {
        VStack(spacing: .spacing.x5) {
            HStack(spacing: .spacing.x2) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.ecoSmoke : Color.white.opacity(Double.opacity.pageIndicator))
                        .frame(
                            width: index == currentPage ? .size.indicatorActive : .size.indicator,
                            height: .size.indicator
                        )
                        .animation(.spring(response: Double.duration.regular), value: currentPage)
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
                        withAnimation(.spring(response: Double.duration.medium, dampingFraction: Double.damping.snappy)) {
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
