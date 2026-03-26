import CoreLocation
import Foundation
import Observation
import WeatherKit

@Observable
final class WeatherKitService {
    static let shared = WeatherKitService()

    enum WeatherKitServiceError: LocalizedError {
        case invalidLocation
        case weatherKitUnavailable(Error)

        var errorDescription: String? {
            switch self {
            case .invalidLocation:
                return "Invalid weather location"
            case .weatherKitUnavailable(let error):
                return "WeatherKit error: \(error.localizedDescription)"
            }
        }
    }

    private let weatherService = WeatherKit.WeatherService.shared

    private init() {}

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw WeatherKitServiceError.invalidLocation
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let currentWeather = try await weatherService.weather(for: location, including: .current)
            return WeatherData(
                temperature: currentWeather.temperature.value,
                condition: currentWeather.condition.description,
                icon: currentWeather.symbolName,
                humidity: Int(currentWeather.humidity * 100),
                windSpeed: currentWeather.wind.speed.value,
                description: currentWeather.condition.description
            )
        } catch {
            throw WeatherKitServiceError.weatherKitUnavailable(error)
        }
    }
}
