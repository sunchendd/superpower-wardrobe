import SwiftUI
import SwiftData

struct OutfitDiaryView: View {
    @Query(sort: \OutfitDiary.date, order: .reverse) private var diaryEntries: [OutfitDiary]
    @Environment(\.modelContext) private var context
    @Environment(\.themeTokens) private var theme

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            Group {
                if diaryEntries.isEmpty {
                    EmptyStateView(
                        icon: "book.pages",
                        title: "还没有穿搭记录",
                        message: "从推荐页点击「就穿这套」后会自动记录到这里"
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(diaryEntries) { entry in
                                DiaryEntryCard(entry: entry)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("穿搭日记")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DiaryEntryCard: View {
    let entry: OutfitDiary
    @Environment(\.modelContext) private var context
    @Environment(\.themeTokens) private var theme

    private var outfitItems: [ClothingItem] {
        guard !entry.itemIds.isEmpty else { return [] }
        let ids = entry.itemIds
        return LocalDataService.shared.fetchClothingItems(context: context)
            .filter { ids.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.formattedDate)
                        .font(.headline)
                        .foregroundStyle(theme.text)
                    if let temp = entry.temperature, let desc = entry.weatherDescription {
                        Label("\(Int(temp))°C · \(desc)", systemImage: "cloud.sun")
                            .font(.caption)
                            .foregroundStyle(theme.textMuted)
                    }
                }
                Spacer()
                if let mood = entry.mood, !mood.isEmpty {
                    Text(mood)
                        .font(.title2)
                }
            }

            // 衣物图片
            if !outfitItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(outfitItems) { item in
                            if let data = item.imageData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.surface)
                                    .frame(width: 72, height: 72)
                                    .overlay(Image(systemName: "tshirt").foregroundStyle(theme.textSubtle))
                            }
                        }
                    }
                }
            } else if let photoData = entry.photoData, let img = UIImage(data: photoData) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 备注
            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(theme.textMuted)
            }
        }
        .padding(16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder, lineWidth: 1))
    }
}

#Preview {
    NavigationStack { OutfitDiaryView() }
}
