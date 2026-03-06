import SwiftUI

struct OutfitCalendarView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var currentMonth = Date()
    @State private var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(currentMonth.monthYearString)
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(height: 30)
                }

                ForEach(daysInMonth(), id: \.self) { date in
                    if let date {
                        let hasEntry = viewModel.diaryEntries.contains { $0.date.isSameDay(as: date) }
                        let isSelected = selectedDate?.isSameDay(as: date) ?? false
                        let isToday = date.isSameDay(as: Date())

                        Button {
                            selectedDate = date
                        } label: {
                            VStack(spacing: 2) {
                                Text(date.dayString)
                                    .font(.subheadline)
                                    .fontWeight(isToday ? .bold : .regular)
                                    .foregroundStyle(isSelected ? .white : isToday ? .indigo : .primary)

                                Circle()
                                    .fill(hasEntry ? .indigo : .clear)
                                    .frame(width: 6, height: 6)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isSelected ? Color.indigo : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal)

            if let selectedDate {
                let entry = viewModel.diaryEntries.first { $0.date.isSameDay(as: selectedDate) }
                if let entry {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedDate.formattedDate)
                            .font(.headline)
                        if let note = entry.note {
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let mood = entry.mood {
                            Text("心情: \(mood)")
                                .font(.caption)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                    .padding(.horizontal)
                } else {
                    Text("当日无穿搭记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }

            Spacer()
        }
        .navigationTitle("穿搭日历")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDiary(month: currentMonth)
        }
        .onChange(of: currentMonth) { _, newMonth in
            Task {
                await viewModel.loadDiary(month: newMonth)
            }
        }
    }

    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let startOfMonth = currentMonth.startOfMonth
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let daysCount = currentMonth.daysInMonth

        var days: [Date?] = Array(repeating: nil, count: weekday - 1)
        for day in 1...daysCount {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        return days
    }
}

#Preview {
    NavigationStack {
        OutfitCalendarView()
    }
}
