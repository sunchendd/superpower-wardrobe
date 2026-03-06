import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    var phone: String?
    var bodyInfo: String?
    var stylePreferences: [String]?
    var location: String?

    enum CodingKeys: String, CodingKey {
        case id, phone, location
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bodyInfo = "body_info"
        case stylePreferences = "style_preferences"
    }
}
