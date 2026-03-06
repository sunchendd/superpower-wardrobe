import SwiftUI

struct ColorDistributionChart: View {
    let data: [ColorStat]

    private var maxCount: Int {
        data.map(\.count).max() ?? 1
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(data.prefix(10)) { stat in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: stat.color))
                        .frame(width: 20, height: 20)
                        .overlay {
                            Circle().stroke(.gray.opacity(0.3), lineWidth: 1)
                        }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.gray.opacity(0.1))
                                .frame(height: 20)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: stat.color).opacity(0.7))
                                .frame(
                                    width: max(geo.size.width * CGFloat(stat.count) / CGFloat(maxCount), 20),
                                    height: 20
                                )
                        }
                    }
                    .frame(height: 20)

                    Text("\(stat.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    ColorDistributionChart(data: [
        ColorStat(color: "#000000", count: 12),
        ColorStat(color: "#FFFFFF", count: 8),
        ColorStat(color: "#0000FF", count: 6),
        ColorStat(color: "#FF0000", count: 4),
        ColorStat(color: "#808080", count: 3),
    ])
    .padding()
}
