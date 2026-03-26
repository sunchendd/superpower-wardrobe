import SwiftUI
import SwiftData

struct OutfitCalendarView: View {
    @Query(sort: \OutfitDiary.date, order: .reverse) private var diaryEntries: [OutfitDiary]
    @State private var selectedDate = Date()

    private var todaysEntries: [OutfitDiary] {
        diaryEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 16) {
            DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)

            if todaysEntries.isEmpty {
                EmptyStateView(icon: "calendar", title: "当天暂无记录", message: "去推荐页点击“就穿这套”即可自动记录")
            } else {
                List(todaysEntries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.date.formattedDate)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if let note = entry.note, !note.isEmpty {
                            Text(note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("穿搭日历")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { OutfitCalendarView() }
}
