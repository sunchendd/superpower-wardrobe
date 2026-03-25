import SwiftUI
import SwiftData

@main
struct SuperWardrobeApp: App {
    @State private var purchaseService = PurchaseService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if purchaseService.isPurchased {
                    ContentView()
                        .environment(purchaseService)
                } else {
                    PaywallView()
                        .environment(purchaseService)
                }
            }
            .modelContainer(for: [
                LocalClothingItem.self,
                LocalOutfitDiary.self,
                LocalTravelPlan.self,
            ])
            .animation(.easeInOut(duration: 0.4), value: purchaseService.isPurchased)
            .task {
                LocationService.shared.requestPermission()
            }
        }
    }
}
