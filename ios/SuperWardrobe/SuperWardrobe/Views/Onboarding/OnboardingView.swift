import AuthenticationServices
import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    private let bgColor = Color(hex: "#020203")
    private let accentColor = Color(hex: "#BE185D")
    private let textColor = Color(hex: "#EDEDEF")
    private let mutedColor = Color(hex: "#8A8F98")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 72)

                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 132, height: 132)

                    Image(systemName: "hanger")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(accentColor)
                }

                VStack(spacing: 18) {
                    Text("超能力衣橱")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(textColor)

                    Text("每天 30 秒，告别穿搭纠结\n为效率而生的智能衣橱")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(mutedColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.top, 42)

                Spacer()

                VStack(spacing: 20) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        if case let .success(authResults) = result,
                           let credential = authResults.credential as? ASAuthorizationAppleIDCredential {
                            AppleAuthService.shared.storeSignedInUserIdentifier(credential.user)
                            if let fullName = credential.fullName {
                                let name = [fullName.familyName, fullName.givenName]
                                    .compactMap { $0 }.joined(separator: " ")
                                if !name.isEmpty { AppleAuthService.shared.storedUserName = name }
                            }
                            if let email = credential.email {
                                AppleAuthService.shared.storedUserEmail = email
                            }
                        }
                        onFinish()
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button("稍后再说") {
                        onFinish()
                    }
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(mutedColor)
                }
                .padding(.horizontal, 28)

                HStack(spacing: 8) {
                    Capsule()
                        .fill(accentColor)
                        .frame(width: 26, height: 8)
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 8, height: 8)
                }
                .padding(.top, 52)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    OnboardingView {}
}
