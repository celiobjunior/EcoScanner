import SwiftUI

// MARK: - OnboardingPage

struct OnboardingPage {
    let systemImage: String
    let titleKey: String
    let subtitleKey: String
    let cards: [OnboardingCard]
    let showsCategories: Bool
    let tutorialImageAssetName: String?

    static var pages: [OnboardingPage] {
        commonPages(tutorialAssetName: tutorialAssetName)
    }

    private static var tutorialAssetName: String {
        if LocalizationStore.shouldUsePortuguese {
            return "TutorialImagePT"
        } else {
            return "TutorialImageEN"
        }
    }

    private static func commonPages(tutorialAssetName: String) -> [OnboardingPage] {
        [
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
                ],
                showsCategories: false,
                tutorialImageAssetName: nil
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
                ],
                showsCategories: false,
                tutorialImageAssetName: nil
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
                ],
                showsCategories: true,
                tutorialImageAssetName: nil
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
                ],
                showsCategories: false,
                tutorialImageAssetName: nil
            ),
            OnboardingPage(
                systemImage: "questionmark",
                titleKey: "onboarding.page5.title",
                subtitleKey: "onboarding.page5.subtitle",
                cards: [],
                showsCategories: false,
                tutorialImageAssetName: tutorialAssetName
            ),
        ]
    }
}
