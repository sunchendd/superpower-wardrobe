import SwiftUI

struct AISettingsView: View {
    @State private var aiService = AIService.shared
    @State private var draftKey: String = ""
    @State private var draftURL: String = ""
    @State private var isTesting = false
    @State private var testResult: Bool? = nil
    @State private var showKey = false

    var body: some View {
        Form {
            // MARK: - Intro
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "cpu.fill")
                            .font(.title2)
                            .foregroundStyle(.indigo)
                        Text("AI 功能配置")
                            .font(.headline)
                    }

                    Text("超级衣橱的 AI 识别功能由 **DeepSeek** 提供。你需要自行申请 API Key（注册免费），填入后即可享受：")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        featureBullet("拍照自动识别衣物分类、颜色、风格")
                        featureBullet("智能生成每日穿搭推荐语")
                        featureBullet("图片描述与标签建议")
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
                .padding(.vertical, 4)
            }

            // MARK: - How to get key
            Section("如何获取 API Key") {
                Link(destination: URL(string: "https://platform.deepseek.com")!) {
                    HStack {
                        Image(systemName: "safari")
                            .foregroundStyle(.indigo)
                        Text("访问 platform.deepseek.com 注册")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    step("1", "注册 DeepSeek 账号（免费）")
                    step("2", "进入 API Keys 页面，创建新 Key")
                    step("3", "复制 Key 填入下方")
                    step("4", "点击「测试连接」验证是否有效")
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }

            // MARK: - API Key Input
            Section("API Key") {
                HStack {
                    if showKey {
                        TextField("sk-...", text: $draftKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("sk-...", text: $draftKey)
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

            // MARK: - Base URL (advanced)
            Section {
                TextField("API 地址", text: $draftURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                Button("保存地址") {
                    aiService.baseURL = draftURL.trimmingCharacters(in: .whitespaces)
                }
                .disabled(draftURL.trimmingCharacters(in: .whitespaces).isEmpty)
            } header: {
                Text("API 地址（高级，一般无需修改）")
            } footer: {
                Text("默认：https://api.deepseek.com")
            }

            // MARK: - Status & Test
            Section("连接状态") {
                HStack {
                    Label(
                        aiService.isConfigured ? "已配置 API Key" : "未配置",
                        systemImage: aiService.isConfigured ? "checkmark.circle.fill" : "xmark.circle"
                    )
                    .foregroundStyle(aiService.isConfigured ? .green : .secondary)

                    Spacer()

                    if let result = testResult {
                        Label(result ? "连接成功" : "连接失败", systemImage: result ? "wifi" : "wifi.slash")
                            .font(.caption)
                            .foregroundStyle(result ? .green : .red)
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
                        if isTesting {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text(isTesting ? "测试中..." : "测试连接")
                    }
                }
                .disabled(!aiService.isConfigured || isTesting)
            }

            // MARK: - Privacy note
            Section {
                Label("你的 API Key 仅存储在本机，不会上传到任何服务器", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI 功能")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draftKey = aiService.apiKey
            draftURL = aiService.baseURL
        }
    }

    // MARK: - Helpers

    private func featureBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.indigo)
                .padding(.top, 1)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func step(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(.indigo)
                .clipShape(Circle())
            Text(text)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    NavigationStack { AISettingsView() }
}
