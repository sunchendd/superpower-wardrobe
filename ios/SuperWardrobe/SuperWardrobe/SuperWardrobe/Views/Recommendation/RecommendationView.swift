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

                if viewModel.isLoading || viewModel.isGenerating {
                    LoadingView(message: viewModel.isGenerating ? "AI 正在生成搭配..." : "加载中...")
                        .padding(.top, 40)
                } else if viewModel.recommendations.isEmpty {
                    emptyStateView
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今日推荐")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        TabView(selection: $currentPage) {
                            ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, rec in
                                OutfitCard(
                                    recommendation: rec,
                                    wardrobeItems: viewModel.wardrobe,
                                    onAccept: { Task { await viewModel.acceptRecommendation(rec) } },
                                    onRate: { rating in viewModel.rateRecommendation(id: rec.id, rating: rating) }
                                )
                                .tag(index)
                                .padding(.horizontal)
                            }
                        }
                        #if os(iOS)
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        #endif
                        .frame(height: 420)
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.refreshRecommendations() }
                } label: {
                    Image(systemName: "arrow.clockwise.circle")
                }
                .disabled(viewModel.isLoading || viewModel.isGenerating)
            }
        }
        .refreshable {
            await viewModel.refreshRecommendations()
        }
        .task {
            await viewModel.loadTodayRecommendations()
        }
        .alert("错误", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.indigo.opacity(0.5))
                .padding(.top, 40)

            if !AIService.shared.isConfigured {
                Text("请先配置 AI")
                    .font(.title3).fontWeight(.semibold)
                Text("前往「我的 → 个人设置 → AI 配置」填入千问 API Key，即可自动生成每日穿搭推荐")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                NavigationLink {
                    SettingsView()
                } label: {
                    Text("去配置")
                        .font(.headline)
                        .padding(.horizontal, 28).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent).tint(.indigo)
            } else if LocalDataService.shared.fetchClothingItems().isEmpty {
                Text("衣橱还是空的")
                    .font(.title3).fontWeight(.semibold)
                Text("先去「衣橱」添加几件衣物，AI 就能为你生成每日穿搭推荐")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("暂无今日推荐")
                    .font(.title3).fontWeight(.semibold)
                Text("点击右上角刷新按钮，AI 将为你生成今日专属搭配")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button {
                    Task { await viewModel.refreshRecommendations() }
                } label: {
                    Label("立即生成", systemImage: "sparkles")
                        .font(.headline)
                        .padding(.horizontal, 28).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent).tint(.indigo)
            }
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    NavigationStack {
        RecommendationView()
    }
}
