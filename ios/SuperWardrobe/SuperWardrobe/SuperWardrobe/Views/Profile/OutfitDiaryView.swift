import SwiftUI
import Kingfisher

struct OutfitDiaryView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var showNewEntry = false
    @State private var newNote = ""
    @State private var newMood = "😊"

    private let moods = ["😊", "😍", "😎", "🥰", "😴", "🤔", "😢", "😡"]

    var body: some View {
        Group {
            if viewModel.diaryEntries.isEmpty {
                EmptyStateView(
                    icon: "book",
                    title: "还没有日记",
                    message: "记录每天的穿搭心情吧"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.diaryEntries) { entry in
                            DiaryEntryCard(entry: entry)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("穿搭日记")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewEntry = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewEntry) {
            NavigationStack {
                Form {
                    Section("心情") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(moods, id: \.self) { mood in
                                    Button {
                                        newMood = mood
                                    } label: {
                                        Text(mood)
                                            .font(.title)
                                            .padding(8)
                                            .background(newMood == mood ? Color.indigo.opacity(0.2) : Color.clear)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                    }

                    Section("今日笔记") {
                        TextEditor(text: $newNote)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("新日记")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") {
                            newMood = "😊"
                            newNote = ""
                            showNewEntry = false
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("保存") {
                            Task {
                                let userId = LocalDataService.shared.currentUserId
                                let entry = OutfitDiary(
                                    id: UUID(),
                                    userId: userId,
                                    date: Date(),
                                    outfitId: nil,
                                    photoUrl: nil,
                                    note: newNote.isEmpty ? nil : newNote,
                                    weatherData: nil,
                                    mood: newMood,
                                    sharedAt: nil
                                )
                                await viewModel.saveDiaryEntry(entry)
                                showNewEntry = false
                                newMood = "😊"
                                newNote = ""
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .task {
            await viewModel.loadDiary(month: Date())
        }
    }
}

struct DiaryEntryCard: View {
    let entry: OutfitDiary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.date.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if let mood = entry.mood {
                    Text(mood)
                        .font(.title3)
                }
            }

            if let photoUrl = entry.photoUrl, let url = URL(string: photoUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let note = entry.note {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let weather = entry.weatherData, !weather.isEmpty {
                Label("已记录天气", systemImage: "cloud")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        OutfitDiaryView()
    }
}
