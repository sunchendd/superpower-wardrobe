import XCTest
@testable import SuperWardrobe

final class RecommendationEngineTests: XCTestCase {
    func testWeatherConditionThresholdsAndHints() {
        let hot = WeatherCondition(temperature: 28)
        XCTAssertEqual(hot.preferredSeasons, ["summer", "all"])
        XCTAssertEqual(hot.layersNeeded, 1)
        XCTAssertEqual(hot.tip, "气温较高，建议穿着清凉透气的夏日单品")

        let mild = WeatherCondition(temperature: 12)
        XCTAssertEqual(mild.preferredSeasons, ["spring", "autumn", "all"])
        XCTAssertEqual(mild.layersNeeded, 2)
        XCTAssertEqual(mild.tip, "温度适中，可搭配薄外套以备不时之需")
    }

    func testGenerateSuggestionsFromRemoteUsesWeatherTipAndCapsCount() {
        let items = [
            TestFixtures.clothingItem(name: "白衬衫", season: "summer"),
            TestFixtures.clothingItem(name: "深色长裤", season: "all"),
        ]
        let weather = TestFixtures.weatherData(temperature: 30, condition: "Clear")

        let recommendations = LocalRecommendationEngine.shared.generateSuggestionsFromRemote(
            items: items,
            weather: weather,
            count: 7
        )

        XCTAssertEqual(recommendations.count, 5)
        XCTAssertTrue(recommendations.allSatisfy { $0.reasonText == "气温较高，建议穿着清凉透气的夏日单品" })
        XCTAssertTrue(recommendations.allSatisfy { $0.weatherData == "☀️ 30°C" })
    }

    func testGenerateSuggestionsFromRemoteFallsBackToDefaultReasonWithoutWeather() {
        let recommendations = LocalRecommendationEngine.shared.generateSuggestionsFromRemote(
            items: [TestFixtures.clothingItem()],
            weather: nil,
            count: 1
        )

        XCTAssertEqual(recommendations.count, 1)
        XCTAssertEqual(recommendations.first?.reasonText, "今日搭配推荐")
        XCTAssertNil(recommendations.first?.weatherData)
    }
}
