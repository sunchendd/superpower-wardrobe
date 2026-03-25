import Foundation

// MARK: - Local Outfit Recommendation Engine
//
// Generates outfit recommendations purely from the local wardrobe
// without requiring any backend. Works in guest mode and as fallback.

struct OutfitSuggestion: Identifiable {
    let id: UUID
    let items: [LocalClothingItem]
    let reason: String
    let weatherTip: String?
    let score: Double // 0-1 style coherence estimate
}

enum WeatherCondition {
    case hot          // > 28°C
    case warm         // 20-28°C
    case mild         // 12-20°C
    case cool         // 5-12°C
    case cold         // < 5°C

    init(temperature: Double) {
        switch temperature {
        case 28...: self = .hot
        case 20..<28: self = .warm
        case 12..<20: self = .mild
        case 5..<12: self = .cool
        default: self = .cold
        }
    }

    var preferredSeasons: [String] {
        switch self {
        case .hot: return ["summer", "all"]
        case .warm: return ["summer", "spring", "all"]
        case .mild: return ["spring", "autumn", "all"]
        case .cool: return ["autumn", "winter", "all"]
        case .cold: return ["winter", "all"]
        }
    }

    var layersNeeded: Int {
        switch self {
        case .hot: return 1
        case .warm: return 1
        case .mild: return 2
        case .cool: return 2
        case .cold: return 3
        }
    }

    var tip: String {
        switch self {
        case .hot: return "气温较高，建议穿着清凉透气的夏日单品"
        case .warm: return "天气温暖，轻薄穿搭正合适"
        case .mild: return "温度适中，可搭配薄外套以备不时之需"
        case .cool: return "天气凉爽，记得增加保暖层"
        case .cold: return "气温较低，建议厚外套加多层搭配"
        }
    }
}

final class LocalRecommendationEngine {
    static let shared = LocalRecommendationEngine()
    private init() {}

    // MARK: - Category Constants

    private let topCategories    = ["上衣", "Tops", "衬衫"]
    private let bottomCategories = ["裤子", "Pants", "裙子", "Skirts"]
    private let outerCategories  = ["外套", "Outerwear", "大衣", "夹克"]
    private let shoeCategories   = ["鞋子", "Shoes"]
    private let accessCategories = ["配饰", "Accessories"]

    // MARK: - Main API

    /// Generate up to `count` outfit suggestions from the given wardrobe.
    func generateSuggestions(
        from items: [LocalClothingItem],
        weather: WeatherData? = nil,
        count: Int = 3
    ) -> [OutfitSuggestion] {
        guard !items.isEmpty else { return [] }

        let condition: WeatherCondition?
        if let weather {
            condition = WeatherCondition(temperature: weather.temperature)
        } else {
            condition = nil
        }

        // Filter by preferred season if weather available
        let filteredItems: [LocalClothingItem]
        if let condition {
            filteredItems = items.filter { condition.preferredSeasons.contains($0.season) }
                .nilIfEmpty ?? items
        } else {
            filteredItems = items
        }

        // Group by category
        let tops    = filteredItems.filter { isTop($0) }.shuffled()
        let bottoms = filteredItems.filter { isBottom($0) }.shuffled()
        let outers  = filteredItems.filter { isOuter($0) }.shuffled()
        let shoes   = filteredItems.filter { isShoe($0) }.shuffled()

        var suggestions: [OutfitSuggestion] = []

        // Try to build `count` suggestions
        for i in 0..<count {
            let top    = tops.element(at: i)
            let bottom = bottoms.element(at: i)
            let outer  = (condition?.layersNeeded ?? 2) >= 2 ? outers.element(at: i) : nil
            let shoe   = shoes.element(at: i)

            var outfit: [LocalClothingItem] = []
            if let top    { outfit.append(top) }
            if let bottom { outfit.append(bottom) }
            if let outer  { outfit.append(outer) }
            if let shoe   { outfit.append(shoe) }

            // Fall back: if not enough categories, pick random items
            if outfit.count < 2 {
                outfit = Array(filteredItems.shuffled().prefix(3))
            }

            guard !outfit.isEmpty else { continue }

            let score = coherenceScore(for: outfit)
            let reason = buildReason(items: outfit, condition: condition)
            let weatherTip = condition?.tip

            suggestions.append(OutfitSuggestion(
                id: UUID(),
                items: outfit,
                reason: reason,
                weatherTip: weatherTip,
                score: score
            ))
        }

        // Sort by coherence, best first
        return suggestions.sorted { $0.score > $1.score }
    }

    /// Generate suggestions from Supabase ClothingItems (for online mode fallback).
    func generateSuggestionsFromRemote(
        items: [ClothingItem],
        weather: WeatherData?,
        count: Int = 3
    ) -> [DailyRecommendation] {
        let condition = weather.map { WeatherCondition(temperature: $0.temperature) }
        let preferred = condition?.preferredSeasons ?? ["all", "spring", "summer", "autumn", "winter"]

        let filtered = items.filter { preferred.contains($0.season ?? "all") }
            .nilIfEmpty ?? items

        var recs: [DailyRecommendation] = []
        for _ in 0..<min(count, 5) {
            let subset = Array(filtered.shuffled().prefix(3))
            let tip = condition?.tip ?? "今日搭配推荐"
            let rec = DailyRecommendation(
                id: UUID(),
                userId: subset.first?.userId ?? UUID(),
                date: Date(),
                outfitId: UUID(),
                weatherData: weather.map { "\($0.weatherEmoji) \($0.temperatureFormatted)" },
                reasonText: tip,
                accepted: false,
                feedbackScore: nil
            )
            recs.append(rec)
        }
        return recs
    }

    // MARK: - Category Helpers

    private func isTop(_ item: LocalClothingItem) -> Bool {
        topCategories.contains { item.categoryName?.contains($0) == true }
    }

    private func isBottom(_ item: LocalClothingItem) -> Bool {
        bottomCategories.contains { item.categoryName?.contains($0) == true }
    }

    private func isOuter(_ item: LocalClothingItem) -> Bool {
        outerCategories.contains { item.categoryName?.contains($0) == true }
    }

    private func isShoe(_ item: LocalClothingItem) -> Bool {
        shoeCategories.contains { item.categoryName?.contains($0) == true }
    }

    // MARK: - Scoring

    /// Estimate style coherence (0-1) based on shared style tags and color harmony.
    private func coherenceScore(for items: [LocalClothingItem]) -> Double {
        guard items.count > 1 else { return 1.0 }

        // Shared tags bonus
        let allTags = items.flatMap { $0.styleTags }
        let uniqueTags = Set(allTags)
        let sharedRatio = allTags.isEmpty ? 0.5 : Double(allTags.count - uniqueTags.count) / Double(allTags.count)

        // Color variety bonus (diverse but not clashing)
        let colors = items.compactMap { $0.colorHex }
        let colorScore = colors.count > 3 ? 0.5 : 0.8

        return (sharedRatio * 0.5 + colorScore * 0.5).clamped(to: 0...1)
    }

    // MARK: - Reason Text

    private func buildReason(items: [LocalClothingItem], condition: WeatherCondition?) -> String {
        let names = items.compactMap { $0.name ?? $0.categoryName }.prefix(3).joined(separator: " + ")
        let base = names.isEmpty ? "精心挑选的搭配" : names
        if let tip = condition?.tip {
            return "\(base)｜\(tip)"
        }
        return base
    }
}

// MARK: - Helpers

private extension Collection {
    var nilIfEmpty: Self? { isEmpty ? nil : self }
}

private extension Array {
    func element(at index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
