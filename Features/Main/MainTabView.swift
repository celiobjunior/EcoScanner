import SwiftUI
import SwiftData

// MARK: - MainTabView

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var selectedTab: SidebarTab? = .scanner
    @State private var showHelp = false
    @State private var showCredits = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .tint(.ecoPrimary)
        .onAppear {
            _updateContext()
        }
        .sheet(isPresented: $showHelp) {
            HelpTutorialView()
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }
}

// MARK: - SidebarTab

enum SidebarTab: String, Identifiable, CaseIterable, Sendable {
    case scanner, history, profile

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .scanner: return "navigation.scanner"
        case .history: return "navigation.history"
        case .profile: return "navigation.profile"
        }
    }

    var systemImage: String {
        switch self {
        case .scanner: return "viewfinder"
        case .history: return "clock.arrow.circlepath"
        case .profile: return "person.crop.circle"
        }
    }
}

// MARK: - Sidebar

private extension MainTabView {

    var sidebar: some View {
        List(selection: $selectedTab) {
            ForEach(SidebarTab.allCases) { tab in
                Label(tab.labelKey.localized, systemImage: tab.systemImage)
                    .tag(tab)
            }

            Section {
                Button {
                    showHelp = true
                } label: {
                    Label("navigation.help".localized, systemImage: "questionmark.circle")
                }

                Button {
                    showCredits = true
                } label: {
                    Label("navigation.credits".localized, systemImage: "heart.text.square")
                }
            }
        }
        .tint(.ecoPrimary)
        .navigationTitle("app.name".localized)
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        #endif
    }

    @ViewBuilder
    var detailView: some View {
        switch selectedTab {
        case .scanner, .none:
            ScannerView()
        case .history:
            EcoHistoryView()
        case .profile:
            ProfileView()
        }
    }
}

// MARK: - Context Update

private extension MainTabView {

    func _updateContext() {
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = try? modelContext.fetch(descriptor)

        if let profile = existing?.first {
            profileManager.profile = profile
        } else {
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
            try? modelContext.save()
            profileManager.profile = newProfile
        }

        profileManager.modelContext = modelContext
    }
}
