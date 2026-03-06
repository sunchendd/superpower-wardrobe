import SwiftUI

struct SettingsView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var displayName = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var notificationsEnabled = true
    @State private var dailyReminderTime = Date()
    @State private var selectedStyles: Set<String> = []
    @State private var isSaving = false

    private let styleOptions = ["休闲", "正式", "运动", "街头", "复古", "简约", "甜美", "中性", "商务", "波西米亚"]

    var body: some View {
        Form {
            Section("个人信息") {
                TextField("昵称", text: $displayName)
                TextField("手机号", text: $phone)
                    .keyboardType(.phonePad)
                TextField("所在城市", text: $location)
            }

            Section("身体信息") {
                HStack {
                    TextField("身高 (cm)", text: $height)
                        .keyboardType(.decimalPad)
                    Divider()
                    TextField("体重 (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }
            }

            Section("风格偏好") {
                FlowLayout(spacing: 8) {
                    ForEach(styleOptions, id: \.self) { style in
                        let isSelected = selectedStyles.contains(style)
                        Button {
                            if isSelected {
                                selectedStyles.remove(style)
                            } else {
                                selectedStyles.insert(style)
                            }
                        } label: {
                            Text(style)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.indigo : Color.gray.opacity(0.12))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Section("通知") {
                Toggle("每日穿搭提醒", isOn: $notificationsEnabled)
                if notificationsEnabled {
                    DatePicker("提醒时间", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                }
            }

            Section {
                Button {
                    Task { await saveProfile() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("保存设置")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("个人设置")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
            if let profile = viewModel.profile {
                displayName = profile.displayName ?? ""
                phone = profile.phone ?? ""
                location = profile.location ?? ""
                selectedStyles = Set(profile.stylePreferences ?? [])

                if let bodyInfo = profile.bodyInfo,
                   let data = bodyInfo.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    height = json["height"] as? String ?? ""
                    weight = json["weight"] as? String ?? ""
                }
            }
        }
    }

    private func saveProfile() async {
        guard let userId = await SupabaseService.shared.currentUserId else { return }
        isSaving = true
        defer { isSaving = false }

        let bodyInfoDict: [String: String] = ["height": height, "weight": weight]
        let bodyInfoData = try? JSONSerialization.data(withJSONObject: bodyInfoDict)
        let bodyInfoString = bodyInfoData.flatMap { String(data: $0, encoding: .utf8) }

        let profile = UserProfile(
            id: userId,
            displayName: displayName.isEmpty ? nil : displayName,
            avatarUrl: viewModel.profile?.avatarUrl,
            phone: phone.isEmpty ? nil : phone,
            bodyInfo: bodyInfoString,
            stylePreferences: Array(selectedStyles),
            location: location.isEmpty ? nil : location
        )

        await viewModel.updateProfile(profile)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
