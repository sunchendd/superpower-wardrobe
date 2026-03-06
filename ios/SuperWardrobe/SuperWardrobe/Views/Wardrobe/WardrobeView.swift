import SwiftUI

struct WardrobeView: View {
    @State private var viewModel = WardrobeViewModel()
    @State private var showFilter = false
    @State private var selectedItem: ClothingItem?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryButton(nil, label: "全部")
                    ForEach(viewModel.categories) { category in
                        categoryButton(category, label: category.name)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if viewModel.isLoading {
                Spacer()
                LoadingView(message: "加载衣橱中...")
                Spacer()
            } else if viewModel.filteredItems.isEmpty {
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
                        ForEach(viewModel.filteredItems) { item in
                            ClothingItemCard(item: item)
                                .onTapGesture {
                                    selectedItem = item
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteItem(item) }
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
                    showFilter = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showFilter) {
            FilterSheet()
        }
        .sheet(item: $selectedItem) { item in
            NavigationStack {
                ClothingItemDetailView(item: item)
            }
        }
        .refreshable {
            await viewModel.loadItems()
        }
        .task {
            await viewModel.loadItems()
        }
    }

    @ViewBuilder
    private func categoryButton(_ category: Category?, label: String) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category?.id
        Button {
            viewModel.filterByCategory(category)
        } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.indigo : Color.gray.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        WardrobeView()
    }
}
