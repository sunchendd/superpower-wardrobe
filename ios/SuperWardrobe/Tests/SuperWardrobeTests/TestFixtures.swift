import Foundation

enum TestFixtures {
    static func clothingItem(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        name: String? = "测试单品",
        color: String = "#336699",
        season: String = "all",
        styleTags: [String] = ["简约"],
        status: String = "active",
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> ClothingItem {
        ClothingItem(
            id: id,
            userId: userId,
            categoryId: nil,
            name: name,
            imageUrl: nil,
            brand: nil,
            color: color,
            season: season,
            styleTags: styleTags,
            purchasePrice: nil,
            purchaseDate: nil,
            purchaseUrl: nil,
            wearCount: 0,
            status: status,
            createdAt: createdAt
        )
    }

    static func weatherData(
        temperature: Double = 24,
        condition: String = "Clear",
        icon: String = "01d",
        humidity: Int = 50,
        windSpeed: Double = 3.2,
        description: String = "晴"
    ) -> WeatherData {
        WeatherData(
            temperature: temperature,
            condition: condition,
            icon: icon,
            humidity: humidity,
            windSpeed: windSpeed,
            description: description
        )
    }
}
