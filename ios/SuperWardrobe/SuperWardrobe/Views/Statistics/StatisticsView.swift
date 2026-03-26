import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeTokens) private var theme
    @State private var viewModel = StatisticsViewModel()

    private var topIdleItems: [UtilizationItem] {
        Array(viewModel.utilizationRanking.sorted { $0.wearCount < $1.wearCount }.prefix(4))
    }

    private var avgPrice: Double {
        guard viewModel.totalItems > 0 else { return 0 }
        return viewModel.totalSpending / Double(viewModel.totalItems)
    }

    private var activeRate: Double {
        guard viewModel.totalItems > 0 else { return 0 }
        let active = max(0, viewModel.totalItems - idleCountEstimate)
        return Double(active) / Double(viewModel.totalItems)
    }

    private var idleCountEstimate: Int {
        viewModel.utilizationRanking.filter { $0.wearCount == 0 }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroHeader
                kpiGrid

                if viewModel.totalItems == 0 && !viewModel.isLoading {
                    premiumEmptyState
                } else {
                    sectionCard(title: "品类分布", subtitle: "按件数拆解你的衣橱") {
                        CategoryPieChart(data: viewModel.categoryDistribution)
                    }

                    sectionCard(title: "久未穿", subtitle: "优先把沉睡单品重新激活") {
                        UtilizationRanking(items: topIdleItems)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(theme.background.ignoresSafeArea())
        .refreshable { viewModel.loadStatistics(context: modelContext) }
        .task { viewModel.loadStatistics(context: modelContext) }
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "统计中...")
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("洞察")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.text)
                        .tracking(-1.1)

                    Text("了解你的穿着习惯")
                        .font(.subheadline)
                        .foregroundStyle(theme.textMuted)
                }

                Spacer()

                Text("\(viewModel.totalItems) 件")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
            }

            HStack(spacing: 10) {
                metricCard(title: "利用率", value: rateString(activeRate), tint: .green)
                metricCard(title: "均价", value: viewModel.totalItems > 0 ? avgPrice.currencyFormatted : "¥0", tint: .orange)
                metricCard(title: "未穿", value: "\(idleCountEstimate)", tint: .pink)
            }
        }
    }

    private var kpiGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            kpiCard(title: "总衣物", value: "\(viewModel.totalItems)", icon: "tshirt", tint: theme.accent)
            kpiCard(title: "品类", value: "\(viewModel.categoryDistribution.count)", icon: "square.grid.2x2", tint: .cyan)
            kpiCard(title: "最常穿", value: "\(viewModel.utilizationRanking.first?.wearCount ?? 0)", icon: "repeat", tint: .yellow)
        }
    }

    private func kpiCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.headline)
                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(theme.text)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }

    private func metricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .tracking(1)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.text)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tint.opacity(0.28), lineWidth: 1))
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(theme.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.textMuted)
            }

            content()
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }

    private var premiumEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(theme.accent)
                .padding(18)
                .background(theme.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(theme.cardBorder, lineWidth: 1))

            Text("暂无数据")
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.text)

            Text("先添加几件衣物，统计面板就会自动出现品类和穿着洞察。")
                .font(.subheadline)
                .foregroundStyle(theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
    }

    private func rateString(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

#Preview {
    NavigationStack { StatisticsView() }
}
