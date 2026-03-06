import SwiftUI
import Kingfisher

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    if let avatarUrl = viewModel.profile?.avatarUrl, let url = URL(string: avatarUrl) {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(.indigo.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.profile?.displayName ?? "未设置昵称")
                            .font(.title3)
                            .fontWeight(.semibold)
                        if let location = viewModel.profile?.location {
                            Label(location, systemImage: "location")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }

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

            Section("出行") {
                NavigationLink {
                    TravelPlanView()
                } label: {
                    Label("旅行计划", systemImage: "airplane")
                }
            }

            Section("设置") {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("个人设置", systemImage: "gearshape")
                }

                Button(role: .destructive) {
                    Task {
                        try? await SupabaseService.shared.signOut()
                    }
                } label: {
                    Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("我的")
        .task {
            await viewModel.loadProfile()
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
