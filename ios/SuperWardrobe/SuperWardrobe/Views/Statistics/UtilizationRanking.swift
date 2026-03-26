import SwiftUI
import UIKit

struct UtilizationRanking: View {
    let items: [UtilizationItem]
    @Environment(\.themeTokens) private var theme

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(rankTint(index).opacity(0.18))
                            .frame(width: 54, height: 54)
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(rankTint(index).opacity(0.26), lineWidth: 1))

                        if let image = thumbnailImage(for: item) {
                            image
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            Image(systemName: "tshirt")
                                .font(.headline)
                                .foregroundStyle(rankTint(index))
                        }
                    }
                    .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.text)
                                .lineLimit(1)

                            if item.wearCount == 0 {
                                badge(text: "未穿", tint: .orange)
                            } else if item.wearCount <= 2 {
                                badge(text: "优先穿着", tint: .pink)
                            }
                        }

                        Text(item.wearCount == 0 ? "建议先激活" : "穿着 \(item.wearCount) 次")
                            .font(.caption)
                            .foregroundStyle(theme.textMuted)
                    }

                    Spacer()

                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(rankTint(index))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(rankTint(index).opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(14)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
            }
        }
    }

    private func thumbnailImage(for item: UtilizationItem) -> Image? {
        guard let data = item.imageData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    private func badge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func rankTint(_ index: Int) -> Color {
        switch index {
        case 0: return .pink
        case 1: return .orange
        case 2: return .yellow
        default: return .cyan
        }
    }
}

#Preview {
    UtilizationRanking(items: [
        UtilizationItem(id: UUID(), name: "黑色 T 恤", wearCount: 0, imageData: nil),
        UtilizationItem(id: UUID(), name: "深蓝西装裤", wearCount: 1, imageData: nil),
        UtilizationItem(id: UUID(), name: "白色板鞋", wearCount: 2, imageData: nil)
    ])
    .padding()
    .background(Color.black)
}
