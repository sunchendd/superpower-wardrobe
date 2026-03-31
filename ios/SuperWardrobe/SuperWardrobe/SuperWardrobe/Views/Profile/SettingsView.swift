import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var displayName = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var notificationsEnabled = true
    @State private var dailyReminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedStyles: Set<String> = []
    @State private var isSaving = false
    @State private var aiApiKey = ""
    @State private var showApiKey = false
    @State private var weatherApiKey = ""
    @State private var showWeatherKey = false

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
                            if isSelected { selectedStyles.remove(style) }
                            else { selectedStyles.insert(style) }
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

            Section {
                HStack {
                    Label("AI 识别", systemImage: "sparkles")
                        .foregroundStyle(aiApiKey.isEmpty ? Color.gray : Color.indigo)
                    Spacer()
                    Text(aiApiKey.isEmpty ? "未配置" : "已配置")
                        .font(.caption)
                        .foregroundStyle(aiApiKey.isEmpty ? Color.orange : Color.green)
                }

                HStack {
                    if showApiKey {
                        TextField("sk-...", text: $aiApiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("千问 API Key", text: $aiApiKey)
                    }
                    Button {
                        showApiKey.toggle()
                    } label: {
                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }

                Button("保存 API Key") {
                    AIService.shared.apiKey = aiApiKey
                }
                .disabled(aiApiKey.isEmpty)

                Link("获取千问 API Key →",
                     destination: URL(string: "https://dashscope.console.aliyun.com/apiKey")!)
                    .font(.caption)
                    .foregroundStyle(.indigo)
            } header: {
                Text("AI 配置")
            } footer: {
                Text("用于添加衣物时自动识别类别、颜色和风格标签。使用阿里云百炼（千问VL）模型，需申请 API Key。")
                    .font(.caption)
            }

            Section("天气配置") {
                HStack {
                    Image(systemName: "cloud.sun")
                        .foregroundColor(weatherApiKey.isEmpty ? Color.gray : Color.blue)
                    Text(weatherApiKey.isEmpty ? "未配置 OpenWeather Key" : "API Key 已配置")
                        .foregroundColor(weatherApiKey.isEmpty ? .secondary : .primary)
                    Spacer()
                }
                HStack {
                    if showWeatherKey {
                        TextField("OpenWeather API Key", text: $weatherApiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("OpenWeather API Key", text: $weatherApiKey)
                            .textInputAutocapitalization(.never)
                    }
                    Button(showWeatherKey ? "隐藏" : "显示") {
                        showWeatherKey.toggle()
                    }
                }
                Button("保存天气 Key") {
                    UserDefaults.standard.set(weatherApiKey, forKey: "weather_api_key")
                }
                .disabled(weatherApiKey.isEmpty)
                Link("获取 API Key（免费）", destination: URL(string: "https://openweathermap.org/api")!)
                    .font(.caption)
                    .foregroundColor(.blue)
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
                        if isSaving { ProgressView().padding(.trailing, 8) }
                        Text("保存设置").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("个人设置")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            aiApiKey = AIService.shared.apiKey
            weatherApiKey = UserDefaults.standard.string(forKey: "weather_api_key") ?? ""
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
        let userId = LocalDataService.shared.currentUserId
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

        // Schedule or cancel daily notification
        let reminderTime = dailyReminderTime
        let notificationsOn = notificationsEnabled
        if notificationsOn {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_outfit_reminder"])
                let content = UNMutableNotificationContent()
                content.title = "今日穿搭推荐"
                content.body = "来看看今天穿什么吧 ✨"
                content.sound = .default
                let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "daily_outfit_reminder", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_outfit_reminder"])
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
