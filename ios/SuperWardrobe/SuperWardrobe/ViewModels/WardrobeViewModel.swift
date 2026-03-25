import Foundation
import SwiftUI
import SwiftData

@Observable
final class WardrobeViewModel {
    var items: [ClothingItem] = []
    var localItems: [LocalClothingItem] = []
    var categories: [Category] = []
    var selectedCategory: Category?
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var isGuestMode: Bool = false

    private let service = SupabaseService.shared

    // MARK: - Filtered Items (remote)

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

    // MARK: - Filtered Local Items (guest/offline)

    func filteredLocalItems(all: [LocalClothingItem]) -> [LocalClothingItem] {
        var result = all
        if let category = selectedCategory {
            result = result.filter { $0.categoryName == category.name }
        }
        if !searchText.isEmpty {
            result = result.filter { item in
                (item.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                item.colorHex.localizedCaseInsensitiveContains(searchText) ||
                item.styleTags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return result
    }

    // MARK: - Load

    func loadItems(isGuest: Bool = false, context: ModelContext? = nil) async {
        isGuestMode = isGuest
        isLoading = true
        defer { isLoading = false }

        // Always load default categories
        categories = Category.defaultCategories

        if isGuest {
            // Local items are driven by @Query in the view; just load categories
            if let ctx = context {
                localItems = LocalDataService.shared.fetchClothingItems(context: ctx)
            }
            return
        }

        guard let userId = await service.currentUserId else {
            isGuestMode = true
            return
        }

        do {
            async let itemsTask = service.fetchClothingItems(userId: userId)
            async let categoriesTask = service.fetchCategories()
            let (fetched, cats) = try await (itemsTask, categoriesTask)
            items = fetched
            categories = cats.isEmpty ? Category.defaultCategories : cats
        } catch {
            errorMessage = "加载失败，显示本地数据"
            if let ctx = context {
                localItems = LocalDataService.shared.fetchClothingItems(context: ctx)
            }
        }
    }

    // MARK: - CRUD (remote)

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

    // MARK: - Filter / Search

    func filterByCategory(_ category: Category?) {
        selectedCategory = category
    }
}
