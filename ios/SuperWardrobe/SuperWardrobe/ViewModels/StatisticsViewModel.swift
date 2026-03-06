import Foundation

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

    func loadStatistics() async {
        guard let userId = await service.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let items = try await service.fetchClothingItems(userId: userId)
            let categories = try await service.fetchCategories()

            totalItems = items.count
            totalSpending = items.compactMap(\.purchasePrice).reduce(0, +)

            let categoryMap = Dictionary(grouping: items) { $0.categoryId }
            let chartColors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"]
            categoryDistribution = categories.enumerated().map { index, cat in
                CategoryStat(
                    name: cat.name,
                    count: categoryMap[cat.id]?.count ?? 0,
                    color: chartColors[index % chartColors.count]
                )
            }.filter { $0.count > 0 }

            let colorMap = Dictionary(grouping: items) { $0.color }
            colorDistribution = colorMap.map { color, group in
                ColorStat(color: color, count: group.count)
            }.sorted { $0.count > $1.count }

            utilizationRanking = items
                .sorted { $0.wearCount > $1.wearCount }
                .prefix(20)
                .map { UtilizationItem(id: $0.id, name: $0.name ?? "未命名", wearCount: $0.wearCount, imageUrl: $0.imageUrl) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
