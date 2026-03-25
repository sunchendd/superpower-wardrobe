import Foundation
import SwiftData

@Observable
final class RecommendationViewModel {
    var recommendations: [DailyRecommendation] = []
    var localSuggestions: [OutfitSuggestion] = []
    var weather: WeatherData?
    var purchaseSuggestions: [PurchaseRecommendation] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var isGuestMode: Bool = false

    private let supabaseService = SupabaseService.shared
    private let weatherService = WeatherService.shared
    private let locationService = LocationService.shared
    private let engine = LocalRecommendationEngine.shared

    // MARK: - Load

    func loadTodayRecommendations(isGuest: Bool = false, context: ModelContext? = nil) async {
        isGuestMode = isGuest
        isLoading = true
        defer { isLoading = false }

        // Fetch weather regardless of mode
        await fetchWeather()

        if isGuest {
            await loadLocalRecommendations(context: context)
        } else {
            await loadRemoteRecommendations(context: context)
        }
    }

    // MARK: - Accept / Rate

    func acceptRecommendation(_ recommendation: DailyRecommendation) async {
        guard var updated = recommendations.first(where: { $0.id == recommendation.id }) else { return }
        updated.accepted = true
        do {
            try await supabaseService.client.from("daily_recommendations")
                .update(["accepted": true])
                .eq("id", value: updated.id.uuidString)
                .execute()
            if let index = recommendations.firstIndex(where: { $0.id == updated.id }) {
                recommendations[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rateFeedback(_ recommendation: DailyRecommendation, score: Int) async {
        do {
            try await supabaseService.client.from("daily_recommendations")
                .update(["feedback_score": score])
                .eq("id", value: recommendation.id.uuidString)
                .execute()
            if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
                recommendations[index].feedbackScore = score
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func fetchWeather() async {
        if let location = locationService.currentLocation {
            weather = try? await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    private func loadRemoteRecommendations(context: ModelContext?) async {
        guard let userId = await supabaseService.currentUserId else {
            isGuestMode = true
            await loadLocalRecommendations(context: context)
            return
        }

        do {
            async let recsTask = supabaseService.fetchDailyRecommendations(userId: userId, date: Date())
            async let purchaseTask = supabaseService.fetchPurchaseRecommendations(userId: userId)
            let (recs, purchases) = try await (recsTask, purchaseTask)
            recommendations = recs
            purchaseSuggestions = purchases

            // If no server recommendations, generate locally from remote items
            if recs.isEmpty {
                let items = try await supabaseService.fetchClothingItems(userId: userId)
                if !items.isEmpty {
                    recommendations = engine.generateSuggestionsFromRemote(
                        items: items,
                        weather: weather
                    )
                }
            }
        } catch {
            errorMessage = "加载推荐失败"
            await loadLocalRecommendations(context: context)
        }
    }

    private func loadLocalRecommendations(context: ModelContext?) async {
        guard let ctx = context else { return }
        let localItems = LocalDataService.shared.fetchClothingItems(context: ctx)
        guard !localItems.isEmpty else { return }
        localSuggestions = engine.generateSuggestions(from: localItems, weather: weather, count: 3)
    }
}
