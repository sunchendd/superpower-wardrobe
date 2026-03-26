import CoreLocation
import SwiftData
import XCTest
@testable import SuperWardrobe

final class RecommendationViewModelTests: XCTestCase {
    func testLoadPopulatesLocationAndWeatherSummary() async throws {
        let modelContext = try makeInMemoryContext()
        let location = CLLocation(latitude: 30.2741, longitude: 120.1551)
        let locationService = MockLocationService(
            location: location,
            locality: "杭州"
        )
        let weatherService = MockWeatherService(
            weather: TestFixtures.weatherData(
                temperature: 22,
                condition: "Clear",
                humidity: 61,
                windSpeed: 2.4,
                description: "多云转晴"
            )
        )

        let viewModel = RecommendationViewModel(
            weatherService: weatherService,
            locationService: locationService,
            engine: .shared
        )

        await viewModel.load(context: modelContext)

        XCTAssertEqual(viewModel.locationName, "杭州")
        XCTAssertEqual(viewModel.weather?.temperatureFormatted, "22°C")
        XCTAssertEqual(viewModel.weatherSummary, "多云转晴")
        XCTAssertEqual(viewModel.windSummary, "东南风 2 级")
        XCTAssertTrue(locationService.fetchCurrentLocationCalled)
    }

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            ClothingItem.self,
            OutfitDiary.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return ModelContext(container)
    }
}

private struct MockWeatherService: WeatherProviding {
    let weather: WeatherData

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        weather
    }
}

private final class MockLocationService: LocationProviding {
    let location: CLLocation
    let locality: String
    var fetchCurrentLocationCalled = false

    init(location: CLLocation, locality: String) {
        self.location = location
        self.locality = locality
    }

    func fetchCurrentLocation() async throws -> CLLocation {
        fetchCurrentLocationCalled = true
        return location
    }

    func resolveLocality(for location: CLLocation) async throws -> String? {
        locality
    }
}
