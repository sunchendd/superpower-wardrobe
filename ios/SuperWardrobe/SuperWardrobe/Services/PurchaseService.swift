import StoreKit
import Foundation

/// Manages the $1 one-time purchase that unlocks the full app.
/// Uses StoreKit 2 (iOS 17+).
@Observable
final class PurchaseService {
    static let shared = PurchaseService()

    // MARK: - State

    var isPurchased: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var products: [Product] = []

    // MARK: - Config

    /// Must match your App Store Connect In-App Purchase product ID.
    static let productId = "com.superwardrobe.fullaccess"

    // MARK: - Init

    private init() {
        Task {
            await checkEntitlement()
            await loadProducts()
        }
        // Listen for transactions (e.g. purchases completed on another device)
        startTransactionListener()
    }

    // MARK: - Public API

    /// Attempt to purchase the unlock product.
    func purchase() async {
        guard let product = products.first else {
            errorMessage = "商品加载中，请稍后重试"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                await handleVerification(verificationResult)
            case .userCancelled:
                break
            case .pending:
                errorMessage = "购买待处理，完成后将自动解锁"
            @unknown default:
                break
            }
        } catch {
            errorMessage = "购买失败：\(error.localizedDescription)"
        }
    }

    /// Restore purchases (required by App Store guidelines).
    func restore() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await checkEntitlement()
            if !isPurchased {
                errorMessage = "未找到有效购买记录"
            }
        } catch {
            errorMessage = "恢复失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func loadProducts() async {
        do {
            products = try await Product.products(for: [PurchaseService.productId])
        } catch {
            errorMessage = "商品加载失败"
        }
    }

    private func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == PurchaseService.productId,
               transaction.revocationDate == nil {
                isPurchased = true
                return
            }
        }
        isPurchased = false
    }

    private func handleVerification(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            isPurchased = true
            await transaction.finish()
        case .unverified:
            errorMessage = "购买验证失败，请联系支持"
        }
    }

    private func startTransactionListener() {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID == PurchaseService.productId,
                       transaction.revocationDate == nil {
                        self?.isPurchased = true
                        await transaction.finish()
                    }
                }
            }
        }
    }
}
