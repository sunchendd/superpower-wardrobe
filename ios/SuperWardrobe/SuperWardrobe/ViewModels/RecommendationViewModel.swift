import Foundation

@Observable
final class RecommendationViewModel {
    var recommendations: [DailyRecommendation] = []
    var weather: WeatherData?
    var purchaseSuggestions: [PurchaseRecommendation] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let supabaseService = SupabaseService.shared
    private let weatherService = WeatherService.shared
    private let locationService = LocationService.shared

    func loadTodayRecommendations() async {
        guard let userId = await supabaseService.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if let location = locationService.currentLocation {
                weather = try await weatherService.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }

            async let recsTask = supabaseService.fetchDailyRecommendations(userId: userId, date: Date())
            async let purchaseTask = supabaseService.fetchPurchaseRecommendations(userId: userId)
            let (recs, purchases) = try await (recsTask, purchaseTask)
            recommendations = recs
            purchaseSuggestions = purchases
        } catch {
            errorMessage = error.localizedDescription
        }
    }

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
}
