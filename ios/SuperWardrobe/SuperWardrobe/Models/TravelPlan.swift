import Foundation

struct TravelPlan: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var title: String
    var destination: String?
    var startDate: Date
    var endDate: Date

    enum CodingKeys: String, CodingKey {
        case id, title, destination
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct TravelPlanOutfit: Codable, Identifiable {
    let id: UUID
    var travelPlanId: UUID
    var date: Date
    var outfitId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, date
        case travelPlanId = "travel_plan_id"
        case outfitId = "outfit_id"
    }
}
