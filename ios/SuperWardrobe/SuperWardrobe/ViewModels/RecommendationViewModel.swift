import Foundation
import SwiftData

@Observable
final class RecommendationViewModel {
    var suggestions: [OutfitSuggestion] = []
    var weather: WeatherData?
    var isLoading: Bool = false
    var errorMessage: String?

    private let weatherService = WeatherService.shared
    private let locationService = LocationService.shared
    private let engine = LocalRecommendationEngine.shared

    // MARK: - Load

    func load(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        // Fetch weather
        if let loc = locationService.currentLocation {
            weather = try? await weatherService.fetchWeather(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude
            )
        }

        // Generate local recommendations
        let items = LocalDataService.shared.fetchClothingItems(context: context)
        suggestions = engine.generateSuggestions(from: items, weather: weather, count: 3)
    }

    func refresh(context: ModelContext) async {
        await load(context: context)
    }
}
