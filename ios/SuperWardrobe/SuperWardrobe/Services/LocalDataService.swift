import Foundation
import SwiftData
import UIKit

// MARK: - SwiftData Models

@Model
final class LocalClothingItem {
    @Attribute(.unique) var id: UUID
    var name: String?
    var imageData: Data?
    var brand: String?
    var colorHex: String
    var season: String
    var styleTags: [String]
    var purchasePrice: Double?
    var purchaseDateRaw: Date?
    var purchaseUrl: String?
    var wearCount: Int
    var categoryName: String?
    var categoryIcon: String?
    var createdAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String? = nil,
        imageData: Data? = nil,
        brand: String? = nil,
        colorHex: String = "#808080",
        season: String = "all",
        styleTags: [String] = [],
        purchasePrice: Double? = nil,
        purchaseDateRaw: Date? = nil,
        purchaseUrl: String? = nil,
        wearCount: Int = 0,
        categoryName: String? = nil,
        categoryIcon: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.brand = brand
        self.colorHex = colorHex
        self.season = season
        self.styleTags = styleTags
        self.purchasePrice = purchasePrice
        self.purchaseDateRaw = purchaseDateRaw
        self.purchaseUrl = purchaseUrl
        self.wearCount = wearCount
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.notes = notes
        self.createdAt = createdAt
    }

    /// Convenience thumbnail image
    var thumbnail: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }

    /// Create a display-ready ClothingItem from this local record
    func toClothingItem() -> ClothingItem {
        ClothingItem(
            id: id,
            userId: UUID(), // local guest user
            categoryId: nil,
            name: name,
            imageUrl: nil,
            brand: brand,
            color: colorHex,
            season: season,
            styleTags: styleTags,
            purchasePrice: purchasePrice,
            purchaseDate: purchaseDateRaw,
            purchaseUrl: purchaseUrl,
            wearCount: wearCount,
            status: "active",
            createdAt: createdAt
        )
    }
}

@Model
final class LocalOutfitDiary {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mood: String?
    var notes: String?
    var photoData: Data?
    var weatherDescription: String?
    var temperature: Double?
    var itemIds: [UUID]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        mood: String? = nil,
        notes: String? = nil,
        photoData: Data? = nil,
        weatherDescription: String? = nil,
        temperature: Double? = nil,
        itemIds: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.notes = notes
        self.photoData = photoData
        self.weatherDescription = weatherDescription
        self.temperature = temperature
        self.itemIds = itemIds
        self.createdAt = createdAt
    }
}

@Model
final class LocalTravelPlan {
    @Attribute(.unique) var id: UUID
    var destination: String
    var startDate: Date
    var endDate: Date
    var notes: String?
    var packedItemIds: [UUID]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        destination: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        packedItemIds: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.packedItemIds = packedItemIds
        self.createdAt = createdAt
    }

    var dayCount: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day.map { $0 + 1 } ?? 1
    }

    var dateRangeText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        return "\(fmt.string(from: startDate)) - \(fmt.string(from: endDate))"
    }
}

// MARK: - Service

/// Manages all local-first data operations using SwiftData.
/// Used in guest mode or as a cache layer when Supabase is unavailable.
@Observable
final class LocalDataService {
    static let shared = LocalDataService()
    private init() {}

    // MARK: - Clothing Items

    func saveClothingItem(_ item: LocalClothingItem, context: ModelContext) {
        context.insert(item)
        try? context.save()
    }

    func deleteClothingItem(_ item: LocalClothingItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
    }

    func incrementWearCount(for item: LocalClothingItem, context: ModelContext) {
        item.wearCount += 1
        try? context.save()
    }

    func fetchClothingItems(context: ModelContext) -> [LocalClothingItem] {
        let descriptor = FetchDescriptor<LocalClothingItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchClothingItems(for category: String?, context: ModelContext) -> [LocalClothingItem] {
        var descriptor = FetchDescriptor<LocalClothingItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let cat = category {
            descriptor.predicate = #Predicate { $0.categoryName == cat }
        }
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Outfit Diary

    func saveDiaryEntry(_ entry: LocalOutfitDiary, context: ModelContext) {
        context.insert(entry)
        try? context.save()
    }

    func deleteDiaryEntry(_ entry: LocalOutfitDiary, context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }

    func fetchDiaryEntries(for month: Date, context: ModelContext) -> [LocalOutfitDiary] {
        let calendar = Calendar.current
        guard
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
            let end = calendar.date(byAdding: .month, value: 1, to: start)
        else { return [] }

        let descriptor = FetchDescriptor<LocalOutfitDiary>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Travel Plans

    func saveTravelPlan(_ plan: LocalTravelPlan, context: ModelContext) {
        context.insert(plan)
        try? context.save()
    }

    func deleteTravelPlan(_ plan: LocalTravelPlan, context: ModelContext) {
        context.delete(plan)
        try? context.save()
    }

    func fetchTravelPlans(context: ModelContext) -> [LocalTravelPlan] {
        let descriptor = FetchDescriptor<LocalTravelPlan>(
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Image Helpers

    static func compressImage(_ image: UIImage, maxDimension: CGFloat = 1024, quality: CGFloat = 0.8) -> Data? {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
