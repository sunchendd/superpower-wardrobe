import Foundation
import SwiftData

@Observable
final class RecommendationViewModel {
    var suggestions: [OutfitSuggestion] = []
    var weather: WeatherData?
    var locationName: String = "定位中"
    var isLoading: Bool = false
    var errorMessage: String?

    private let weatherService: WeatherProviding
    private let locationService: LocationProviding
    private let engine: LocalRecommendationEngine

    init(
        weatherService: WeatherProviding = WeatherKitService.shared,
        locationService: LocationProviding = LocationService.shared,
        engine: LocalRecommendationEngine = .shared
    ) {
        self.weatherService = weatherService
        self.locationService = locationService
        self.engine = engine
    }

    var locationLine: String {
        "\(locationName) · \(Date().weekdayString)"
    }

    var weatherSummary: String {
        weather?.description ?? "天气获取中"
    }

    var windSummary: String {
        weather?.windSummary ?? "风力获取中"
    }

    var umbrellaAdvice: String {
        weather?.umbrellaAdvice ?? "天气获取中"
    }

    // MARK: - Load

    func load(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let location = try await locationService.fetchCurrentLocation()
            locationName = try await locationService.resolveLocality(for: location) ?? "当前位置"
            weather = try await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            locationName = "定位失败"
            errorMessage = nil
        }

        let items = LocalDataService.shared.fetchClothingItems(context: context)
        suggestions = engine.generateSuggestions(from: items, weather: weather, count: 3)
    }

    func refresh(context: ModelContext) async {
        await load(context: context)
    }
}
