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
    var clothingIds: [String] = []
    var rating: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, date, accepted, rating
        case userId = "user_id"
        case outfitId = "outfit_id"
        case weatherData = "weather_data"
        case reasonText = "reason_text"
        case feedbackScore = "feedback_score"
        case clothingIds = "clothing_ids"
    }

    init(
        id: UUID,
        userId: UUID,
        date: Date,
        outfitId: UUID? = nil,
        weatherData: String? = nil,
        reasonText: String? = nil,
        accepted: Bool? = nil,
        feedbackScore: Int? = nil,
        clothingIds: [String] = [],
        rating: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.outfitId = outfitId
        self.weatherData = weatherData
        self.reasonText = reasonText
        self.accepted = accepted
        self.feedbackScore = feedbackScore
        self.clothingIds = clothingIds
        self.rating = rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        date = try container.decode(Date.self, forKey: .date)
        outfitId = try container.decodeIfPresent(UUID.self, forKey: .outfitId)
        weatherData = try container.decodeIfPresent(String.self, forKey: .weatherData)
        reasonText = try container.decodeIfPresent(String.self, forKey: .reasonText)
        accepted = try container.decodeIfPresent(Bool.self, forKey: .accepted)
        feedbackScore = try container.decodeIfPresent(Int.self, forKey: .feedbackScore)
        clothingIds = try container.decodeIfPresent([String].self, forKey: .clothingIds) ?? []
        rating = try container.decodeIfPresent(Int.self, forKey: .rating) ?? 0
    }
}
