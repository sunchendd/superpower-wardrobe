import SwiftUI
import UIKit

struct ClothingItemDetailView: View {
    let item: ClothingItem
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let data = item.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.gray.opacity(0.1))
                        .frame(height: 250)
                        .overlay {
                            Image(systemName: "tshirt")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                        }
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(item.name ?? "未命名衣物")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Circle()
                            .fill(Color(hex: item.color))
                            .frame(width: 24, height: 24)
                            .overlay {
                                Circle().stroke(.gray.opacity(0.3), lineWidth: 1)
                            }
                    }

                    Divider()

                    detailRow(icon: "tag", title: "品牌", value: item.brand ?? "未知")
                    detailRow(icon: "leaf", title: "季节", value: seasonLabel(item.season))
                    detailRow(icon: "arrow.counterclockwise", title: "穿着次数", value: "\(item.wearCount) 次")

                    if let price = item.purchasePrice {
                        detailRow(icon: "yensign.circle", title: "购买价格", value: price.currencyFormatted)
                    }

                    if let date = item.purchaseDate {
                        detailRow(icon: "calendar", title: "购买日期", value: date.formattedDate)
                    }

                    if !item.styleTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("风格标签", systemImage: "sparkles")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            FlowLayout(spacing: 6) {
                                ForEach(item.styleTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(.indigo.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    if let url = item.purchaseUrl, !url.isEmpty {
                        Link(destination: URL(string: url)!) {
                            Label("购买链接", systemImage: "link")
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("衣物详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") {
                    isEditing = true
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.subheadline)
            Spacer()
        }
    }

    private func seasonLabel(_ season: String?) -> String {
        switch season {
        case "spring": return "春季"
        case "summer": return "夏季"
        case "autumn": return "秋季"
        case "winter": return "冬季"
        case "all": return "四季"
        default: return "未设置"
        }
    }
}

#Preview {
    NavigationStack {
        ClothingItemDetailView(item: .placeholder())
    }
}
