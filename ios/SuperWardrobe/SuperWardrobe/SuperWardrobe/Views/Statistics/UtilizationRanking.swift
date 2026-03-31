import SwiftUI
import Kingfisher

struct UtilizationRanking: View {
    let items: [UtilizationItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(rankColor(index))
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    if let urlString = item.imageUrl, let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "tshirt")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                    }

                    Text(item.name)
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                        Text("\(item.wearCount)次")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)

                if index < items.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .indigo.opacity(0.5)
        }
    }
}

#Preview {
    UtilizationRanking(items: [
        UtilizationItem(id: UUID(), name: "黑色T恤", wearCount: 25, imageUrl: nil),
        UtilizationItem(id: UUID(), name: "牛仔裤", wearCount: 20, imageUrl: nil),
        UtilizationItem(id: UUID(), name: "白色衬衫", wearCount: 15, imageUrl: nil),
    ])
    .padding()
}
