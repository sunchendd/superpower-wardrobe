import SwiftUI
import SwiftData

@main
struct SuperWardrobeApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                        .environment(authViewModel)
                } else {
                    AuthView(viewModel: authViewModel)
                        .environment(authViewModel)
                }
            }
            .modelContainer(for: [
                LocalClothingItem.self,
                LocalOutfitDiary.self,
                LocalTravelPlan.self,
            ])
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
            .task {
                await authViewModel.checkAuthState()
                // Request location permission on launch
                LocationService.shared.requestPermission()
            }
        }
    }
}
