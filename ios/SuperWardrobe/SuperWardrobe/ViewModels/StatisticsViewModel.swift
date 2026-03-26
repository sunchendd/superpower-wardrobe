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
    let imageData: Data?
}

@Observable
final class StatisticsViewModel {
    var totalItems: Int = 0
    var totalSpending: Double = 0
    var categoryDistribution: [CategoryStat] = []
    var colorDistribution: [ColorStat] = []
    var utilizationRanking: [UtilizationItem] = []
    var isLoading: Bool = false

    private let chartColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"
    ]

    func loadStatistics(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        let items = LocalDataService.shared.fetchClothingItems(context: context)

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

        let colorMap = Dictionary(grouping: items) { $0.color }
        colorDistribution = colorMap.map { color, group in
            ColorStat(color: color, count: group.count)
        }.sorted { $0.count > $1.count }

        utilizationRanking = items
            .sorted { $0.wearCount > $1.wearCount }
            .prefix(20)
            .map { UtilizationItem(id: $0.id, name: $0.name ?? $0.categoryName ?? "未命名", wearCount: $0.wearCount, imageData: $0.imageData) }
    }
}
