import SwiftUI

enum SuperWardrobeShellTab: Int, CaseIterable, Identifiable {
    case recommendation
    case wardrobe
    case add
    case statistics
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .recommendation: return "推荐"
        case .wardrobe: return "衣橱"
        case .add: return "添加"
        case .statistics: return "统计"
        case .settings: return "设置"
        }
    }

    var icon: String {
        switch self {
        case .recommendation: return "eye"
        case .wardrobe: return "hanger"
        case .add: return "plus"
        case .statistics: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

struct WardrobeAppShell<Recommendation: View, Wardrobe: View, Statistics: View, Settings: View>: View {
    @Binding var selection: SuperWardrobeShellTab
    let onAdd: () -> Void
    let recommendation: Recommendation
    let wardrobe: Wardrobe
    let statistics: Statistics
    let settings: Settings

    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: ThemeTokens { themeManager.tokens }

    var body: some View {
        ZStack(alignment: .bottom) {
            ThemeSurfaceBackground()

            currentScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                Spacer()
                WardrobeFloatingTabBar(selection: $selection, onAdd: onAdd)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selection {
        case .recommendation:
            recommendation
        case .wardrobe:
            wardrobe
        case .add:
            recommendation
        case .statistics:
            statistics
        case .settings:
            settings
        }
    }
}

struct WardrobeFloatingTabBar: View {
    @Binding var selection: SuperWardrobeShellTab
    let onAdd: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: ThemeTokens { themeManager.tokens }

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.recommendation)
            tabButton(.wardrobe)

            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 60, height: 60)
                        .shadow(color: theme.shadow, radius: 16, x: 0, y: 8)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(theme.accentForeground)
                }
                .offset(y: -24)
            }
            .accessibilityLabel("添加衣物")
            .frame(maxWidth: .infinity)

            tabButton(.statistics)
            tabButton(.settings)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(theme.tabBarBackground)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
                .shadow(color: theme.shadow.opacity(theme.isDarkFixed ? 0.45 : 0.14), radius: 18, x: 0, y: 10)
        )
    }

    @ViewBuilder
    private func tabButton(_ tab: SuperWardrobeShellTab) -> some View {
        let isSelected = selection == tab

        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                Text(tab.title)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? theme.accent : theme.textMuted)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}

struct WardrobeHeroHeader: View {
    let title: String
    let subtitle: String?
    let trailingBadge: String?

    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: ThemeTokens { themeManager.tokens }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.text)
                        .tracking(-1.4)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(theme.textMuted)
                    }
                }

                Spacer(minLength: 12)

                if let trailingBadge {
                    Text(trailingBadge)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(theme.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(theme.card.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
                }
            }
        }
    }
}

struct WardrobeGlassCard<Content: View>: View {
    let content: Content

    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: ThemeTokens { themeManager.tokens }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: theme.shadow.opacity(theme.isDarkFixed ? 0.32 : 0.08), radius: 18, x: 0, y: 10)
            )
    }
}
