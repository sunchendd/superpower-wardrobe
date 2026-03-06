import Foundation
import Supabase

@Observable
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Constants.supabaseURL)!,
            supabaseKey: Constants.supabaseAnonKey
        )
    }

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Clothing Items

    func fetchClothingItems(userId: UUID) async throws -> [ClothingItem] {
        try await client.from("clothing_items")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func addClothingItem(_ item: ClothingItem) async throws {
        try await client.from("clothing_items")
            .insert(item)
            .execute()
    }

    func updateClothingItem(_ item: ClothingItem) async throws {
        try await client.from("clothing_items")
            .update(item)
            .eq("id", value: item.id.uuidString)
            .execute()
    }

    func deleteClothingItem(id: UUID) async throws {
        try await client.from("clothing_items")
            .update(["status": "deleted"])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [Category] {
        try await client.from("categories")
            .select()
            .order("sort_order", ascending: true)
            .execute()
            .value
    }

    // MARK: - Outfits

    func fetchOutfits(userId: UUID) async throws -> [Outfit] {
        try await client.from("outfits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createOutfit(_ outfit: Outfit, items: [OutfitItem]) async throws {
        try await client.from("outfits")
            .insert(outfit)
            .execute()
        if !items.isEmpty {
            try await client.from("outfit_items")
                .insert(items)
                .execute()
        }
    }

    // MARK: - Outfit Diary

    func fetchOutfitDiary(userId: UUID, month: Date) async throws -> [OutfitDiary] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        let formatter = ISO8601DateFormatter()
        return try await client.from("outfit_diary")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: formatter.string(from: startOfMonth))
            .lt("date", value: formatter.string(from: endOfMonth))
            .order("date", ascending: false)
            .execute()
            .value
    }

    func saveOutfitDiary(_ diary: OutfitDiary) async throws {
        try await client.from("outfit_diary")
            .upsert(diary)
            .execute()
    }

    // MARK: - Daily Recommendations

    func fetchDailyRecommendations(userId: UUID, date: Date) async throws -> [DailyRecommendation] {
        let formatter = ISO8601DateFormatter()
        return try await client.from("daily_recommendations")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: formatter.string(from: date))
            .execute()
            .value
    }

    // MARK: - Purchase Recommendations

    func fetchPurchaseRecommendations(userId: UUID) async throws -> [PurchaseRecommendation] {
        try await client.from("purchase_recommendations")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "active")
            .order("priority", ascending: true)
            .execute()
            .value
    }

    // MARK: - Travel Plans

    func fetchTravelPlans(userId: UUID) async throws -> [TravelPlan] {
        try await client.from("travel_plans")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("start_date", ascending: true)
            .execute()
            .value
    }

    func createTravelPlan(_ plan: TravelPlan) async throws {
        try await client.from("travel_plans")
            .insert(plan)
            .execute()
    }

    func addTravelPlanOutfit(planId: UUID, date: Date, outfitId: UUID) async throws {
        let item = TravelPlanOutfit(
            id: UUID(),
            travelPlanId: planId,
            date: date,
            outfitId: outfitId
        )
        try await client.from("travel_plan_outfits")
            .insert(item)
            .execute()
    }

    // MARK: - User Profile

    func fetchUserProfile(userId: UUID) async throws -> UserProfile? {
        let profiles: [UserProfile] = try await client.from("user_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        return profiles.first
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        try await client.from("user_profiles")
            .upsert(profile)
            .execute()
    }

    // MARK: - Storage

    func uploadImage(data: Data, bucket: String, path: String) async throws -> URL {
        try await client.storage.from(bucket).upload(
            path: path,
            file: data,
            options: FileOptions(contentType: "image/jpeg")
        )
        let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
        return publicURL
    }
}
