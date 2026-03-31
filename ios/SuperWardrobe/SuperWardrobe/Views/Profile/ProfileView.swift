import SwiftUI

struct ProfileView: View {
    @Environment(\.themeTokens) private var theme
    private let auth = AppleAuthService.shared

    private var displayName: String {
        auth.storedUserName ?? (auth.isSignedIn ? "已登录用户" : "未登录")
    }

    private var avatarLetters: String {
        let name = auth.storedUserName ?? ""
        return String(name.prefix(1)).isEmpty ? "👤" : String(name.prefix(1))
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // ── 用户卡片 ──────────────────────────────
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.18))
                                .frame(width: 80, height: 80)
                            Text(avatarLetters)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(theme.accent)
                        }

                        VStack(spacing: 4) {
                            Text(displayName)
                                .font(.title3).fontWeight(.semibold)
                                .foregroundStyle(theme.text)
                            if let email = auth.storedUserEmail {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(theme.textMuted)
                            }
                            if auth.isSignedIn {
                                Label("Apple 账号已登录", systemImage: "apple.logo")
                                    .font(.caption)
                                    .foregroundStyle(theme.textSubtle)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.cardBorder, lineWidth: 1))

                    // ── 功能入口 ──────────────────────────────
                    VStack(spacing: 0) {
                        ProfileNavRow(icon: "calendar", label: "穿搭日历", color: theme.accent) {
                            OutfitCalendarView()
                        }
                        Divider().padding(.leading, 52)
                        ProfileNavRow(icon: "book.pages", label: "穿搭日记", color: Color(hex: "#7C3AED")) {
                            OutfitDiaryView()
                        }
                        Divider().padding(.leading, 52)
                        ProfileNavRow(icon: "gearshape", label: "设置", color: theme.textMuted) {
                            SettingsAppView()
                        }
                    }
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.cardBorder, lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileNavRow<Dest: View>: View {
    let icon: String
    let label: String
    let color: Color
    @ViewBuilder let destination: () -> Dest
    @Environment(\.themeTokens) private var theme

    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color)
                }
                Text(label)
                    .foregroundStyle(theme.text)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.textSubtle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
