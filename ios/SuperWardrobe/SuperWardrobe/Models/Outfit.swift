import Foundation

struct Outfit: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var name: String?
    var occasion: String?
    var rating: Int?
    var source: String?
    var season: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, occasion, rating, source, season
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct OutfitItem: Codable, Identifiable {
    let id: UUID
    var outfitId: UUID
    var clothingItemId: UUID
    var layerOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case outfitId = "outfit_id"
        case clothingItemId = "clothing_item_id"
        case layerOrder = "layer_order"
    }
}
