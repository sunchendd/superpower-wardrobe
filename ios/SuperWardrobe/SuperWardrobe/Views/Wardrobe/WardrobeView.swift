import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WardrobeViewModel()
    @State private var selectedItem: LocalClothingItem?
    @State private var showOutfitCreator = false
    @State private var showFilter = false

    @Query(sort: \LocalClothingItem.createdAt, order: .reverse)
    private var allItems: [LocalClothingItem]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var displayItems: [LocalClothingItem] {
        viewModel.filteredItems(from: allItems)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(nil, label: "全部")
                    ForEach(viewModel.categories) { cat in
                        categoryChip(cat, label: cat.name)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Grid or empty state
            if displayItems.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "tshirt",
                    title: "衣橱空空如也",
                    message: "点击 + 开始添加你的第一件衣物"
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayItems) { item in
                            LocalClothingCard(item: item)
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
                    .padding()
                }
            }
        }
        .navigationTitle("我的衣橱")
        .searchable(text: $viewModel.searchText, prompt: "搜索衣物...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showOutfitCreator = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            LocalItemDetailView(item: item)
        }
        .sheet(isPresented: $showOutfitCreator) {
            OutfitCreatorView()
        }
    }

    @ViewBuilder
    private func categoryChip(_ category: Category?, label: String) -> some View {
        let selected = viewModel.selectedCategory?.id == category?.id
        Button { viewModel.filterByCategory(category) } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(selected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selected ? Color.indigo : Color.gray.opacity(0.12))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Local Clothing Card

struct LocalClothingCard: View {
    let item: LocalClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let img = item.thumbnail {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(hex: item.colorHex).opacity(0.2)
                        .overlay {
                            Image(systemName: item.categoryIcon ?? "tshirt")
                                .font(.largeTitle)
                                .foregroundStyle(Color(hex: item.colorHex))
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? item.categoryName ?? "衣物")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let brand = item.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                    if item.wearCount > 0 {
                        Label("\(item.wearCount)", systemImage: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Local Item Detail

struct LocalItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let item: LocalClothingItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let img = item.thumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: item.colorHex).opacity(0.15))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1.3, contentMode: .fit)
                            .overlay {
                                Image(systemName: item.categoryIcon ?? "tshirt")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color(hex: item.colorHex))
                            }
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        if let name = item.name {
                            Text(name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        if let brand = item.brand {
                            LabeledContent("品牌", value: brand)
                        }
                        if let category = item.categoryName {
                            LabeledContent("分类", value: category)
                        }

                        LabeledContent("颜色") {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: item.colorHex))
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(.secondary.opacity(0.3), lineWidth: 1))
                                Text(item.colorHex).foregroundStyle(.secondary)
                            }
                        }

                        if let price = item.purchasePrice {
                            LabeledContent("价格", value: price.currencyFormatted)
                        }

                        LabeledContent("穿着次数", value: "\(item.wearCount) 次")

                        if !item.styleTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("风格标签")
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
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("衣物详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { WardrobeView() }
}
