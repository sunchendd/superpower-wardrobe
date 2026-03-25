import Foundation
import SwiftData

struct CategoryStat: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let color: String
}

struct ColorStat: Identifiable {
    let id = UUID()
    let color: String
    let count: Int
}

struct UtilizationItem: Identifiable {
    let id: UUID
    let name: String
    let wearCount: Int
    let imageUrl: String?
    let imageData: Data? // for local items
}

@Observable
final class StatisticsViewModel {
    var totalItems: Int = 0
    var totalSpending: Double = 0
    var categoryDistribution: [CategoryStat] = []
    var colorDistribution: [ColorStat] = []
    var utilizationRanking: [UtilizationItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    private let chartColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"
    ]

    // MARK: - Remote (Supabase)

    func loadStatistics() async {
        guard let userId = await service.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let items = try await service.fetchClothingItems(userId: userId)
            let categories = try await service.fetchCategories()
            applyRemoteStats(items: items, categories: categories)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Local (SwiftData / guest mode)

    func loadLocalStatistics(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        let items = LocalDataService.shared.fetchClothingItems(context: context)
        applyLocalStats(items: items)
    }

    // MARK: - Private

    private func applyRemoteStats(items: [ClothingItem], categories: [Category]) {
        totalItems = items.count
        totalSpending = items.compactMap(\.purchasePrice).reduce(0, +)

        let categoryMap = Dictionary(grouping: items) { $0.categoryId }
        categoryDistribution = categories.enumerated().compactMap { index, cat in
            let count = categoryMap[cat.id]?.count ?? 0
            guard count > 0 else { return nil }
            return CategoryStat(
                name: cat.name,
                count: count,
                color: chartColors[index % chartColors.count]
            )
        }

        let colorMap = Dictionary(grouping: items) { $0.color }
        colorDistribution = colorMap.map { color, group in
            ColorStat(color: color, count: group.count)
        }.sorted { $0.count > $1.count }

        utilizationRanking = items
            .sorted { $0.wearCount > $1.wearCount }
            .prefix(20)
            .map {
                UtilizationItem(
                    id: $0.id,
                    name: $0.name ?? "未命名",
                    wearCount: $0.wearCount,
                    imageUrl: $0.imageUrl,
                    imageData: nil
                )
            }
    }

    private func applyLocalStats(items: [LocalClothingItem]) {
        totalItems = items.count
        totalSpending = items.compactMap(\.purchasePrice).reduce(0, +)

        let categoryMap = Dictionary(grouping: items) { $0.categoryName ?? "其他" }
        categoryDistribution = categoryMap.enumerated().map { index, pair in
            CategoryStat(
                name: pair.key,
                count: pair.value.count,
                color: chartColors[index % chartColors.count]
            )
        }.sorted { $0.count > $1.count }

        let colorMap = Dictionary(grouping: items) { $0.colorHex }
        colorDistribution = colorMap.map { color, group in
            ColorStat(color: color, count: group.count)
        }.sorted { $0.count > $1.count }

        utilizationRanking = items
            .sorted { $0.wearCount > $1.wearCount }
            .prefix(20)
            .map {
                UtilizationItem(
                    id: $0.id,
                    name: $0.name ?? $0.categoryName ?? "未命名",
                    wearCount: $0.wearCount,
                    imageUrl: nil,
                    imageData: $0.imageData
                )
            }
    }
}
