import SwiftUI

struct PurchaseSuggestionRow: View {
    let suggestion: PurchaseRecommendation

    private var priorityColor: Color {
        switch suggestion.priority {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }

    private var priorityLabel: String {
        switch suggestion.priority {
        case 1: return "高"
        case 2: return "中"
        case 3: return "低"
        default: return "—"
        }
    }

    private var seasonLabel: String {
        switch suggestion.season {
        case "spring": return "春"
        case "summer": return "夏"
        case "autumn": return "秋"
        case "winter": return "冬"
        default: return "四季"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(priorityColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "bag")
                        .foregroundStyle(priorityColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                if let reason = suggestion.reason {
                    Text(reason)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                if let description = suggestion.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let tags = suggestion.styleTags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.indigo.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("优先级: \(priorityLabel)")
                    .font(.caption2)
                    .foregroundStyle(priorityColor)
                Text(seasonLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .cardStyle()
    }
}

#Preview {
    PurchaseSuggestionRow(suggestion: PurchaseRecommendation(
        id: UUID(),
        userId: UUID(),
        categoryId: nil,
        reason: "缺少一件百搭的白色T恤",
        description: "推荐购买一件纯棉白色圆领T恤，可以搭配多种下装",
        styleTags: ["休闲", "百搭", "基础"],
        season: "summer",
        priority: 1,
        status: "active"
    ))
    .padding()
}
