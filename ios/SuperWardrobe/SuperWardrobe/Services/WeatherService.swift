import Foundation

struct WeatherData: Codable {
    let temperature: Double
    let condition: String
    let icon: String
    let humidity: Int
    let windSpeed: Double
    let windDirection: String?
    let description: String

    init(
        temperature: Double,
        condition: String,
        icon: String,
        humidity: Int,
        windSpeed: Double,
        windDirection: String? = nil,
        description: String
    ) {
        self.temperature = temperature
        self.condition = condition
        self.icon = icon
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case temperature = "temp"
        case condition, icon, humidity, windDirection, description
        case windSpeed = "wind_speed"
    }

    var temperatureFormatted: String {
        String(format: "%.0f°C", temperature)
    }

    var windLevel: Int {
        switch windSpeed {
        case ..<0.3: return 0
        case ..<1.6: return 1
        case ..<3.4: return 2
        case ..<5.5: return 3
        case ..<8.0: return 4
        case ..<10.8: return 5
        case ..<13.9: return 6
        case ..<17.2: return 7
        case ..<20.8: return 8
        case ..<24.5: return 9
        case ..<28.5: return 10
        case ..<32.7: return 11
        default: return 12
        }
    }

    var windSummary: String {
        "\(windDirection ?? "东南风") \(windLevel) 级"
    }

    var umbrellaAdvice: String {
        let lowered = condition.lowercased()
        if lowered.contains("rain") || lowered.contains("drizzle") || lowered.contains("thunder") {
            return "记得带伞"
        }
        return "不用带伞"
    }

    var weatherEmoji: String {
        switch condition.lowercased() {
        case let c where c.contains("clear"): return "☀️"
        case let c where c.contains("cloud"): return "☁️"
        case let c where c.contains("rain"): return "🌧️"
        case let c where c.contains("snow"): return "❄️"
        case let c where c.contains("thunder"): return "⛈️"
        case let c where c.contains("fog"), let c where c.contains("mist"): return "🌫️"
        default: return "🌤️"
        }
    }
}

final class WeatherService {
    static let shared = WeatherService()
    private init() {}

    private struct OpenWeatherResponse: Codable {
        let main: MainData
        let weather: [WeatherInfo]
        let wind: WindData

        struct MainData: Codable {
            let temp: Double
            let humidity: Int
        }

        struct WeatherInfo: Codable {
            let main: String
            let description: String
            let icon: String
        }

        struct WindData: Codable {
            let speed: Double
        }
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        let apiKey = Constants.openWeatherAPIKey
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&units=metric&lang=zh_cn&appid=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
        let weatherInfo = response.weather.first

        return WeatherData(
            temperature: response.main.temp,
            condition: weatherInfo?.main ?? "Unknown",
            icon: weatherInfo?.icon ?? "01d",
            humidity: response.main.humidity,
            windSpeed: response.wind.speed,
            windDirection: nil,
            description: weatherInfo?.description ?? ""
        )
    }
}
