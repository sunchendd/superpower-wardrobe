import SwiftUI

enum ThemePalette: String, CaseIterable, Identifiable {
    case rose
    case ocean
    case sage
    case lavender

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rose: return "Rose"
        case .ocean: return "Ocean"
        case .sage: return "Sage"
        case .lavender: return "Lavender"
        }
    }
}

enum ThemeMode: Equatable {
    case darkFixed
    case light(ThemePalette)
}

struct ThemeTokens: Equatable, Sendable {
    let mode: ThemeMode
    let palette: ThemePalette?
    let background: Color
    let backgroundTint: Color
    let surface: Color
    let surfaceRaised: Color
    let card: Color
    let cardBorder: Color
    let text: Color
    let textMuted: Color
    let textSubtle: Color
    let accent: Color
    let accentForeground: Color
    let success: Color
    let warning: Color
    let danger: Color
    let shadow: Color
    let tabBarBackground: Color

    var isDarkFixed: Bool {
        if case .darkFixed = mode { return true }
        return false
    }

    var titleGradient: LinearGradient {
        LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [background, backgroundTint], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let darkFixed = ThemeTokens(
        mode: .darkFixed,
        palette: nil,
        background: Color(hex: "#020203"),
        backgroundTint: Color(hex: "#09090C"),
        surface: Color.white.opacity(0.04),
        surfaceRaised: Color.white.opacity(0.07),
        card: Color.white.opacity(0.04),
        cardBorder: Color.white.opacity(0.09),
        text: Color(hex: "#EDEDEF"),
        textMuted: Color(hex: "#8A8F98"),
        textSubtle: Color(hex: "#5E6470"),
        accent: Color(hex: "#BE185D"),
        accentForeground: .white,
        success: Color(hex: "#22C55E"),
        warning: Color(hex: "#F59E0B"),
        danger: Color(hex: "#EF4444"),
        shadow: .black.opacity(0.55),
        tabBarBackground: Color(hex: "#0B0B0D").opacity(0.96)
    )

    static func light(_ palette: ThemePalette) -> ThemeTokens {
        switch palette {
        case .rose:
            return ThemeTokens(
                mode: .light(.rose),
                palette: .rose,
                background: Color(hex: "#FDF2F8"),
                backgroundTint: Color(hex: "#FFF7FB"),
                surface: .white,
                surfaceRaised: .white,
                card: .white,
                cardBorder: Color(hex: "#F4BBD2"),
                text: Color(hex: "#0F172A"),
                textMuted: Color(hex: "#64748B"),
                textSubtle: Color(hex: "#94A3B8"),
                accent: Color(hex: "#BE185D"),
                accentForeground: .white,
                success: Color(hex: "#16A34A"),
                warning: Color(hex: "#D97706"),
                danger: Color(hex: "#DC2626"),
                shadow: .black.opacity(0.12),
                tabBarBackground: .white.opacity(0.94)
            )
        case .ocean:
            return ThemeTokens(
                mode: .light(.ocean),
                palette: .ocean,
                background: Color(hex: "#F0F9FF"),
                backgroundTint: Color(hex: "#F8FDFF"),
                surface: .white,
                surfaceRaised: .white,
                card: .white,
                cardBorder: Color(hex: "#B8DAF6"),
                text: Color(hex: "#0F172A"),
                textMuted: Color(hex: "#64748B"),
                textSubtle: Color(hex: "#94A3B8"),
                accent: Color(hex: "#0369A1"),
                accentForeground: .white,
                success: Color(hex: "#16A34A"),
                warning: Color(hex: "#D97706"),
                danger: Color(hex: "#DC2626"),
                shadow: .black.opacity(0.12),
                tabBarBackground: .white.opacity(0.94)
            )
        case .sage:
            return ThemeTokens(
                mode: .light(.sage),
                palette: .sage,
                background: Color(hex: "#F0FDF4"),
                backgroundTint: Color(hex: "#F8FFF9"),
                surface: .white,
                surfaceRaised: .white,
                card: .white,
                cardBorder: Color(hex: "#BEE5C7"),
                text: Color(hex: "#0F172A"),
                textMuted: Color(hex: "#64748B"),
                textSubtle: Color(hex: "#94A3B8"),
                accent: Color(hex: "#15803D"),
                accentForeground: .white,
                success: Color(hex: "#16A34A"),
                warning: Color(hex: "#D97706"),
                danger: Color(hex: "#DC2626"),
                shadow: .black.opacity(0.12),
                tabBarBackground: .white.opacity(0.94)
            )
        case .lavender:
            return ThemeTokens(
                mode: .light(.lavender),
                palette: .lavender,
                background: Color(hex: "#F5F3FF"),
                backgroundTint: Color(hex: "#FBFAFF"),
                surface: .white,
                surfaceRaised: .white,
                card: .white,
                cardBorder: Color(hex: "#D8CEF8"),
                text: Color(hex: "#0F172A"),
                textMuted: Color(hex: "#64748B"),
                textSubtle: Color(hex: "#94A3B8"),
                accent: Color(hex: "#7C3AED"),
                accentForeground: .white,
                success: Color(hex: "#16A34A"),
                warning: Color(hex: "#D97706"),
                danger: Color(hex: "#DC2626"),
                shadow: .black.opacity(0.12),
                tabBarBackground: .white.opacity(0.94)
            )
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var mode: ThemeMode = .darkFixed

    var tokens: ThemeTokens {
        switch mode {
        case .darkFixed:
            return .darkFixed
        case .light(let palette):
            return .light(palette)
        }
    }

    var isDarkFixed: Bool {
        if case .darkFixed = mode { return true }
        return false
    }

    var selectedLightPalette: ThemePalette {
        get {
            switch mode {
            case .darkFixed:
                return .rose
            case .light(let palette):
                return palette
            }
        }
        set {
            mode = .light(newValue)
        }
    }

    func useDarkFixedMode() {
        mode = .darkFixed
    }

    func useLightPalette(_ palette: ThemePalette) {
        mode = .light(palette)
    }
}

private struct ThemeTokensKey: EnvironmentKey {
    static let defaultValue: ThemeTokens = .darkFixed
}

extension EnvironmentValues {
    var themeTokens: ThemeTokens {
        get { self[ThemeTokensKey.self] }
        set { self[ThemeTokensKey.self] = newValue }
    }
}

extension View {
    func themeManager(_ manager: ThemeManager) -> some View {
        environmentObject(manager)
            .environment(\.themeTokens, manager.tokens)
    }

    func themeTokens(_ tokens: ThemeTokens) -> some View {
        environment(\.themeTokens, tokens)
    }
}

struct ThemeSurfaceBackground: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private var tokens: ThemeTokens { themeManager.tokens }

    var body: some View {
        ZStack {
            tokens.background

            Ellipse()
                .fill(tokens.accent.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -120, y: -260)

            Ellipse()
                .fill(tokens.accent.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 100)
                .offset(x: 150, y: 280)

            LinearGradient(
                colors: [tokens.backgroundTint.opacity(0.0), tokens.backgroundTint.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

struct ThemeSurfaceModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    private var tokens: ThemeTokens { themeManager.tokens }

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(tokens.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(tokens.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: tokens.shadow.opacity(tokens.isDarkFixed ? 0.32 : 0.08), radius: 18, x: 0, y: 10)
            )
    }
}

struct ThemeCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    private var tokens: ThemeTokens { themeManager.tokens }

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(tokens.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(tokens.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: tokens.shadow.opacity(tokens.isDarkFixed ? 0.28 : 0.08), radius: 14, x: 0, y: 8)
            )
    }
}

extension View {
    func themeSurface() -> some View {
        modifier(ThemeSurfaceModifier())
    }

    func themeCard() -> some View {
        modifier(ThemeCardModifier())
    }
}
