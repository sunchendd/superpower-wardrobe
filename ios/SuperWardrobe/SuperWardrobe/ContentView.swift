import SwiftUI

struct ContentView: View {
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab: SuperWardrobeShellTab = .recommendation
    @State private var showAddItem = false

    var body: some View {
        ZStack {
            WardrobeAppShell(
                selection: $selectedTab,
                onAdd: { showAddItem = true },
                recommendation: NavigationStack { RecommendationView() },
                wardrobe: NavigationStack { WardrobeView() },
                statistics: NavigationStack { StatisticsView() },
                settings: NavigationStack { SettingsAppView() }
            )
            .themeManager(themeManager)

            if !hasSeenOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        hasSeenOnboarding = true
                    }
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack {
                AddItemView()
            }
            .themeManager(themeManager)
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ContentView()
}
