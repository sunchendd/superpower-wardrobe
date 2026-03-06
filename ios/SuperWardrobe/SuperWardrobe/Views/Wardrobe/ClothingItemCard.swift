import SwiftUI
import Kingfisher

struct ClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let urlString = item.imageUrl, let url = URL(string: urlString) {
                    KFImage(url)
                        .placeholder {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray.opacity(0.1))
                                .overlay {
                                    ProgressView()
                                }
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.1))
                        .frame(height: 180)
                        .overlay {
                            Image(systemName: "tshirt")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                }

                if item.wearCount > 0 {
                    Text("\(item.wearCount)次")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: item.color))
                    .frame(width: 12, height: 12)

                Text(item.name ?? "未命名")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            if let brand = item.brand {
                Text(brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    ClothingItemCard(item: .placeholder())
        .frame(width: 180)
        .padding()
}
