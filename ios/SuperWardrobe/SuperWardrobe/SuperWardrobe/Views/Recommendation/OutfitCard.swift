import SwiftUI
import Kingfisher

struct OutfitCard: View {
    let recommendation: DailyRecommendation
    let wardrobeItems: [ClothingItem]
    let onAccept: () -> Void
    let onRate: (Int) -> Void

    @State private var currentRating = 0

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

            // Outfit item thumbnails
            let outfitItems = recommendation.clothingIds.compactMap { idStr -> ClothingItem? in
                guard let uuid = UUID(uuidString: idStr) else { return nil }
                return wardrobeItems.first { $0.id == uuid }
            }

            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
                .frame(height: 120)
                .overlay {
                    if outfitItems.isEmpty {
                        VStack {
                            Image(systemName: "hanger")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("搭配预览")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(spacing: 8) {
                            ForEach(Array(outfitItems.prefix(3)), id: \.id) { clothingItem in
                                if let urlStr = clothingItem.imageUrl, let url = URL(string: urlStr) {
                                    KFImage(url)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                }
                            }
                        }
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
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= currentRating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            currentRating = star
                            onRate(star)
                        }
                }
            }
        }
        .padding(20)
        .cardStyle()
        .onAppear {
            currentRating = recommendation.rating
        }
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
        wardrobeItems: [],
        onAccept: {},
        onRate: { _ in }
    )
    .padding()
}
