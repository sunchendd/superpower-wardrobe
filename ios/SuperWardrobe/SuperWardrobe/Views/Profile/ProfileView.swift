import SwiftUI
import Kingfisher

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var showSignOutAlert = false

    private var isGuest: Bool { authViewModel.isGuestMode }

    var body: some View {
        List {
            // MARK: - Profile Header
            Section {
                HStack(spacing: 16) {
                    avatarView

                    VStack(alignment: .leading, spacing: 4) {
                        if isGuest {
                            Text("游客")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("注册账号以同步数据到云端")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(viewModel.profile?.displayName ?? "未设置昵称")
                                .font(.title3)
                                .fontWeight(.semibold)
                            if let location = viewModel.profile?.location {
                                Label(location, systemImage: "location")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    if isGuest {
                        Button("注册") {
                            Task { await authViewModel.signOut() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Records
            Section("穿搭记录") {
                NavigationLink {
                    OutfitCalendarView()
                } label: {
                    Label("穿搭日历", systemImage: "calendar")
                }

                NavigationLink {
                    OutfitDiaryView()
                } label: {
                    Label("穿搭日记", systemImage: "book")
                }
            }

            // MARK: - Travel
            Section("出行") {
                NavigationLink {
                    TravelPlanView()
                } label: {
                    Label("旅行计划", systemImage: "airplane")
                }
            }

            // MARK: - Settings & Sign Out
            Section("设置") {
                if !isGuest {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("个人设置", systemImage: "gearshape")
                    }
                }

                Button(role: .destructive) {
                    showSignOutAlert = true
                } label: {
                    Label(isGuest ? "退出游客模式" : "退出登录",
                          systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("我的")
        .task {
            if !isGuest {
                await viewModel.loadProfile()
            }
        }
        .alert(isGuest ? "退出游客模式" : "退出登录", isPresented: $showSignOutAlert) {
            Button("确认", role: .destructive) {
                Task { await authViewModel.signOut() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(isGuest
                 ? "退出后本设备数据仍会保留，下次仍可使用游客模式访问。"
                 : "确认退出登录吗？")
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = viewModel.profile?.avatarUrl, let url = URL(string: avatarUrl) {
            KFImage(url)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(isGuest ? Color.orange.opacity(0.2) : Color.indigo.opacity(0.2))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: isGuest ? "person.crop.circle.badge.questionmark" : "person.fill")
                        .font(.title2)
                        .foregroundStyle(isGuest ? .orange : .indigo)
                }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthViewModel())
}
