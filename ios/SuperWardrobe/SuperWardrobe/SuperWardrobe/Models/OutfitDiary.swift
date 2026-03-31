import Foundation

struct OutfitDiary: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var date: Date
    var outfitId: UUID?
    var photoUrl: String?
    var note: String?
    var weatherData: String?
    var mood: String?
    var sharedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, date, note, mood
        case userId = "user_id"
        case outfitId = "outfit_id"
        case photoUrl = "photo_url"
        case weatherData = "weather_data"
        case sharedAt = "shared_at"
    }
}
