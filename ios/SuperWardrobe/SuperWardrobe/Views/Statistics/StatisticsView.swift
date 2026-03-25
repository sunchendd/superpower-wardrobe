import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = StatisticsViewModel()

    private var isGuest: Bool { authViewModel.isGuestMode }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary cards
                HStack(spacing: 16) {
                    StatCard(
                        title: "总衣物",
                        value: "\(viewModel.totalItems)",
                        icon: "tshirt",
                        color: .indigo
                    )
                    StatCard(
                        title: "总花费",
                        value: viewModel.totalSpending.currencyFormatted,
                        icon: "yensign.circle",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                // Category distribution
                if !viewModel.categoryDistribution.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("品类分布")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        CategoryPieChart(data: viewModel.categoryDistribution)
                            .frame(height: 260)
                            .padding(.horizontal)
                    }
                }

                // Color distribution
                if !viewModel.colorDistribution.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("颜色分布")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ColorDistributionChart(data: viewModel.colorDistribution)
                            .padding(.horizontal)
                    }
                }

                // Utilization ranking
                if !viewModel.utilizationRanking.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("穿着排行")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        UtilizationRanking(items: viewModel.utilizationRanking)
                            .padding(.horizontal)
                    }
                }

                // Empty state
                if viewModel.totalItems == 0 && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "chart.pie",
                        title: "暂无数据",
                        message: "添加衣物后即可查看统计分析"
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("衣橱统计")
        .refreshable {
            await loadStats()
        }
        .task {
            await loadStats()
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "统计中...")
            }
        }
    }

    private func loadStats() async {
        if isGuest {
            viewModel.loadLocalStatistics(context: modelContext)
        } else {
            await viewModel.loadStatistics()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
    .environment(AuthViewModel())
}
