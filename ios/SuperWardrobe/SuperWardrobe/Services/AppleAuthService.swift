import AuthenticationServices
import Foundation
import Observation

enum AppleAuthStatus: String, Codable, Sendable {
    case signedOut
    case signedIn
    case revoked
    case notFound
    case transferred
    case unknown
}

enum AppleAuthServiceError: LocalizedError {
    case missingUserIdentifier
    case credentialStateUnavailable

    var errorDescription: String? {
        switch self {
        case .missingUserIdentifier:
            return "Missing Apple user identifier"
        case .credentialStateUnavailable:
            return "Unable to check Apple credential state"
        }
    }
}

@Observable
final class AppleAuthService {
    static let shared = AppleAuthService()

    private let provider = ASAuthorizationAppleIDProvider()
    private let storedUserIdentifierKey = "apple_user_identifier"

    private init() {}

    var storedUserIdentifier: String? {
        get { UserDefaults.standard.string(forKey: storedUserIdentifierKey) }
        set { UserDefaults.standard.set(newValue, forKey: storedUserIdentifierKey) }
    }

    var storedUserName: String? {
        get { UserDefaults.standard.string(forKey: "apple_user_name") }
        set { UserDefaults.standard.set(newValue, forKey: "apple_user_name") }
    }

    var storedUserEmail: String? {
        get { UserDefaults.standard.string(forKey: "apple_user_email") }
        set { UserDefaults.standard.set(newValue, forKey: "apple_user_email") }
    }

    var isSignedIn: Bool {
        storedUserIdentifier?.isEmpty == false
    }

    var signInStatus: AppleAuthStatus {
        isSignedIn ? .signedIn : .signedOut
    }

    func storeSignedInUserIdentifier(_ userIdentifier: String) {
        storedUserIdentifier = userIdentifier
    }

    func clearSignedInUserIdentifier() {
        UserDefaults.standard.removeObject(forKey: storedUserIdentifierKey)
    }

    func credentialState(for userIdentifier: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        try await withCheckedThrowingContinuation { continuation in
            provider.getCredentialState(forUserID: userIdentifier) { state, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: state)
            }
        }
    }

    func refreshSignInStatus() async -> AppleAuthStatus {
        guard let userIdentifier = storedUserIdentifier, !userIdentifier.isEmpty else {
            return .signedOut
        }

        do {
            let state = try await credentialState(for: userIdentifier)
            switch state {
            case .authorized:
                return .signedIn
            case .revoked:
                clearSignedInUserIdentifier()
                return .revoked
            case .notFound:
                clearSignedInUserIdentifier()
                return .notFound
            case .transferred:
                clearSignedInUserIdentifier()
                return .transferred
            @unknown default:
                return .unknown
            }
        } catch {
            return .unknown
        }
    }
}
