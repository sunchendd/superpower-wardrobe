import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: ThemeTokens { themeManager.tokens }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(theme.isDarkFixed ? 0.16 : 0.11))
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.text)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "tshirt",
        title: "衣橱空空如也",
        message: "点击 + 按钮开始添加你的第一件衣物吧",
        actionTitle: "立即添加"
    ) {
        print("add")
    }
}
