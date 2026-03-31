import Foundation

struct WeatherData: Codable {
    let temperature: Double
    let condition: String
    let icon: String
    let humidity: Int
    let windSpeed: Double
    let description: String

    enum CodingKeys: String, CodingKey {
        case temperature = "temp"
        case condition, icon, humidity, description
        case windSpeed = "wind_speed"
    }

    var temperatureFormatted: String {
        String(format: "%.0f°C", temperature)
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
        let apiKey = UserDefaults.standard.string(forKey: "weather_api_key") ?? ""
        guard !apiKey.isEmpty else {
            throw NSError(domain: "WeatherService", code: 401, userInfo: [NSLocalizedDescriptionKey: "未配置天气 API Key"])
        }
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
            description: weatherInfo?.description ?? ""
        )
    }
}
