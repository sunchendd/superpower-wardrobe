import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var icon: String?
    var sortOrder: Int
    var parentId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case sortOrder = "sort_order"
        case parentId = "parent_id"
    }

    static let defaultCategories: [Category] = [
        Category(id: UUID(), name: "上衣", icon: "tshirt", sortOrder: 0, parentId: nil),
        Category(id: UUID(), name: "裤子", icon: "figure.walk", sortOrder: 1, parentId: nil),
        Category(id: UUID(), name: "裙子", icon: "sparkles", sortOrder: 2, parentId: nil),
        Category(id: UUID(), name: "外套", icon: "cloud.snow", sortOrder: 3, parentId: nil),
        Category(id: UUID(), name: "鞋子", icon: "shoe", sortOrder: 4, parentId: nil),
        Category(id: UUID(), name: "配饰", icon: "crown", sortOrder: 5, parentId: nil),
    ]
}
