import SwiftUI
import SwiftData

struct RecommendationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = RecommendationViewModel()
    @State private var currentPage = 0

    private var isGuest: Bool { authViewModel.isGuestMode }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weather card
                if let weather = viewModel.weather {
                    WeatherCard(weather: weather)
                        .padding(.horizontal)
                }

                // Loading
                if viewModel.isLoading {
                    LoadingView(message: "正在为你搭配...")
                        .padding(.top, 40)
                } else if isGuest {
                    localRecommendationsSection
                } else {
                    remoteRecommendationsSection
                }

                // Purchase suggestions (remote only)
                if !isGuest && !viewModel.purchaseSuggestions.isEmpty {
                    purchaseSuggestionsSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("每日推荐")
        .refreshable {
            await viewModel.loadTodayRecommendations(isGuest: isGuest, context: modelContext)
        }
        .task {
            await viewModel.loadTodayRecommendations(isGuest: isGuest, context: modelContext)
        }
    }

    // MARK: - Remote Recommendations

    @ViewBuilder
    private var remoteRecommendationsSection: some View {
        if viewModel.recommendations.isEmpty {
            EmptyStateView(
                icon: "sparkles",
                title: "暂无推荐",
                message: "添加更多衣物后将获得每日搭配推荐"
            )
            .padding(.top, 40)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("今日推荐")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                TabView(selection: $currentPage) {
                    ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, rec in
                        OutfitCard(recommendation: rec) {
                            Task { await viewModel.acceptRecommendation(rec) }
                        }
                        .tag(index)
                        .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)
            }
        }
    }

    // MARK: - Local Recommendations

    @ViewBuilder
    private var localRecommendationsSection: some View {
        if viewModel.localSuggestions.isEmpty {
            EmptyStateView(
                icon: "tshirt",
                title: "衣橱还是空的",
                message: "先添加一些衣物，AI 将自动为你搭配"
            )
            .padding(.top, 40)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("今日搭配")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Label("本地生成", systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                TabView(selection: $currentPage) {
                    ForEach(Array(viewModel.localSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                        LocalOutfitCard(suggestion: suggestion)
                            .tag(index)
                            .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 420)
            }
        }
    }

    // MARK: - Purchase Suggestions

    private var purchaseSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("购物建议")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVStack(spacing: 8) {
                ForEach(viewModel.purchaseSuggestions) { suggestion in
                    PurchaseSuggestionRow(suggestion: suggestion)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Local Outfit Card

struct LocalOutfitCard: View {
    let suggestion: OutfitSuggestion
    @State private var liked: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item thumbnails
            if !suggestion.items.isEmpty {
                HStack(spacing: 8) {
                    ForEach(suggestion.items.prefix(4)) { item in
                        itemThumb(item)
                    }
                    if suggestion.items.count > 4 {
                        Text("+\(suggestion.items.count - 4)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)
            }

            Divider()

            // Reason
            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.reason)
                    .font(.subheadline)
                    .lineLimit(3)

                if let tip = suggestion.weatherTip {
                    Label(tip, systemImage: "thermometer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Like button
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) { liked.toggle() }
                } label: {
                    Label(liked ? "已喜欢" : "喜欢", systemImage: liked ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundStyle(liked ? .pink : .secondary)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    @ViewBuilder
    private func itemThumb(_ item: LocalClothingItem) -> some View {
        Group {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        RecommendationView()
    }
    .environment(AuthViewModel())
}
