import SwiftUI
import SwiftData

@main
struct SuperWardrobeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            .modelContainer(for: [
                ClothingItem.self,
                OutfitDiary.self,
            ])
            .task {
                LocationService.shared.requestPermission()
            }
        }
    }
}
