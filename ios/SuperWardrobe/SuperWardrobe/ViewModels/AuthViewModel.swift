import Foundation
import SwiftUI

@Observable
final class AuthViewModel {
    // MARK: - State

    var isAuthenticated: Bool = false
    var isGuestMode: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Form Fields

    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var isSignUpMode: Bool = false

    private let service = SupabaseService.shared
    private let guestKey = "wardrobe_guest_mode"

    // MARK: - Init

    init() {
        isGuestMode = UserDefaults.standard.bool(forKey: guestKey)
        if isGuestMode {
            isAuthenticated = true
        }
    }

    // MARK: - Auth Actions

    func checkAuthState() async {
        guard !isGuestMode else {
            isAuthenticated = true
            return
        }
        do {
            _ = try await service.client.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func signIn() async {
        guard validate() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.signIn(email: email, password: password)
            isAuthenticated = true
            errorMessage = nil
        } catch {
            errorMessage = "登录失败，请检查邮箱和密码"
        }
    }

    func signUp() async {
        guard validate() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.signUp(email: email, password: password)
            // Auto sign in after registration
            try await service.signIn(email: email, password: password)
            isAuthenticated = true
            errorMessage = nil
        } catch {
            errorMessage = "注册失败，该邮箱可能已被使用"
        }
    }

    func signOut() async {
        if isGuestMode {
            isGuestMode = false
            UserDefaults.standard.set(false, forKey: guestKey)
            isAuthenticated = false
            return
        }
        do {
            try await service.signOut()
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func continueAsGuest() {
        isGuestMode = true
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: guestKey)
    }

    func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = nil
        password = ""
        confirmPassword = ""
    }

    // MARK: - Private

    private func validate() -> Bool {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty || !trimmedEmail.contains("@") {
            errorMessage = "请输入有效的邮箱地址"
            return false
        }
        if password.count < 6 {
            errorMessage = "密码至少需要 6 位字符"
            return false
        }
        if isSignUpMode && password != confirmPassword {
            errorMessage = "两次输入的密码不一致"
            return false
        }
        return true
    }
}
