import Foundation
import SwiftUI

@Observable
final class WardrobeViewModel {
    var items: [ClothingItem] = []
    var categories: [Category] = []
    var selectedCategory: Category?
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var filterColors: [String] = []
    var filterSeasons: [String] = []
    var filterStyles: [String] = []

    private let service = LocalDataService.shared

    init() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("wardrobeDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.loadItems() }
        }
    }

    var filteredItems: [ClothingItem] {
        var result = items
        if let category = selectedCategory {
            result = result.filter { $0.categoryId == category.id }
        }
        if !searchText.isEmpty {
            result = result.filter { item in
                (item.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                item.color.localizedCaseInsensitiveContains(searchText) ||
                item.styleTags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        if !filterColors.isEmpty {
            result = result.filter { filterColors.contains($0.color) }
        }
        if !filterSeasons.isEmpty {
            result = result.filter { item in
                guard let season = item.season else { return false }
                return filterSeasons.contains(season)
            }
        }
        if !filterStyles.isEmpty {
            result = result.filter { item in
                filterStyles.contains(where: { item.styleTags.contains($0) })
            }
        }
        return result
    }

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        items = service.fetchClothingItems()
        categories = service.fetchCategories()
    }

    func addItem(_ item: ClothingItem) async {
        service.addClothingItem(item)
        items.insert(item, at: 0)
    }

    func updateItem(_ item: ClothingItem) {
        service.updateClothingItem(item)
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        }
    }

    func deleteItem(_ item: ClothingItem) async {
        service.deleteClothingItem(id: item.id)
        items.removeAll { $0.id == item.id }
    }

    func incrementWearCount(id: UUID) {
        service.incrementWearCount(id: id)
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].wearCount += 1
        }
    }

    func filterByCategory(_ category: Category?) {
        selectedCategory = category
    }

    func search() {
        // filtering is done reactively via filteredItems computed property
    }
}
