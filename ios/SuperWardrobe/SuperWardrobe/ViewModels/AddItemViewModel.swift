import Foundation
import UIKit
import SwiftData

@Observable
final class AddItemViewModel {
    var capturedImage: UIImage?
    var processedImage: UIImage?
    var classificationResult: ClassificationResult?
    var isClassifying: Bool = false
    var isRemovingBackground: Bool = false
    var isSaving: Bool = false
    var selectedCategory: Category?
    var itemName: String = ""
    var brand: String = ""
    var color: String = "#808080"
    var season: String = "all"
    var styleTags: [String] = []
    var purchasePrice: String = ""
    var purchaseUrl: String = ""
    var errorMessage: String?

    private let fashionCLIPService = FashionCLIPService.shared
    private let supabaseService = SupabaseService.shared

    let seasonOptions = ["spring", "summer", "autumn", "winter", "all"]
    let seasonLabels  = ["春", "夏", "秋", "冬", "四季"]

    // MARK: - Classification

    func classifyImage(_ image: UIImage) async {
        capturedImage = image
        isClassifying = true
        defer { isClassifying = false }

        do {
            let result = try await fashionCLIPService.classifyImage(image)
            classificationResult = result
            color = result.color
            styleTags = result.style
            itemName = result.category
        } catch {
            // Classification failure is non-fatal — user can fill in manually
            errorMessage = nil
        }
    }

    func removeBackground(_ image: UIImage) async {
        isRemovingBackground = true
        defer { isRemovingBackground = false }

        do {
            processedImage = try await fashionCLIPService.removeBackground(image)
        } catch {
            errorMessage = "去除背景失败，将使用原图"
        }
    }

    // MARK: - Save (Supabase)

    func saveItem() async {
        guard let image = processedImage ?? capturedImage else {
            errorMessage = "请先拍照或选择图片"
            return
        }

        isSaving = true
        defer { isSaving = false }

        if let userId = await supabaseService.currentUserId {
            await saveToSupabase(image: image, userId: userId)
        } else {
            errorMessage = "请先登录后再保存到云端"
        }
    }

    /// Save item to local SwiftData store (guest / offline mode).
    func saveItemLocally(context: ModelContext) async {
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
            purchaseUrl: purchaseUrl.isEmpty ? nil : purchaseUrl,
            wearCount: 0,
            categoryName: selectedCategory?.name,
            categoryIcon: selectedCategory?.icon
        )

        LocalDataService.shared.saveClothingItem(local, context: context)
        resetForm()
    }

    // MARK: - Private

    private func saveToSupabase(image: UIImage, userId: UUID) async {
        do {
            let imageData = image.jpegData(compressionQuality: 0.8)!
            let path = "clothing/\(userId.uuidString)/\(UUID().uuidString).jpg"
            let imageURL = try await supabaseService.uploadImage(
                data: imageData,
                bucket: "clothing-images",
                path: path
            )

            let item = ClothingItem(
                id: UUID(),
                userId: userId,
                categoryId: selectedCategory?.id,
                name: itemName.isEmpty ? nil : itemName,
                imageUrl: imageURL.absoluteString,
                brand: brand.isEmpty ? nil : brand,
                color: color,
                season: season,
                styleTags: styleTags,
                purchasePrice: Double(purchasePrice),
                purchaseDate: Date(),
                purchaseUrl: purchaseUrl.isEmpty ? nil : purchaseUrl,
                wearCount: 0,
                status: "active",
                createdAt: Date()
            )

            try await supabaseService.addClothingItem(item)
            resetForm()
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Reset

    func resetForm() {
        capturedImage = nil
        processedImage = nil
        classificationResult = nil
        selectedCategory = nil
        itemName = ""
        brand = ""
        color = "#808080"
        season = "all"
        styleTags = []
        purchasePrice = ""
        purchaseUrl = ""
        errorMessage = nil
    }
}
