import SwiftUI
import SwiftData

/// Lets the user manually assemble an outfit from their wardrobe,
/// give it a name, and save it to the diary.
struct OutfitCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var outfitName: String = ""
    @State private var selectedIds: Set<UUID> = []
    @State private var isSaving = false
    @State private var showSuccess = false

    @Query(sort: \LocalClothingItem.createdAt, order: .reverse)
    private var allItems: [LocalClothingItem]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    private var selectedItems: [LocalClothingItem] {
        allItems.filter { selectedIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selected preview strip
                if !selectedIds.isEmpty {
                    selectedPreviewStrip
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                }

                // Name field
                TextField("搭配名称（可选）", text: $outfitName)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))

                Divider()

                // Wardrobe grid
                if allItems.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "tshirt",
                        title: "衣橱空空如也",
                        message: "先添加一些衣物，再来搭配吧"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(allItems) { item in
                                LocalItemTile(
                                    item: item,
                                    isSelected: selectedIds.contains(item.id)
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.25)) {
                                        if selectedIds.contains(item.id) {
                                            selectedIds.remove(item.id)
                                        } else {
                                            selectedIds.insert(item.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle("创建搭配")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveOutfit()
                    } label: {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("保存").fontWeight(.semibold)
                        }
                    }
                    .disabled(selectedIds.isEmpty || isSaving)
                }
            }
            .alert("搭配已保存", isPresented: $showSuccess) {
                Button("完成") { dismiss() }
            } message: {
                Text("你的搭配 \"\(outfitName.isEmpty ? "新搭配" : outfitName)\" 已保存到穿搭日记。")
            }
        }
    }

    // MARK: - Subviews

    private var selectedPreviewStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("已选 \(selectedIds.count) 件")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedItems) { item in
                        ZStack(alignment: .topTrailing) {
                            itemThumb(item)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    selectedIds.remove(item.id)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)).padding(1))
                            }
                            .offset(x: 4, y: -4)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func itemThumb(_ item: LocalClothingItem) -> some View {
        if let img = item.thumbnail {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            Color(hex: item.colorHex).opacity(0.3)
                .overlay {
                    Image(systemName: item.categoryIcon ?? "tshirt")
                        .foregroundStyle(Color(hex: item.colorHex))
                }
        }
    }

    // MARK: - Actions

    private func saveOutfit() {
        guard !selectedIds.isEmpty else { return }
        isSaving = true

        let entry = LocalOutfitDiary(
            date: Date(),
            notes: outfitName.isEmpty ? nil : outfitName,
            itemIds: Array(selectedIds)
        )
        LocalDataService.shared.saveDiaryEntry(entry, context: modelContext)

        // Bump wear count for each selected item
        for item in selectedItems {
            LocalDataService.shared.incrementWearCount(for: item, context: modelContext)
        }

        isSaving = false
        showSuccess = true
    }
}

// MARK: - Local Item Tile

struct LocalItemTile: View {
    let item: LocalClothingItem
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image or color swatch
            Group {
                if let img = item.thumbnail {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(hex: item.colorHex).opacity(0.25)
                        .overlay {
                            Image(systemName: item.categoryIcon ?? "tshirt")
                                .font(.title2)
                                .foregroundStyle(Color(hex: item.colorHex))
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Selection checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .background(Circle().fill(.indigo).padding(2))
                    .padding(4)
                    .transition(.scale.combined(with: .opacity))
            }

            // Selection border
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected ? Color.indigo : Color.clear, lineWidth: 2.5)
        }
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if let name = item.name ?? item.categoryName {
                Text(name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(4)
            }
        }
    }
}

#Preview {
    OutfitCreatorView()
}
