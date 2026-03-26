import SwiftUI

struct CategoryPieChart: View {
    let data: [CategoryStat]
    @Environment(\.themeTokens) private var theme

    private var total: Int {
        data.reduce(0) { $0 + $1.count }
    }

    private var rows: [(stat: CategoryStat, progress: Double)] {
        data.map { stat in
            let progress = Double(stat.count) / Double(max(total, 1))
            return (stat, progress)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: row.stat.color))
                                .frame(width: 10, height: 10)
                            Text(row.stat.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.text)
                        }

                        Spacer()

                        Text("\(row.stat.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.text)

                        Text("\(Int((row.progress * 100).rounded()))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.textMuted)
                            .padding(.leading, 2)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.cardBorder)
                                .frame(height: 8)

                            Capsule()
                                .fill(Color(hex: row.stat.color))
                                .frame(width: max(12, proxy.size.width * row.progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }

            HStack {
                Text("总计")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textMuted)
                Spacer()
                Text("\(total) 件")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.text)
            }
            .padding(.top, 2)
        }
    }
}

#Preview {
    CategoryPieChart(data: [
        CategoryStat(name: "上衣", count: 15, color: "#BE185D"),
        CategoryStat(name: "裤子", count: 10, color: "#0369A1"),
        CategoryStat(name: "外套", count: 7, color: "#15803D"),
        CategoryStat(name: "配饰", count: 5, color: "#7C3AED"),
    ])
    .padding()
    .background(Color.black)
}
