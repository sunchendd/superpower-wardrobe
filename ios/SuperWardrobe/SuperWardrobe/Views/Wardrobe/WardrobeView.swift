import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeTokens) private var theme
    @State private var viewModel = WardrobeViewModel()
    @State private var selectedItem: ClothingItem?

    @Query(sort: \ClothingItem.createdAt, order: .reverse)
    private var allItems: [ClothingItem]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var displayItems: [ClothingItem] {
        viewModel.filteredItems(from: allItems)
    }

    private var activeCount: Int {
        displayItems.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroHeader
                searchField
                categoryStrip
                sectionHeader

                if displayItems.isEmpty {
                    premiumEmptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayItems) { item in
                            PremiumClothingCard(item: item)
                                .onTapGesture { selectedItem = item }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        LocalDataService.shared.deleteClothingItem(item, context: modelContext)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(theme.background.ignoresSafeArea())
        .sheet(item: $selectedItem) { item in
            LocalItemDetailView(item: item)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("衣橱")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.text)
                        .tracking(-1.2)

                    Text("了解你的穿着轮廓")
                        .font(.subheadline)
                        .foregroundStyle(theme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(activeCount) 件")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(theme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(theme.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))

                    Text(viewModel.selectedCategory?.name ?? "全部")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textMuted)
                }
            }

            HStack(spacing: 10) {
                metricPill(title: "筛选", value: viewModel.selectedCategory?.name ?? "全部")
                metricPill(title: "搜索", value: viewModel.searchText.isEmpty ? "未输入" : "已筛选")
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.textMuted)

            TextField("搜索衣物、品牌、标签", text: $viewModel.searchText)
                .foregroundStyle(theme.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.textMuted)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }

    private var categoryStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("分类")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .textCase(.uppercase)
                .tracking(1.1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(nil, label: "全部")
                    ForEach(viewModel.categories) { cat in
                        categoryChip(cat, label: cat.name)
                    }
                }
                .padding(.vertical, 2)
            }

            Capsule()
                .fill(theme.cardBorder)
                .frame(height: 1)
                .padding(.top, 2)
        }
    }

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("我的衣橱")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(theme.text)
                Text("按类别和标签快速查看")
                    .font(.caption)
                    .foregroundStyle(theme.textMuted)
            }

            Spacer()

            Text("\(displayItems.count) / \(allItems.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
        }
    }

    private var premiumEmptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.surface)
                    .frame(width: 92, height: 92)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    )

                Image(systemName: "tshirt")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(theme.accent)
            }

            Text("衣橱空空如也")
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.text)

            Text("点击底部添加按钮，先放入第一件衣物，推荐和统计就会开始工作。")
                .font(.subheadline)
                .foregroundStyle(theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }

    private func categoryChip(_ category: Category?, label: String) -> some View {
        let selected = viewModel.selectedCategory?.id == category?.id

        return Button {
            viewModel.filterByCategory(category)
        } label: {
            Text(label)
                .font(.subheadline.weight(selected ? .semibold : .medium))
                .foregroundStyle(selected ? theme.background : theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selected ? theme.accent : theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selected ? theme.accent : theme.cardBorder, lineWidth: 1))
        }
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.textMuted)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }
}

private struct PremiumClothingCard: View {
    let item: ClothingItem
    @Environment(\.themeTokens) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                cardPreview

                Text("穿 \(item.wearCount) 次")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.surface.opacity(0.9))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name ?? item.categoryName ?? "衣物")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let brand = item.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(theme.textMuted)
                            .lineLimit(1)
                    }

                    Spacer()

                    if let price = item.purchasePrice {
                        Text(price.currencyFormatted)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.text)
                    }
                }

                HStack(spacing: 6) {
                    if let category = item.categoryName {
                        tag(category, tint: theme.accent)
                    }
                    if let season = item.season {
                        tag(seasonLabel(season), tint: theme.textMuted)
                    }
                }
                .lineLimit(1)
            }
        }
        .padding(12)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }

    private var cardPreview: some View {
        Group {
            if let img = item.thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: item.color).opacity(0.55),
                            theme.accent.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: item.categoryIcon ?? "tshirt")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(theme.text.opacity(0.88))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func seasonLabel(_ season: String) -> String {
        switch season {
        case "spring": return "春"
        case "summer": return "夏"
        case "autumn": return "秋"
        case "winter": return "冬"
        case "all": return "四季"
        default: return season
        }
    }
}

private struct LocalItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeTokens) private var theme
    let item: ClothingItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroImage

                    VStack(spacing: 12) {
                        infoRow(title: "品牌", value: item.brand ?? "未知")
                        infoRow(title: "分类", value: item.categoryName ?? "未分类")
                        infoRow(title: "颜色", value: item.color)
                        infoRow(title: "穿着次数", value: "\(item.wearCount) 次")
                    }

                    if !item.styleTags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("风格标签")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(theme.text)
                            FlowLayout(spacing: 6) {
                                ForEach(item.styleTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(theme.text)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(theme.surface)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
                                }
                            }
                        }
                        .padding(16)
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
                    }
                }
                .padding(16)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("衣物详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(theme.text)
                }
            }
        }
    }

    private var heroImage: some View {
        Group {
            if let img = item.thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: item.color).opacity(0.52),
                            theme.accent.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: item.categoryIcon ?? "tshirt")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(theme.text.opacity(0.9))
                }
            }
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textMuted)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.text)
        }
        .padding(14)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }
}

#Preview {
    NavigationStack { WardrobeView() }
}
