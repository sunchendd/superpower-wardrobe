import Foundation
import SwiftData
import UIKit

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

// MARK: - Image Storage

enum ImageStorage {
    static func compressedJPEGData(
        from image: UIImage,
        maxDimension: CGFloat = 1024,
        quality: CGFloat = 0.8
    ) -> Data? {
        let size = scaledSize(for: image.size, maxDimension: maxDimension)
        guard size != .zero else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    static func thumbnail(
        from image: UIImage,
        maxDimension: CGFloat = 256
    ) -> UIImage? {
        let size = scaledSize(for: image.size, maxDimension: maxDimension)
        guard size != .zero else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    static func thumbnail(
        from data: Data,
        maxDimension: CGFloat = 256
    ) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return thumbnail(from: image, maxDimension: maxDimension)
    }

    private static func scaledSize(for size: CGSize, maxDimension: CGFloat) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        return CGSize(width: size.width * ratio, height: size.height * ratio)
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

    func saveClothingItem(_ item: ClothingItem, context: ModelContext) {
        context.insert(item)
        try? context.save()
    }

    func deleteClothingItem(_ item: ClothingItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
    }

    func incrementWearCount(for item: ClothingItem, context: ModelContext) {
        item.wearCount += 1
        try? context.save()
    }

    func fetchClothingItems(context: ModelContext) -> [ClothingItem] {
        let descriptor = FetchDescriptor<ClothingItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchClothingItems(for category: String?, context: ModelContext) -> [ClothingItem] {
        var descriptor = FetchDescriptor<ClothingItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let cat = category {
            descriptor.predicate = #Predicate { $0.categoryName == cat }
        }
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Outfit Diary

    func saveDiaryEntry(_ entry: OutfitDiary, context: ModelContext) {
        context.insert(entry)
        try? context.save()
    }

    func deleteDiaryEntry(_ entry: OutfitDiary, context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }

    func fetchDiaryEntries(for month: Date, context: ModelContext) -> [OutfitDiary] {
        let calendar = Calendar.current
        guard
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
            let end = calendar.date(byAdding: .month, value: 1, to: start)
        else { return [] }

        let descriptor = FetchDescriptor<OutfitDiary>(
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
        ImageStorage.compressedJPEGData(from: image, maxDimension: maxDimension, quality: quality)
    }
}
