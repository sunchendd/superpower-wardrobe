import Foundation
import SwiftUI
import SwiftData

@Observable
final class WardrobeViewModel {
    var categories: [Category] = Category.defaultCategories
    var selectedCategory: Category?
    var searchText: String = ""

    // MARK: - Filtered Items

    func filteredItems(from all: [ClothingItem]) -> [ClothingItem] {
        var result = all
        if let category = selectedCategory {
            result = result.filter { ($0.categoryName ?? "") == category.name }
        }
        if !searchText.isEmpty {
            result = result.filter { item in
                (item.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                item.color.localizedCaseInsensitiveContains(searchText) ||
                item.styleTags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return result
    }

    // MARK: - Filter

    func filterByCategory(_ category: Category?) {
        selectedCategory = category
    }
}
