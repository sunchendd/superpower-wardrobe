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

    private let service = SupabaseService.shared

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
        return result
    }

    func loadItems() async {
        guard let userId = await service.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let itemsTask = service.fetchClothingItems(userId: userId)
            async let categoriesTask = service.fetchCategories()
            let (fetchedItems, fetchedCategories) = try await (itemsTask, categoriesTask)
            items = fetchedItems
            categories = fetchedCategories
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addItem(_ item: ClothingItem) async {
        do {
            try await service.addClothingItem(item)
            items.insert(item, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: ClothingItem) async {
        do {
            try await service.deleteClothingItem(id: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func filterByCategory(_ category: Category?) {
        selectedCategory = category
    }

    func search() {
        // filtering is done reactively via filteredItems computed property
    }
}
