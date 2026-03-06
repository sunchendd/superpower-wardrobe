import SwiftUI

struct RecommendationView: View {
    @State private var viewModel = RecommendationViewModel()
    @State private var currentPage = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let weather = viewModel.weather {
                    WeatherCard(weather: weather)
                        .padding(.horizontal)
                }

                if viewModel.isLoading {
                    LoadingView(message: "正在为你搭配...")
                } else if viewModel.recommendations.isEmpty {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "暂无推荐",
                        message: "添加更多衣物后将获得每日搭配推荐"
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今日推荐")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        TabView(selection: $currentPage) {
                            ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, rec in
                                OutfitCard(recommendation: rec) {
                                    Task {
                                        await viewModel.acceptRecommendation(rec)
                                    }
                                }
                                .tag(index)
                                .padding(.horizontal)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 400)
                    }
                }

                if !viewModel.purchaseSuggestions.isEmpty {
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
            .padding(.vertical)
        }
        .navigationTitle("每日推荐")
        .refreshable {
            await viewModel.loadTodayRecommendations()
        }
        .task {
            await viewModel.loadTodayRecommendations()
        }
    }
}

#Preview {
    NavigationStack {
        RecommendationView()
    }
}
