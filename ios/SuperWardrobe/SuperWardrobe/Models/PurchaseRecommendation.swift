import Foundation

struct PurchaseRecommendation: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var categoryId: UUID?
    var reason: String?
    var description: String?
    var styleTags: [String]?
    var season: String?
    var priority: Int
    var status: String

    enum CodingKeys: String, CodingKey {
        case id, reason, description, season, priority, status
        case userId = "user_id"
        case categoryId = "category_id"
        case styleTags = "style_tags"
    }
}
