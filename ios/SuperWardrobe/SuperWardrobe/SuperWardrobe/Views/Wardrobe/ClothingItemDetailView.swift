import SwiftUI
import Kingfisher

struct ClothingItemDetailView: View {
    @State private var item: ClothingItem
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    init(item: ClothingItem) {
        _item = State(initialValue: item)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let urlString = item.imageUrl, let url = URL(string: urlString) {
                    KFImage(url)
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

                    if let urlStr = item.purchaseUrl, !urlStr.isEmpty, let purchaseURL = URL(string: urlStr) {
                        Link(destination: purchaseURL) {
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
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button {
                        LocalDataService.shared.incrementWearCount(id: item.id)
                        item.wearCount += 1
                    } label: {
                        Label("今天穿了", systemImage: "checkmark.circle")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            #if os(iOS)
            NavigationStack {
                ItemEditView(viewModel: AddItemViewModel(existingItem: item)) {
                    if let updated = LocalDataService.shared.fetchClothingItems()
                        .first(where: { $0.id == item.id }) {
                        item = updated
                    }
                    isEditing = false
                }
            }
            #endif
        }
        .confirmationDialog("确定要删除这件衣物吗？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                LocalDataService.shared.deleteClothingItem(id: item.id)
                NotificationCenter.default.post(name: NSNotification.Name("wardrobeDidChange"), object: nil)
                dismiss()
            }
            Button("取消", role: .cancel) {}
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

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

#Preview {
    NavigationStack {
        ClothingItemDetailView(item: .placeholder())
    }
}
