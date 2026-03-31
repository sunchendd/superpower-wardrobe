import CoreLocation
import Foundation

@Observable
final class RecommendationViewModel {
    var recommendations: [DailyRecommendation] = []
    var wardrobe: [ClothingItem] = []
    var weather: WeatherData?
    var purchaseSuggestions: [PurchaseRecommendation] = []
    var isLoading: Bool = false
    var isGenerating: Bool = false
    var errorMessage: String?

    private let service = LocalDataService.shared
    private let weatherService = WeatherService.shared
    private let locationService = LocationService.shared

    func loadTodayRecommendations() async {
        isLoading = true
        defer { isLoading = false }

        // 触发定位权限，使用带10秒超时的异步定位
        locationService.requestPermission()
        let location: CLLocation?
        do {
            location = try await locationService.fetchCurrentLocation(timeout: 10)
        } catch {
            // 定位失败或超时，退回到北京坐标
            location = CLLocation(latitude: 39.9042, longitude: 116.4074)
        }

        // 拉取天气
        do {
            if let loc = location {
                weather = try await weatherService.fetchWeather(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude
                )
            }
        } catch { }

        // 读取今日缓存推荐
        let cached = service.fetchDailyRecommendations(date: Date())
        if !cached.isEmpty {
            recommendations = cached
            wardrobe = service.fetchClothingItems()
            purchaseSuggestions = service.fetchPurchaseRecommendations()
            return
        }

        // 有 AI Key + 有衣物 → 自动生成
        let wardrobeItems = service.fetchClothingItems()
        wardrobe = wardrobeItems
        guard AIService.shared.isConfigured, !wardrobeItems.isEmpty else {
            purchaseSuggestions = service.fetchPurchaseRecommendations()
            return
        }

        await generateRecommendations(wardrobe: wardrobeItems)
        purchaseSuggestions = service.fetchPurchaseRecommendations()
    }

    func refreshRecommendations() async {
        isGenerating = true
        defer { isGenerating = false }

        // 重新获取天气
        do {
            if let loc = locationService.currentLocation {
                weather = try await weatherService.fetchWeather(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude
                )
            }
        } catch { }

        let wardrobeItems = service.fetchClothingItems()
        wardrobe = wardrobeItems
        guard AIService.shared.isConfigured else {
            errorMessage = AIError.noAPIKey.localizedDescription
            return
        }
        guard !wardrobeItems.isEmpty else {
            errorMessage = "衣橱暂无衣物，请先添加衣物"
            return
        }
        await generateRecommendations(wardrobe: wardrobeItems)
    }

    func acceptRecommendation(_ recommendation: DailyRecommendation) async {
        guard var updated = recommendations.first(where: { $0.id == recommendation.id }) else { return }
        updated.accepted = true
        service.saveDailyRecommendation(updated)
        if let index = recommendations.firstIndex(where: { $0.id == updated.id }) {
            recommendations[index] = updated
        }

        // Create OutfitDiary entry
        let diary = OutfitDiary(
            id: UUID(),
            userId: service.currentUserId,
            date: Date(),
            outfitId: nil,
            photoUrl: nil,
            note: recommendation.reasonText ?? "",
            weatherData: nil,
            mood: "😊",
            sharedAt: nil
        )
        service.saveOutfitDiary(diary)

        // Increment wearCount for each clothing item
        for idStr in recommendation.clothingIds {
            if let uuid = UUID(uuidString: idStr) {
                service.incrementWearCount(id: uuid)
            }
        }
    }

    func rateFeedback(_ recommendation: DailyRecommendation, score: Int) async {
        guard var updated = recommendations.first(where: { $0.id == recommendation.id }) else { return }
        updated.feedbackScore = score
        service.saveDailyRecommendation(updated)
        if let index = recommendations.firstIndex(where: { $0.id == updated.id }) {
            recommendations[index] = updated
        }
    }

    func rateRecommendation(id: UUID, rating: Int) {
        if let idx = recommendations.firstIndex(where: { $0.id == id }) {
            recommendations[idx].rating = rating
            service.saveDailyRecommendation(recommendations[idx])
        }
    }

    // MARK: - Private

    private func generateRecommendations(wardrobe: [ClothingItem]) async {
        do {
            let profile = service.fetchUserProfile()
            let stylePrefs = profile?.stylePreferences ?? []
            let suggestions = try await AIService.shared.generateOutfitRecommendations(
                wardrobe: wardrobe,
                weather: weather,
                stylePreferences: stylePrefs
            )
            let userId = service.currentUserId
            let weatherString = weather.map { "天气:\($0.description)，温度:\(Int($0.temperature))°C" }
            let recs: [DailyRecommendation] = suggestions.map { s in
                DailyRecommendation(
                    id: UUID(),
                    userId: userId,
                    date: Date(),
                    outfitId: nil,
                    weatherData: weatherString,
                    reasonText: "【\(s.themeName)】\(s.reason)（\(s.occasion)）",
                    accepted: false,
                    feedbackScore: nil,
                    clothingIds: s.clothingIds
                )
            }
            for rec in recs { service.saveDailyRecommendation(rec) }
            recommendations = recs
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
