import Foundation
#if os(iOS)
import UIKit

@Observable
final class AddItemViewModel {
    var capturedImage: UIImage?
    var classificationResult: ClothingClassification?
    var isClassifying: Bool = false
    var isSaving: Bool = false
    var selectedCategory: Category?
    var itemName: String = ""
    var brand: String = ""
    var color: String = "#000000"
    var season: String = "all"
    var styleTags: [String] = []
    var purchasePrice: String = ""
    var purchaseUrl: String = ""
    var purchaseDate: Date = Date()
    var editingItem: ClothingItem? = nil
    var errorMessage: String?

    private let localService = LocalDataService.shared

    let seasonOptions = ["spring", "summer", "autumn", "winter", "all"]
    let seasonLabels = ["春", "夏", "秋", "冬", "四季"]

    init() {}

    init(existingItem: ClothingItem) {
        self.editingItem = existingItem
        self.itemName = existingItem.name ?? ""
        self.brand = existingItem.brand ?? ""
        self.color = existingItem.color
        self.season = existingItem.season ?? "all"
        self.styleTags = existingItem.styleTags
        self.purchasePrice = existingItem.purchasePrice.map { String($0) } ?? ""
        self.purchaseDate = existingItem.purchaseDate ?? Date()
        self.purchaseUrl = existingItem.purchaseUrl ?? ""
        if let categoryId = existingItem.categoryId {
            let categories = LocalDataService.shared.fetchCategories()
            self.selectedCategory = categories.first { $0.id == categoryId }
        }
    }

    func classifyImage(_ image: UIImage) async {
        capturedImage = image

        // 未配置 API Key 时静默跳过，让用户手动填写
        guard AIService.shared.isConfigured else { return }

        isClassifying = true
        defer { isClassifying = false }

        do {
            let result = try await AIService.shared.classifyClothing(image)
            classificationResult = result
            color = result.color
            styleTags = result.style
            if itemName.isEmpty { itemName = result.category }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveItem() async {
        isSaving = true
        defer { isSaving = false }

        let userId = localService.currentUserId
        var localImageURL: URL? = nil

        if let image = capturedImage {
            let imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
            localImageURL = localService.saveImage(data: imageData)
        }

        if let existing = editingItem {
            let updated = ClothingItem(
                id: existing.id,
                userId: existing.userId,
                categoryId: selectedCategory?.id,
                name: itemName.isEmpty ? nil : itemName,
                imageUrl: localImageURL?.absoluteString ?? existing.imageUrl,
                brand: brand.isEmpty ? nil : brand,
                color: color,
                season: season,
                styleTags: styleTags,
                purchasePrice: Double(purchasePrice),
                purchaseDate: purchaseDate,
                purchaseUrl: purchaseUrl.isEmpty ? nil : purchaseUrl,
                wearCount: existing.wearCount,
                status: existing.status,
                createdAt: existing.createdAt
            )
            localService.updateClothingItem(updated)
        } else {
            guard capturedImage != nil else {
                errorMessage = "请先拍照或选择图片"
                return
            }
            let item = ClothingItem(
                id: UUID(),
                userId: userId,
                categoryId: selectedCategory?.id,
                name: itemName.isEmpty ? nil : itemName,
                imageUrl: localImageURL?.absoluteString,
                brand: brand.isEmpty ? nil : brand,
                color: color,
                season: season,
                styleTags: styleTags,
                purchasePrice: Double(purchasePrice),
                purchaseDate: purchaseDate,
                purchaseUrl: purchaseUrl.isEmpty ? nil : purchaseUrl,
                wearCount: 0,
                status: "active",
                createdAt: Date()
            )
            localService.addClothingItem(item)
        }

        NotificationCenter.default.post(name: NSNotification.Name("wardrobeDidChange"), object: nil)
        resetForm()
    }

    func resetForm() {
        capturedImage = nil
        classificationResult = nil
        editingItem = nil
        selectedCategory = nil
        itemName = ""
        brand = ""
        color = "#000000"
        season = "all"
        styleTags = []
        purchasePrice = ""
        purchaseUrl = ""
        purchaseDate = Date()
        errorMessage = nil
    }
}
#endif
