import Foundation
import UIKit

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
    var color: String = "#000000"
    var season: String = "all"
    var styleTags: [String] = []
    var purchasePrice: String = ""
    var purchaseUrl: String = ""
    var errorMessage: String?

    private let fashionCLIPService = FashionCLIPService.shared
    private let supabaseService = SupabaseService.shared

    let seasonOptions = ["spring", "summer", "autumn", "winter", "all"]
    let seasonLabels = ["春", "夏", "秋", "冬", "四季"]

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
            errorMessage = error.localizedDescription
        }
    }

    func removeBackground(_ image: UIImage) async {
        isRemovingBackground = true
        defer { isRemovingBackground = false }

        do {
            processedImage = try await fashionCLIPService.removeBackground(image)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveItem() async {
        guard let userId = await supabaseService.currentUserId else {
            errorMessage = "请先登录"
            return
        }
        guard let image = processedImage ?? capturedImage else {
            errorMessage = "请先拍照或选择图片"
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let imageData = image.jpegData(compressionQuality: 0.8)!
            let path = "clothing/\(userId.uuidString)/\(UUID().uuidString).jpg"
            let imageURL = try await supabaseService.uploadImage(data: imageData, bucket: "clothing-images", path: path)

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
            errorMessage = error.localizedDescription
        }
    }

    func resetForm() {
        capturedImage = nil
        processedImage = nil
        classificationResult = nil
        selectedCategory = nil
        itemName = ""
        brand = ""
        color = "#000000"
        season = "all"
        styleTags = []
        purchasePrice = ""
        purchaseUrl = ""
        errorMessage = nil
    }
}
