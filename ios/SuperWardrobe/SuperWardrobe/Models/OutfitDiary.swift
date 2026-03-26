import Foundation
import SwiftData

@Model
class OutfitDiary: Codable, Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var outfitId: UUID?
    var photoUrl: String?
    var note: String?
    var weatherData: String?
    var mood: String?
    var sharedAt: Date?
    var photoData: Data?
    var weatherDescription: String?
    var temperature: Double?
    var itemIds: [UUID]
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, date, note, mood
        case userId = "user_id"
        case outfitId = "outfit_id"
        case photoUrl = "photo_url"
        case weatherData = "weather_data"
        case sharedAt = "shared_at"
    }

    init(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        date: Date,
        outfitId: UUID? = nil,
        photoUrl: String? = nil,
        note: String? = nil,
        weatherData: String? = nil,
        mood: String? = nil,
        sharedAt: Date? = nil,
        photoData: Data? = nil,
        weatherDescription: String? = nil,
        temperature: Double? = nil,
        itemIds: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.outfitId = outfitId
        self.photoUrl = photoUrl
        self.note = note
        self.weatherData = weatherData ?? weatherDescription
        self.mood = mood
        self.sharedAt = sharedAt
        self.photoData = photoData
        self.weatherDescription = weatherDescription ?? weatherData
        self.temperature = temperature
        self.itemIds = itemIds
        self.createdAt = createdAt
    }

    static func == (lhs: OutfitDiary, rhs: OutfitDiary) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let userId = try container.decodeIfPresent(UUID.self, forKey: .userId) ?? UUID()
        let date = try container.decode(Date.self, forKey: .date)
        let outfitId = try container.decodeIfPresent(UUID.self, forKey: .outfitId)
        let photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        let note = try container.decodeIfPresent(String.self, forKey: .note)
        let weatherData = try container.decodeIfPresent(String.self, forKey: .weatherData)
        let mood = try container.decodeIfPresent(String.self, forKey: .mood)
        let sharedAt = try container.decodeIfPresent(Date.self, forKey: .sharedAt)

        self.init(
            id: id,
            userId: userId,
            date: date,
            outfitId: outfitId,
            photoUrl: photoUrl,
            note: note,
            weatherData: weatherData,
            mood: mood,
            sharedAt: sharedAt,
            photoData: nil,
            weatherDescription: weatherData,
            temperature: nil,
            itemIds: [],
            createdAt: Date()
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(outfitId, forKey: .outfitId)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(weatherData, forKey: .weatherData)
        try container.encodeIfPresent(mood, forKey: .mood)
        try container.encodeIfPresent(sharedAt, forKey: .sharedAt)
    }
}
