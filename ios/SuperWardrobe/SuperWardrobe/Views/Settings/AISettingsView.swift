import SwiftUI

struct AISettingsView: View {
    @State private var aiService = QwenVLService.shared
    @State private var draftKey = ""
    @State private var showKey = false
    @State private var isTesting = false
    @State private var testResult: Bool?
    @State private var testErrorMessage: String?

    var body: some View {
        Form {
            Section("通义千问 API Key") {
                HStack {
                    if showKey {
                        TextField("sk-...", text: $draftKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
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
                    aiService.apiKey = draftKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    testResult = nil
                }
                .disabled(draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("连接状态") {
                HStack {
                    Label(
                        aiService.isConfigured ? "已配置" : "未配置",
                        systemImage: aiService.isConfigured ? "checkmark.circle.fill" : "xmark.circle"
                    )
                    .foregroundStyle(aiService.isConfigured ? .green : .secondary)

                    Spacer()

                    if let ok = testResult {
                        Label(ok ? "连接成功" : "连接失败", systemImage: ok ? "wifi" : "wifi.slash")
                            .font(.caption)
                            .foregroundStyle(ok ? .green : .red)
                    }
                }

                if let errMsg = testErrorMessage, testResult == false {
                    Text(errMsg)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        isTesting = true
                        testErrorMessage = nil
                        do {
                            testResult = try await aiService.testAPI()
                        } catch {
                            testResult = false
                            testErrorMessage = error.localizedDescription
                        }
                        isTesting = false
                    }
                } label: {
                    HStack {
                        if isTesting {
                            ProgressView().scaleEffect(0.9)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text(isTesting ? "测试中..." : "测试连接")
                    }
                }
                .disabled(!aiService.isConfigured || isTesting)
            }

            Section("使用说明") {
                Text("1. 打开阿里云百炼创建 API Key")
                Text("2. 粘贴后保存，再点击“测试连接”")
                Text("3. 回到添加衣物页即可使用拍照识别")
                Link("打开阿里云百炼", destination: URL(string: "https://bailian.console.aliyun.com")!)
            }

            Section {
                Label("API Key 仅保存在本机（Keychain）", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Qwen 配置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draftKey = aiService.apiKey
        }
    }
}

#Preview {
    NavigationStack { AISettingsView() }
}
