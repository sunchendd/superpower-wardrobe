import SwiftUI

struct CategoryPieChart: View {
    let data: [CategoryStat]

    private var total: Int {
        data.reduce(0) { $0 + $1.count }
    }

    private var slices: [(stat: CategoryStat, startAngle: Double, endAngle: Double)] {
        var currentAngle: Double = -90
        return data.map { stat in
            let proportion = Double(stat.count) / Double(max(total, 1))
            let sweep = proportion * 360
            let start = currentAngle
            currentAngle += sweep
            return (stat, start, currentAngle)
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                ForEach(Array(slices.enumerated()), id: \.offset) { _, slice in
                    PieSlice(
                        startAngle: .degrees(slice.startAngle),
                        endAngle: .degrees(slice.endAngle)
                    )
                    .fill(Color(hex: slice.stat.color))
                }

                Circle()
                    .fill(.background)
                    .frame(width: 80, height: 80)

                VStack(spacing: 2) {
                    Text("\(total)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(data) { stat in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: stat.color))
                            .frame(width: 10, height: 10)
                        Text(stat.name)
                            .font(.caption)
                        Spacer()
                        Text("\(stat.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

#Preview {
    CategoryPieChart(data: [
        CategoryStat(name: "上衣", count: 15, color: "#FF6B6B"),
        CategoryStat(name: "裤子", count: 10, color: "#4ECDC4"),
        CategoryStat(name: "裙子", count: 5, color: "#45B7D1"),
        CategoryStat(name: "外套", count: 8, color: "#96CEB4"),
    ])
    .padding()
}
