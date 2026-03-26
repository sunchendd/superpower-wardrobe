import SwiftUI
import SwiftData

struct SettingsAppView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeTokens) private var theme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var aiService = QwenVLService.shared
    @State private var showClearAlert = false

    @Query private var allItems: [ClothingItem]
    @Query private var allDiaries: [OutfitDiary]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                headerCard
                appearanceCard
                recordCard
                aiCard
                dataCard
                aboutCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(theme.background.ignoresSafeArea())
        .alert("确认清空", isPresented: $showClearAlert) {
            Button("清空", role: .destructive) { clearAllData() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将删除所有衣物数据，此操作不可撤销。")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(theme.titleGradient)
                        .frame(width: 72, height: 72)
                    Image(systemName: "hanger")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.accentForeground)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("超级衣橱")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.text)
                    Text("把穿搭决策压缩到 30 秒")
                        .font(.subheadline)
                        .foregroundStyle(theme.textMuted)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                metricChip("\(allItems.count) 件衣物")
                metricChip("\(allDiaries.count) 条日记")
                metricChip(themeManager.tokens.isDarkFixed ? "夜间" : "白天")
            }
        }
        .themeSurface()
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeading("主题外观", subtitle: "夜间固定黑曜石，白天支持多色主题")

            HStack(spacing: 12) {
                modeButton(
                    title: "夜间",
                    isSelected: themeManager.tokens.isDarkFixed
                ) {
                    themeManager.useDarkFixedMode()
                }

                modeButton(
                    title: "白天",
                    isSelected: !themeManager.tokens.isDarkFixed
                ) {
                    themeManager.useLightPalette(themeManager.selectedLightPalette)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ThemePalette.allCases) { palette in
                    paletteButton(palette)
                }
            }
        }
        .themeSurface()
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("穿搭记录", subtitle: "查看你最近的确认穿搭")

            NavigationLink {
                OutfitCalendarView()
            } label: {
                settingsRow(title: "穿搭日历", systemImage: "calendar", trailing: "查看")
            }
            .buttonStyle(.plain)

            NavigationLink {
                OutfitDiaryView()
            } label: {
                settingsRow(title: "穿搭日记", systemImage: "book", trailing: "查看")
            }
            .buttonStyle(.plain)
        }
        .themeSurface()
    }

    private var aiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("AI 功能", subtitle: "配置 Qwen API 后可解锁拍照识别")

            NavigationLink {
                AISettingsView()
            } label: {
                settingsRow(
                    title: "Qwen AI 配置",
                    systemImage: "cpu",
                    trailing: aiService.isConfigured ? "已配置" : "未配置",
                    trailingTint: aiService.isConfigured ? theme.success : theme.warning
                )
            }
            .buttonStyle(.plain)
        }
        .themeSurface()
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("数据管理", subtitle: "首测版所有数据都只保存在本机")

            settingsRow(title: "存储位置", systemImage: "iphone", trailing: "本机 · 不联网")

            Button(role: .destructive) {
                showClearAlert = true
            } label: {
                settingsRow(title: "清空所有衣物数据", systemImage: "trash", trailing: "删除", trailingTint: theme.danger)
            }
            .buttonStyle(.plain)
        }
        .themeSurface()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("关于", subtitle: "版本与说明")

            settingsRow(title: "版本", systemImage: "sparkles", trailing: appVersion)
            settingsRow(title: "版本模式", systemImage: "checkmark.circle", trailing: "首测版", trailingTint: theme.success)
        }
        .themeSurface()
    }

    private func modeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(isSelected ? theme.accentForeground : theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? theme.accent : theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? theme.accent : theme.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func paletteButton(_ palette: ThemePalette) -> some View {
        let isSelected = !themeManager.tokens.isDarkFixed && themeManager.selectedLightPalette == palette
        let paletteTokens = ThemeTokens.light(palette)

        return Button {
            themeManager.useLightPalette(palette)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(paletteTokens.accent)
                        .frame(width: 16, height: 16)
                    Text(palette.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(theme.text)
                    Spacer()
                }

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [paletteTokens.background, paletteTokens.card],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(paletteTokens.cardBorder, lineWidth: 1)
                    )
            }
            .padding(14)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? theme.accent : theme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func metricChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.textMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(theme.surfaceRaised)
            .clipShape(Capsule())
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.text)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(theme.textMuted)
        }
    }

    private func settingsRow(
        title: String,
        systemImage: String,
        trailing: String,
        trailingTint: Color? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 22)
                .foregroundStyle(theme.accent)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.text)

            Spacer()

            Text(trailing)
                .font(.caption.weight(.semibold))
                .foregroundStyle(trailingTint ?? theme.textMuted)
        }
        .padding(14)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
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
        .themeManager(.shared)
}
