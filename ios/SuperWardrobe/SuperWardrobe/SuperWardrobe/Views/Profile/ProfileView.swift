import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var isSignedIn = UserDefaults.standard.bool(forKey: "apple_signed_in")
    @State private var appleName = UserDefaults.standard.string(forKey: "apple_display_name")
    @State private var appleEmail = UserDefaults.standard.string(forKey: "apple_email")

    private var displayName: String {
        appleName ?? viewModel.profile?.displayName ?? "未登录"
    }

    var body: some View {
        List {
            // MARK: - 个人信息头部
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(.indigo.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .overlay {
                            let initial = String((appleName ?? viewModel.profile?.displayName ?? "").prefix(1))
                            if initial.isEmpty {
                                Image(systemName: "person.fill")
                                    .font(.title2).foregroundStyle(.indigo)
                            } else {
                                Text(initial)
                                    .font(.title).fontWeight(.semibold).foregroundStyle(.indigo)
                            }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.title3).fontWeight(.semibold)
                        if let email = appleEmail {
                            Text(email)
                                .font(.caption).foregroundStyle(.secondary)
                        } else if let location = viewModel.profile?.location {
                            Label(location, systemImage: "location")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if isSignedIn {
                        Image(systemName: "applelogo")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                if !isSignedIn {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                    .cornerRadius(8)
                }
            }

            // MARK: - 穿搭记录
            Section("穿搭记录") {
                NavigationLink { OutfitCalendarView() } label: {
                    Label("穿搭日历", systemImage: "calendar")
                }
                NavigationLink { OutfitDiaryView() } label: {
                    Label("穿搭日记", systemImage: "book")
                }
            }

            Section("出行") {
                NavigationLink { TravelPlanView() } label: {
                    Label("旅行计划", systemImage: "airplane")
                }
            }

            // MARK: - 设置
            Section("设置") {
                NavigationLink { SettingsView() } label: {
                    Label("个人设置", systemImage: "gearshape")
                }
                if isSignedIn {
                    Button(role: .destructive) {
                        signOut()
                    } label: {
                        Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("我的")
        .task { await viewModel.loadProfile() }
    }

    // MARK: - Apple Sign In

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }

            // 姓名和邮箱只在首次登录时返回，需立即保存
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }.joined(separator: " ")
                if !name.isEmpty {
                    UserDefaults.standard.set(name, forKey: "apple_display_name")
                    appleName = name
                }
            }
            if let email = credential.email {
                UserDefaults.standard.set(email, forKey: "apple_email")
                appleEmail = email
            }
            UserDefaults.standard.set(true, forKey: "apple_signed_in")
            isSignedIn = true

            // 同步到 UserProfile
            Task {
                var profile = LocalDataService.shared.fetchUserProfile()
                    ?? UserProfile(id: LocalDataService.shared.currentUserId,
                                   displayName: nil, avatarUrl: nil,
                                   phone: nil, bodyInfo: nil,
                                   stylePreferences: nil, location: nil)
                if let name = appleName, profile.displayName == nil {
                    profile = UserProfile(id: profile.id,
                                          displayName: name,
                                          avatarUrl: profile.avatarUrl,
                                          phone: profile.phone,
                                          bodyInfo: profile.bodyInfo,
                                          stylePreferences: profile.stylePreferences,
                                          location: profile.location)
                    LocalDataService.shared.updateUserProfile(profile)
                }
                await viewModel.loadProfile()
            }

        case .failure:
            break
        }
    }

    private func signOut() {
        UserDefaults.standard.removeObject(forKey: "apple_signed_in")
        UserDefaults.standard.removeObject(forKey: "apple_display_name")
        UserDefaults.standard.removeObject(forKey: "apple_email")
        isSignedIn = false
        appleName = nil
        appleEmail = nil
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
