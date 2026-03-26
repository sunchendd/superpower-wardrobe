import SwiftUI
import SwiftData

struct OutfitDiaryView: View {
    @Query(sort: \OutfitDiary.date, order: .reverse) private var diaryEntries: [OutfitDiary]

    var body: some View {
        Group {
            if diaryEntries.isEmpty {
                EmptyStateView(icon: "book", title: "还没有穿搭记录", message: "从推荐页确认穿搭后会自动记录到这里")
            } else {
                List(diaryEntries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.date.formattedDate)
                            .font(.headline)
                        if let note = entry.note, !note.isEmpty {
                            Text(note).font(.subheadline).foregroundStyle(.secondary)
                        }
                        if let mood = entry.mood, !mood.isEmpty {
                            Text("心情: \(mood)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("穿搭日记")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { OutfitDiaryView() }
}
