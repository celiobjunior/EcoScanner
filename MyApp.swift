import SwiftUI
import SwiftData

@main
struct EcoScannerApp: App {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedFirstGuidedScan") private var hasCompletedFirstGuidedScan = false

    let modelContainer: ModelContainer
    @StateObject private var profileManager: UserProfileManager
    @StateObject private var wasteDetector = WasteDetector()
    @StateObject private var cameraManager = CameraManager()

    init() {
        do {
            let container = try ModelContainer(
                for: UserProfile.self, CollectionEntry.self
            )
            self.modelContainer = container
            let manager = UserProfileManager(modelContext: container.mainContext)
            self._profileManager = StateObject(wrappedValue: manager)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                if hasCompletedFirstGuidedScan {
                    MainTabView()
                        .environmentObject(wasteDetector)
                        .environmentObject(profileManager)
                        .environmentObject(cameraManager)
                } else {
                    GuidedFirstScanView()
                        .environmentObject(wasteDetector)
                        .environmentObject(profileManager)
                        .environmentObject(cameraManager)
                }
            } else {
                OnboardingView()
            }
        }
        .modelContainer(modelContainer)
    }
}
