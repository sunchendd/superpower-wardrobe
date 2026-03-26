import CoreLocation
import Foundation
import Observation
import WeatherKit

protocol WeatherProviding {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData
}

@Observable
final class WeatherKitService: WeatherProviding {
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
                windDirection: localizedWindDirection(from: String(describing: currentWeather.wind.compassDirection)),
                description: currentWeather.condition.description
            )
        } catch {
            throw WeatherKitServiceError.weatherKitUnavailable(error)
        }
    }

    private func localizedWindDirection(from rawDirection: String) -> String {
        let normalized = rawDirection
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .lowercased()

        let mapping: [String: String] = [
            "north": "北风",
            "northeast": "东北风",
            "east": "东风",
            "southeast": "东南风",
            "south": "南风",
            "southwest": "西南风",
            "west": "西风",
            "northwest": "西北风",
            "northnortheast": "北偏东北风",
            "eastnortheast": "东偏东北风",
            "eastsoutheast": "东偏东南风",
            "southsoutheast": "南偏东南风",
            "southsouthwest": "南偏西南风",
            "westsouthwest": "西偏西南风",
            "westnorthwest": "西偏西北风",
            "northnorthwest": "北偏西北风"
        ]

        return mapping[normalized] ?? "东南风"
    }
}
