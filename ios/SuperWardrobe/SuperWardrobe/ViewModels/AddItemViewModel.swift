import Foundation
import UIKit
import SwiftData

@Observable
final class AddItemViewModel {
    var capturedImage: UIImage?
    var processedImage: UIImage?
    var aiResult: AIClassificationResult?
    var isClassifying: Bool = false
    var isSaving: Bool = false
    var selectedCategory: Category?
    var itemName: String = ""
    var brand: String = ""
    var color: String = "#808080"
    var season: String = "all"
    var styleTags: [String] = []
    var purchasePrice: String = ""
    var errorMessage: String?

    /// Set to true after classification if the provider doesn't support vision
    var visionUnavailable: Bool = false

    private let aiService = AIService.shared

    let seasonOptions = ["spring", "summer", "autumn", "winter", "all"]
    let seasonLabels  = ["春", "夏", "秋", "冬", "四季"]

    // MARK: - Classification

    func classifyImage(_ image: UIImage) async {
        capturedImage = image
        visionUnavailable = false
        isClassifying = true
        defer { isClassifying = false }

        guard aiService.isConfigured else {
            // No AI configured — user fills in manually
            return
        }

        guard aiService.selectedProvider.supportsVision else {
            // Provider is text-only (e.g. DeepSeek)
            visionUnavailable = true
            return
        }

        do {
            let result = try await aiService.classifyClothing(image: image)
            aiResult = result
            color = result.colorHex
            styleTags = result.styleTags
            season = result.season
            itemName = result.description.isEmpty ? result.category : result.description
            // Match category name to default categories
            selectedCategory = Category.defaultCategories.first { $0.name == result.category }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save to SwiftData

    func saveItem(context: ModelContext) async {
        guard let image = processedImage ?? capturedImage else {
            errorMessage = "请先拍照或选择图片"
            return
        }

        isSaving = true
        defer { isSaving = false }

        let imageData = LocalDataService.compressImage(image)
        let local = LocalClothingItem(
            name: itemName.isEmpty ? nil : itemName,
            imageData: imageData,
            brand: brand.isEmpty ? nil : brand,
            colorHex: color,
            season: season,
            styleTags: styleTags,
            purchasePrice: Double(purchasePrice),
            purchaseDateRaw: Date(),
            categoryName: selectedCategory?.name,
            categoryIcon: selectedCategory?.icon
        )

        LocalDataService.shared.saveClothingItem(local, context: context)
        resetForm()
    }

    // MARK: - Reset

    func resetForm() {
        capturedImage = nil
        processedImage = nil
        aiResult = nil
        visionUnavailable = false
        selectedCategory = nil
        itemName = ""
        brand = ""
        color = "#808080"
        season = "all"
        styleTags = []
        purchasePrice = ""
        errorMessage = nil
    }
}
