import SwiftUI

struct OutfitCard: View {
    let recommendation: DailyRecommendation
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "tshirt")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                    Text("搭配方案")
                        .font(.headline)
                    Spacer()
                    if recommendation.accepted == true {
                        Label("已采纳", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                if let reason = recommendation.reasonText {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }

            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
                .frame(height: 200)
                .overlay {
                    VStack {
                        Image(systemName: "hanger")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("搭配预览")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            if recommendation.accepted != true {
                Button(action: onAccept) {
                    Text("穿这套")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }

            HStack(spacing: 20) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        // rating action handled by parent
                    } label: {
                        Image(systemName: score <= (recommendation.feedbackScore ?? 0) ? "star.fill" : "star")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

#Preview {
    OutfitCard(
        recommendation: DailyRecommendation(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            outfitId: nil,
            weatherData: nil,
            reasonText: "天气晴朗，温度适中，推荐轻薄的春季搭配",
            accepted: false,
            feedbackScore: 3
        ),
        onAccept: {}
    )
    .padding()
}
