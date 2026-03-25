import SwiftUI

struct AISettingsView: View {
    @State private var aiService = AIService.shared
    @State private var draftKey = ""
    @State private var showKey = false
    @State private var isTesting = false
    @State private var testResult: Bool? = nil

    var body: some View {
        Form {
            // MARK: - Provider Picker
            Section("选择 AI 服务商") {
                ForEach(AIProvider.allCases) { provider in
                    providerRow(provider)
                }
            }

            // MARK: - Selected Provider Info
            Section {
                providerInfoCard
            }

            // MARK: - API Key Input
            Section("API Key") {
                HStack {
                    if showKey {
                        TextField(aiService.selectedProvider.keyPlaceholder, text: $draftKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField(aiService.selectedProvider.keyPlaceholder, text: $draftKey)
                    }
                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }

                Button("保存 API Key") {
                    aiService.apiKey = draftKey.trimmingCharacters(in: .whitespaces)
                    testResult = nil
                }
                .disabled(draftKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // MARK: - Status + Test
            Section("连接状态") {
                HStack {
                    Label(
                        aiService.isConfigured ? "已配置" : "未配置",
                        systemImage: aiService.isConfigured ? "checkmark.circle.fill" : "xmark.circle"
                    )
                    .foregroundStyle(aiService.isConfigured ? .green : .secondary)

                    Spacer()

                    if let ok = testResult {
                        Label(ok ? "连接成功" : "连接失败",
                              systemImage: ok ? "wifi" : "wifi.slash")
                        .font(.caption)
                        .foregroundStyle(ok ? .green : .red)
                    }
                }

                Button {
                    Task {
                        isTesting = true
                        testResult = await aiService.testConnection()
                        isTesting = false
                    }
                } label: {
                    HStack {
                        if isTesting { ProgressView().scaleEffect(0.8) }
                        else { Image(systemName: "antenna.radiowaves.left.and.right") }
                        Text(isTesting ? "测试中..." : "测试连接")
                    }
                }
                .disabled(!aiService.isConfigured || isTesting)
            }

            // MARK: - Privacy
            Section {
                Label("API Key 仅保存在本机，不会上传到任何服务器", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI 功能配置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { draftKey = aiService.apiKey }
        .onChange(of: aiService.selectedProvider) { _, _ in
            testResult = nil
            draftKey = aiService.apiKey
        }
    }

    // MARK: - Provider Row

    private func providerRow(_ provider: AIProvider) -> some View {
        Button {
            aiService.selectedProvider = provider
        } label: {
            HStack(spacing: 12) {
                // Vision badge
                VStack {
                    Image(systemName: provider.supportsVision ? "camera.viewfinder" : "text.bubble")
                        .font(.title2)
                        .foregroundStyle(provider.supportsVision ? .indigo : .orange)
                }
                .frame(width: 40)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(provider.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if provider.supportsVision {
                            Text("识图")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.indigo.opacity(0.15))
                                .foregroundStyle(.indigo)
                                .clipShape(Capsule())
                        }
                    }
                    Text(provider.freeQuota)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if aiService.selectedProvider == provider {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.indigo)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Card

    @ViewBuilder
    private var providerInfoCard: some View {
        let p = aiService.selectedProvider
        VStack(alignment: .leading, spacing: 12) {
            // Vision support banner
            if p.supportsVision {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("支持拍照识别衣物分类、颜色和风格")
                }
                .font(.caption)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.indigo.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.indigo)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                    Text("此服务商不支持图片识别，仅可用于穿搭推荐文字生成")
                }
                .font(.caption)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.orange)
            }

            // Steps to get key
            VStack(alignment: .leading, spacing: 8) {
                Text("如何获取 API Key：")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                switch p {
                case .qwen:
                    stepRow("1", "访问阿里云百炼 bailian.console.aliyun.com")
                    stepRow("2", "注册并开通「百炼」服务（新用户有免费额度）")
                    stepRow("3", "在 API-KEY 管理页创建新的 Key")
                    stepRow("4", "粘贴到上方输入框并保存")
                case .deepseek:
                    stepRow("1", "访问 platform.deepseek.com 注册账号")
                    stepRow("2", "进入 API Keys 页面，点击「创建 API Key」")
                    stepRow("3", "粘贴到上方输入框并保存")
                }
            }

            Link(destination: URL(string: p.registrationURL)!) {
                HStack {
                    Image(systemName: "safari")
                    Text("前往注册并获取 Key")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundStyle(.indigo)
            }
        }
    }

    private func stepRow(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(.indigo)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack { AISettingsView() }
}
