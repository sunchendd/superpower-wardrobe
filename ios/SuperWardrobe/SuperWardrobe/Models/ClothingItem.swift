import Foundation
import SwiftData
import UIKit

@Model
class ClothingItem: Codable, Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var categoryId: UUID?
    var name: String?
    var imageUrl: String?
    var imageData: Data?
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
    var categoryName: String?
    var categoryIcon: String?
    var notes: String?

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

    init(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        categoryId: UUID? = nil,
        name: String? = nil,
        imageUrl: String? = nil,
        imageData: Data? = nil,
        brand: String? = nil,
        color: String = "#808080",
        season: String? = "all",
        styleTags: [String] = [],
        purchasePrice: Double? = nil,
        purchaseDate: Date? = nil,
        purchaseUrl: String? = nil,
        wearCount: Int = 0,
        status: String = "active",
        createdAt: Date = Date(),
        categoryName: String? = nil,
        categoryIcon: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.categoryId = categoryId
        self.name = name
        self.imageUrl = imageUrl
        self.imageData = imageData
        self.brand = brand
        self.color = color
        self.season = season
        self.styleTags = styleTags
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.purchaseUrl = purchaseUrl
        self.wearCount = wearCount
        self.status = status
        self.createdAt = createdAt
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.notes = notes
    }

    var thumbnail: UIImage? {
        guard let imageData else { return nil }
        return ImageStorage.thumbnail(from: imageData)
    }

    static func placeholder() -> ClothingItem {
        ClothingItem(
            id: UUID(),
            userId: UUID(),
            categoryId: nil,
            name: "示例衣物",
            imageUrl: nil,
            imageData: nil,
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

    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let userId = try container.decodeIfPresent(UUID.self, forKey: .userId) ?? UUID()
        let categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        let brand = try container.decodeIfPresent(String.self, forKey: .brand)
        let color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#808080"
        let season = try container.decodeIfPresent(String.self, forKey: .season)
        let styleTags = try container.decodeIfPresent([String].self, forKey: .styleTags) ?? []
        let purchasePrice = try container.decodeIfPresent(Double.self, forKey: .purchasePrice)
        let purchaseDate = try container.decodeIfPresent(Date.self, forKey: .purchaseDate)
        let purchaseUrl = try container.decodeIfPresent(String.self, forKey: .purchaseUrl)
        let wearCount = try container.decodeIfPresent(Int.self, forKey: .wearCount) ?? 0
        let status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()

        self.init(
            id: id,
            userId: userId,
            categoryId: categoryId,
            name: name,
            imageUrl: imageUrl,
            imageData: nil,
            brand: brand,
            color: color,
            season: season,
            styleTags: styleTags,
            purchasePrice: purchasePrice,
            purchaseDate: purchaseDate,
            purchaseUrl: purchaseUrl,
            wearCount: wearCount,
            status: status,
            createdAt: createdAt
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encode(color, forKey: .color)
        try container.encodeIfPresent(season, forKey: .season)
        try container.encode(styleTags, forKey: .styleTags)
        try container.encodeIfPresent(purchasePrice, forKey: .purchasePrice)
        try container.encodeIfPresent(purchaseDate, forKey: .purchaseDate)
        try container.encodeIfPresent(purchaseUrl, forKey: .purchaseUrl)
        try container.encode(wearCount, forKey: .wearCount)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
