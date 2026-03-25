import SwiftUI
import SwiftData

/// App settings tab in the local-only build.
struct SettingsAppView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var aiService = AIService.shared
    @State private var showClearAlert = false

    @Query private var allItems: [LocalClothingItem]
    @Query private var allDiaries: [LocalOutfitDiary]

    var body: some View {
        List {
            // MARK: - App Info Header
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                        Image(systemName: "hanger")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("超级衣橱")
                            .font(.headline)
                        HStack(spacing: 12) {
                            Label("\(allItems.count) 件衣物", systemImage: "tshirt")
                            Label("\(allDiaries.count) 条日记", systemImage: "book")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Records
            Section("穿搭记录") {
                NavigationLink { OutfitCalendarView() } label: {
                    Label("穿搭日历", systemImage: "calendar")
                }
                NavigationLink { OutfitDiaryView() } label: {
                    Label("穿搭日记", systemImage: "book")
                }
                NavigationLink { TravelPlanView() } label: {
                    Label("旅行计划", systemImage: "airplane")
                }
            }

            // MARK: - AI Settings
            Section("AI 功能") {
                NavigationLink { AISettingsView() } label: {
                    HStack {
                        Label("DeepSeek AI 配置", systemImage: "cpu")
                        Spacer()
                        if aiService.isConfigured {
                            Label("已配置", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("未配置")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                if !aiService.isConfigured {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.orange)
                        Text("配置 API Key 后可解锁拍照智能识别功能")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Data
            Section("数据管理") {
                HStack {
                    Label("存储位置", systemImage: "iphone")
                    Spacer()
                    Text("本机 · 不联网").font(.caption).foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    showClearAlert = true
                } label: {
                    Label("清空所有衣物数据", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }

            // MARK: - About
            Section("关于") {
                LabeledContent("版本", value: appVersion)
                HStack {
                    Label("购买状态", systemImage: "crown.fill")
                    Spacer()
                    Label("已解锁", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    Label("隐私政策", systemImage: "hand.raised")
                }
                Link(destination: URL(string: "https://example.com/terms")!) {
                    Label("使用条款", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("设置")
        .alert("确认清空", isPresented: $showClearAlert) {
            Button("清空", role: .destructive) { clearAllData() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将删除所有衣物数据，此操作不可撤销。")
        }
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }

    private func clearAllData() {
        for item in allItems { modelContext.delete(item) }
        for diary in allDiaries { modelContext.delete(diary) }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack { SettingsAppView() }
}
