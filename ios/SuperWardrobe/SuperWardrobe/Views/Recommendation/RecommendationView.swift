import SwiftUI
import SwiftData

struct RecommendationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeTokens) private var theme
    @State private var viewModel = RecommendationViewModel()
    @State private var currentPage = 0
    @State private var showSavedAlert = false

    private var currentSuggestion: OutfitSuggestion? {
        guard !viewModel.suggestions.isEmpty else { return nil }
        return viewModel.suggestions[currentPage % viewModel.suggestions.count]
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if viewModel.isLoading {
                LoadingView(message: "正在为你搭配...")
            } else if let suggestion = currentSuggestion {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        weatherHero
                        recommendationCard(suggestion)
                        actionRow
                        pageIndicator
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 130)
                }
                .refreshable {
                    await refreshRecommendations()
                }
            } else {
                EmptyStateView(
                    icon: "tshirt",
                    title: "衣橱还是空的",
                    message: "先添加一些衣物，系统才会为你生成今日推荐",
                    actionTitle: "去添加"
                )
                .padding(.horizontal, 24)
            }
        }
        .task {
            await refreshRecommendations()
        }
        .alert("已记录今天穿搭", isPresented: $showSavedAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("这套搭配已经写入穿搭日记，并更新了衣物穿着次数。")
        }
    }

    private var weatherHero: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.locationLine)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.text.opacity(0.88))

                Text(viewModel.weather?.temperatureFormatted.replacingOccurrences(of: "C", with: "") ?? "--°")
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .foregroundStyle(theme.text)
                    .monospacedDigit()
                    .tracking(-2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Text(viewModel.weatherSummary)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.text.opacity(0.76))

                Text(viewModel.windSummary)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.textMuted)

                Text(viewModel.umbrellaAdvice)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.umbrellaAdvice.contains("带伞") ? theme.warning : theme.success)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background((viewModel.umbrellaAdvice.contains("带伞") ? theme.warning : theme.success).opacity(0.14))
                    .clipShape(Capsule())
            }
        }
    }

    private func recommendationCard(_ suggestion: OutfitSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("今日推荐")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(theme.text)

            HStack(spacing: 10) {
                ForEach(suggestion.items.prefix(4)) { item in
                    recommendationTile(for: item)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(suggestion.reason)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(suggestion.weatherTip ?? "适合通勤，温度适宜")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(20)
        .background(theme.card)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func recommendationTile(for item: ClothingItem) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.surfaceRaised)

                if let image = item.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: item.categoryIcon ?? "hanger")
                            .font(.title3)
                            .foregroundStyle(Color(hex: item.color))
                        Circle()
                            .fill(Color(hex: item.color))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)

            Text(item.name ?? item.categoryName ?? "单品")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.text.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(theme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                confirmCurrentSuggestion()
            } label: {
                Text("就穿这套")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(currentSuggestion == nil)

            Button {
                guard !viewModel.suggestions.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    currentPage = (currentPage + 1) % viewModel.suggestions.count
                }
            } label: {
                Text("换一套")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(theme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(theme.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled((viewModel.suggestions.count) < 2)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.suggestions.indices), id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? theme.accent : theme.textMuted.opacity(0.25))
                    .frame(width: index == currentPage ? 22 : 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [theme.accent, theme.accent.opacity(0.86)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func refreshRecommendations() async {
        await viewModel.refresh(context: modelContext)
        if currentPage >= viewModel.suggestions.count {
            currentPage = 0
        }
    }

    private func confirmCurrentSuggestion() {
        guard let suggestion = currentSuggestion else { return }

        let entry = OutfitDiary(
            date: Date(),
            note: suggestion.reason,
            itemIds: suggestion.items.map(\.id)
        )
        LocalDataService.shared.saveDiaryEntry(entry, context: modelContext)

        for item in suggestion.items {
            LocalDataService.shared.incrementWearCount(for: item, context: modelContext)
        }

        showSavedAlert = true
    }
}

#Preview {
    NavigationStack {
        RecommendationView()
    }
}
