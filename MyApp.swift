import SwiftUI
import SwiftData

@main
struct EcoScannerApp: App {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let modelContainer: ModelContainer
    @StateObject private var profileManager: UserProfileManager
    @StateObject private var wasteDetector = WasteDetector()
    @StateObject private var cameraManager = CameraManager()

    init() {
        #if DEBUG
        // Keep onboarding visible on each run during development/testing.
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        #endif

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
                MainTabView()
                    .environmentObject(wasteDetector)
                    .environmentObject(profileManager)
                    .environmentObject(cameraManager)
            } else {
                OnboardingView()
            }
        }
        .modelContainer(modelContainer)
    }
}
