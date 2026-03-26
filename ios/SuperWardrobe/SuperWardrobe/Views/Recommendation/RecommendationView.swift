import SwiftUI
import SwiftData

struct RecommendationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RecommendationViewModel()
    @State private var currentPage = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weather card
                if let weather = viewModel.weather {
                    WeatherCard(weather: weather)
                        .padding(.horizontal)
                }

                if viewModel.isLoading {
                    LoadingView(message: "正在为你搭配...")
                        .padding(.top, 40)
                } else if viewModel.suggestions.isEmpty {
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
                            if let weather = viewModel.weather {
                                Label(weather.temperatureFormatted, systemImage: "thermometer")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        TabView(selection: $currentPage) {
                            ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                                LocalOutfitCard(suggestion: suggestion)
                                    .tag(index)
                                    .padding(.horizontal)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 380)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("每日推荐")
        .refreshable {
            await viewModel.refresh(context: modelContext)
        }
        .task {
            await viewModel.load(context: modelContext)
        }
    }
}

// MARK: - Local Outfit Card

struct LocalOutfitCard: View {
    let suggestion: OutfitSuggestion
    @State private var liked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Item thumbnails
            if !suggestion.items.isEmpty {
                HStack(spacing: 8) {
                    ForEach(suggestion.items.prefix(4)) { item in
                        itemThumb(item)
                    }
                }
                .frame(height: 90)
            }

            Divider()

            // Reason
            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.reason)
                    .font(.subheadline)
                    .lineLimit(3)

                if let tip = suggestion.weatherTip {
                    Label(tip, systemImage: "cloud.sun")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Like
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) { liked.toggle() }
                } label: {
                    Label(liked ? "喜欢" : "喜欢这套", systemImage: liked ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundStyle(liked ? .pink : .secondary)
                }
                .buttonStyle(.bordered)
                .tint(liked ? .pink : .secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    @ViewBuilder
    private func itemThumb(_ item: ClothingItem) -> some View {
        Group {
            if let img = item.thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(hex: item.color).opacity(0.3)
                    .overlay {
                        Image(systemName: item.categoryIcon ?? "tshirt")
                            .foregroundStyle(Color(hex: item.color))
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack { RecommendationView() }
}
