import SwiftUI

struct LoadingView: View {
    let message: String
    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: ThemeTokens { themeManager.tokens }

    init(message: String = "加载中...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.card)
                    .frame(width: 76, height: 76)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    )

                ProgressView()
                    .scaleEffect(1.15)
                    .tint(theme.accent)
            }

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView(message: "正在加载衣橱...")
}
