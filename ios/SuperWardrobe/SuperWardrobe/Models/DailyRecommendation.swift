import Foundation

struct DailyRecommendation: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var date: Date
    var outfitId: UUID?
    var weatherData: String?
    var reasonText: String?
    var accepted: Bool?
    var feedbackScore: Int?

    enum CodingKeys: String, CodingKey {
        case id, date, accepted
        case userId = "user_id"
        case outfitId = "outfit_id"
        case weatherData = "weather_data"
        case reasonText = "reason_text"
        case feedbackScore = "feedback_score"
    }
}
