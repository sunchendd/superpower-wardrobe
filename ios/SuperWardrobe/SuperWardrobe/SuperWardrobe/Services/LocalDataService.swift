import Foundation

/// Local JSON-file based storage that replaces Supabase backend.
/// All data is persisted in the app's Documents directory.
final class LocalDataService {
    static let shared = LocalDataService()

    private let userIdKey = "local_device_user_id"

    // MARK: - Device User ID

    var currentUserId: UUID {
        if let stored = UserDefaults.standard.string(forKey: userIdKey),
           let id = UUID(uuidString: stored) {
            return id
        }
        let newId = UUID()
        UserDefaults.standard.set(newId.uuidString, forKey: userIdKey)
        return newId
    }

    // MARK: - Generic Persistence

    private func documentsURL(for filename: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }

    private func load<T: Codable>(_ filename: String) -> [T] {
        let url = documentsURL(for: filename)
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([T].self, from: data)) ?? []
    }

    private func save<T: Codable>(_ items: [T], filename: String) {
        let url = documentsURL(for: filename)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(items) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - Clothing Items

    func fetchClothingItems() -> [ClothingItem] {
        (load("clothing_items.json") as [ClothingItem])
            .filter { $0.status == "active" }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func addClothingItem(_ item: ClothingItem) {
        var items: [ClothingItem] = load("clothing_items.json")
        items.append(item)
        save(items, filename: "clothing_items.json")
    }

    func updateClothingItem(_ item: ClothingItem) {
        var items: [ClothingItem] = load("clothing_items.json")
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
        save(items, filename: "clothing_items.json")
    }

    func incrementWearCount(id: UUID) {
        var items: [ClothingItem] = load("clothing_items.json")
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].wearCount += 1
            save(items, filename: "clothing_items.json")
        }
    }

    func deleteClothingItem(id: UUID) {
        var items: [ClothingItem] = load("clothing_items.json")
        if let index = items.firstIndex(where: { $0.id == id }) {
            // Delete associated image file
            if let urlStr = items[index].imageUrl, let url = URL(string: urlStr), url.isFileURL {
                try? FileManager.default.removeItem(at: url)
            }
            items[index].status = "deleted"
        }
        save(items, filename: "clothing_items.json")
    }

    // MARK: - Categories

    func fetchCategories() -> [Category] {
        let stored: [Category] = load("categories.json")
        if stored.isEmpty {
            save(Category.defaultCategories, filename: "categories.json")
            return Category.defaultCategories
        }
        return stored.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Outfits

    func fetchOutfits() -> [Outfit] {
        (load("outfits.json") as [Outfit]).sorted { $0.createdAt > $1.createdAt }
    }

    func createOutfit(_ outfit: Outfit, items: [OutfitItem]) {
        var outfits: [Outfit] = load("outfits.json")
        outfits.append(outfit)
        save(outfits, filename: "outfits.json")

        if !items.isEmpty {
            var outfitItems: [OutfitItem] = load("outfit_items.json")
            outfitItems.append(contentsOf: items)
            save(outfitItems, filename: "outfit_items.json")
        }
    }

    // MARK: - Outfit Diary

    func fetchOutfitDiary(month: Date) -> [OutfitDiary] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        let startOfMonth = calendar.date(from: comps)!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return (load("outfit_diary.json") as [OutfitDiary])
            .filter { $0.date >= startOfMonth && $0.date < endOfMonth }
            .sorted { $0.date > $1.date }
    }

    func saveOutfitDiary(_ diary: OutfitDiary) {
        var entries: [OutfitDiary] = load("outfit_diary.json")
        if let index = entries.firstIndex(where: { $0.id == diary.id }) {
            entries[index] = diary
        } else {
            entries.append(diary)
        }
        save(entries, filename: "outfit_diary.json")
    }

    func deleteOutfitDiary(id: UUID) {
        var entries: [OutfitDiary] = load("outfit_diary.json")
        entries.removeAll { $0.id == id }
        save(entries, filename: "outfit_diary.json")
    }

    // MARK: - Daily Recommendations

    func fetchDailyRecommendations(date: Date) -> [DailyRecommendation] {
        let calendar = Calendar.current
        return (load("daily_recommendations.json") as [DailyRecommendation])
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func saveDailyRecommendation(_ rec: DailyRecommendation) {
        var recs: [DailyRecommendation] = load("daily_recommendations.json")
        if let index = recs.firstIndex(where: { $0.id == rec.id }) {
            recs[index] = rec
        } else {
            recs.append(rec)
        }
        save(recs, filename: "daily_recommendations.json")
    }

    // MARK: - Purchase Recommendations

    func fetchPurchaseRecommendations() -> [PurchaseRecommendation] {
        (load("purchase_recommendations.json") as [PurchaseRecommendation])
            .filter { $0.status == "active" }
            .sorted { $0.priority < $1.priority }
    }

    // MARK: - Travel Plans

    func fetchTravelPlans() -> [TravelPlan] {
        (load("travel_plans.json") as [TravelPlan]).sorted { $0.startDate < $1.startDate }
    }

    func createTravelPlan(_ plan: TravelPlan) {
        var plans: [TravelPlan] = load("travel_plans.json")
        plans.append(plan)
        save(plans, filename: "travel_plans.json")
    }

    func deleteTravelPlan(id: UUID) {
        var plans: [TravelPlan] = load("travel_plans.json")
        plans.removeAll { $0.id == id }
        save(plans, filename: "travel_plans.json")
    }

    // MARK: - User Profile

    func fetchUserProfile() -> UserProfile? {
        (load("user_profile.json") as [UserProfile]).first
    }

    func updateUserProfile(_ profile: UserProfile) {
        save([profile], filename: "user_profile.json")
    }

    // MARK: - Local Image Storage

    func saveImage(data: Data) -> URL? {
        let dir = imagesDirectory()
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = dir.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    private func imagesDirectory() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClothingImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
