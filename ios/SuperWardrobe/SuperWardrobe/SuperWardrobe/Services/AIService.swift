import Foundation
#if os(iOS)
import UIKit

struct ClothingClassification: Codable {
    let category: String
    let color: String
    let style: [String]
    let confidence: Double
}

struct AIOutfitSuggestion: Codable {
    let themeName: String
    let clothingIds: [String]
    let reason: String
    let occasion: String
}

final class AIService {
    static let shared = AIService()

    private let apiKeyDefault = "ai_api_key"
    private let vlURL = "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation"
    private let textURL = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: apiKeyDefault) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyDefault) }
    }

    var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Clothing Image Classification (Qwen VL)

    func classifyClothing(_ image: UIImage) async throws -> ClothingClassification {
        guard isConfigured else { throw AIError.noAPIKey }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { throw AIError.invalidImage }

        let base64 = imageData.base64EncodedString()
        let prompt = """
        请仔细分析这张衣物图片，严格按以下JSON格式返回，不要包含任何其他文字：
        {
          "category": "衣物主类别（上衣/裤子/裙子/外套/鞋子/包/配饰/内衣/运动服，选其一）",
          "color": "主要颜色的十六进制色值（例如 #3A5F8B）",
          "style": ["风格标签1", "风格标签2"],
          "confidence": 0.95
        }
        style 从以下选择1-3个：休闲、正式、运动、街头、复古、简约、甜美、中性、商务、潮流
        """

        let body: [String: Any] = [
            "model": "qwen-vl-plus",
            "input": [
                "messages": [[
                    "role": "user",
                    "content": [
                        ["image": "data:image/jpeg;base64,\(base64)"],
                        ["text": prompt]
                    ]
                ]]
            ]
        ]

        let data = try await postJSON(url: vlURL, body: body)

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let output = json["output"] as? [String: Any],
            let choices = output["choices"] as? [[String: Any]],
            let content = choices.first?["message"] as? [String: Any],
            let parts = content["content"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else { throw AIError.invalidResponse }

        return try decodeJSON(from: extractObject(text), as: ClothingClassification.self)
    }

    // MARK: - Daily Outfit Recommendations (Qwen Text)

    func generateOutfitRecommendations(wardrobe: [ClothingItem], weather: WeatherData?, stylePreferences: [String] = []) async throws -> [AIOutfitSuggestion] {
        guard isConfigured else { throw AIError.noAPIKey }

        let wardrobeDesc = wardrobe.prefix(30).map { item in
            "ID:\(item.id.uuidString) | \(item.name ?? "未命名") | 颜色:\(item.color) | 季节:\(item.season ?? "四季") | 风格:\(item.styleTags.prefix(3).joined(separator: ","))"
        }.joined(separator: "\n")

        let weatherDesc: String
        if let w = weather {
            weatherDesc = "天气:\(w.description)，温度:\(Int(w.temperature))°C，湿度:\(Int(w.humidity))%"
        } else {
            weatherDesc = "天气信息暂不可用，请按当前季节推荐"
        }

        var userMessage = """
        我的衣橱：
        \(wardrobeDesc.isEmpty ? "暂无衣物" : wardrobeDesc)

        今日\(weatherDesc)

        请为我推荐2套今日搭配方案。严格只返回JSON数组，不加任何说明文字：
        [
          {
            "themeName": "主题名称（4字以内）",
            "clothingIds": ["从衣橱中选2-3件衣物的UUID"],
            "reason": "推荐理由，结合天气和场合（30字以内）",
            "occasion": "适合场合（如：日常/通勤/休闲/运动）"
          }
        ]
        """
        if !stylePreferences.isEmpty {
            userMessage += "\n用户偏好风格：\(stylePreferences.joined(separator: "、"))"
        }
        let userPrompt = userMessage

        let body: [String: Any] = [
            "model": "qwen-turbo",
            "input": [
                "messages": [
                    ["role": "system", "content": "你是专业穿搭顾问，根据用户衣橱和天气推荐搭配方案。"],
                    ["role": "user", "content": userPrompt]
                ]
            ]
        ]

        let data = try await postJSON(url: textURL, body: body)

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let output = json["output"] as? [String: Any],
            let choices = output["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw AIError.invalidResponse }

        return try decodeJSON(from: extractArray(content), as: [AIOutfitSuggestion].self)
    }

    // MARK: - Helpers

    private func postJSON(url: String, body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = (json["error"] as? [String: Any])?["message"] as? String {
                throw AIError.apiError(msg)
            }
            throw AIError.apiError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        return data
    }

    private func decodeJSON<T: Decodable>(from text: String, as type: T.Type) throws -> T {
        guard let jsonData = text.data(using: .utf8),
              let result = try? JSONDecoder().decode(type, from: jsonData)
        else { throw AIError.invalidResponse }
        return result
    }

    private func extractObject(_ text: String) -> String {
        guard let start = text.range(of: "{"),
              let end = text.range(of: "}", options: .backwards) else { return "{}" }
        return String(text[start.lowerBound...end.lowerBound])
    }

    private func extractArray(_ text: String) -> String {
        guard let start = text.range(of: "["),
              let end = text.range(of: "]", options: .backwards) else { return "[]" }
        return String(text[start.lowerBound...end.lowerBound])
    }
}

enum AIError: LocalizedError {
    case noAPIKey
    case invalidImage
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey:         return "请先在「个人设置 → AI 配置」填入千问 API Key"
        case .invalidImage:     return "无法处理该图片"
        case .apiError(let m): return "AI 请求失败：\(m)"
        case .invalidResponse:  return "AI 返回数据解析失败，请重试"
        }
    }
}
#endif
