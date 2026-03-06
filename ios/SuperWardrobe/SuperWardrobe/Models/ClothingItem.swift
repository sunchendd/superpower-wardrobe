import Foundation

struct ClothingItem: Codable, Identifiable, Hashable {
    let id: UUID
    var userId: UUID
    var categoryId: UUID?
    var name: String?
    var imageUrl: String?
    var brand: String?
    var color: String
    var season: String?
    var styleTags: [String]
    var purchasePrice: Double?
    var purchaseDate: Date?
    var purchaseUrl: String?
    var wearCount: Int
    var status: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, brand, color, season, status
        case userId = "user_id"
        case categoryId = "category_id"
        case imageUrl = "image_url"
        case styleTags = "style_tags"
        case purchasePrice = "purchase_price"
        case purchaseDate = "purchase_date"
        case purchaseUrl = "purchase_url"
        case wearCount = "wear_count"
        case createdAt = "created_at"
    }

    static func placeholder() -> ClothingItem {
        ClothingItem(
            id: UUID(),
            userId: UUID(),
            categoryId: nil,
            name: "示例衣物",
            imageUrl: nil,
            brand: nil,
            color: "#000000",
            season: "all",
            styleTags: [],
            purchasePrice: nil,
            purchaseDate: nil,
            purchaseUrl: nil,
            wearCount: 0,
            status: "active",
            createdAt: Date()
        )
    }
}
