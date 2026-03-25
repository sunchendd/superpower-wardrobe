import Foundation
import UIKit

// MARK: - AI Response Models

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [Message]
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }

    struct Message: Encodable {
        let role: String
        let content: [ContentPart]
    }

    enum ContentPart: Encodable {
        case text(String)
        case imageUrl(String)

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let str):
                try container.encode("text", forKey: .type)
                try container.encode(str, forKey: .text)
            case .imageUrl(let url):
                try container.encode("image_url", forKey: .type)
                try container.encode(["url": url], forKey: .imageUrl)
            }
        }

        enum CodingKeys: String, CodingKey {
            case type, text
            case imageUrl = "image_url"
        }
    }
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }
    struct Message: Decodable {
        let content: String
    }
}

// MARK: - AI Classification Result

struct AIClassificationResult {
    let category: String       // 上衣 / 裤子 / 裙子 / 外套 / 鞋子 / 配饰
    let color: String          // hex color e.g. #FFFFFF
    let styleTags: [String]    // e.g. ["休闲", "简约"]
    let season: String         // spring / summer / autumn / winter / all
    let confidence: Double     // 0-1
    let description: String    // human-readable description
}

// MARK: - AI Service

/// Calls DeepSeek (OpenAI-compatible) API for clothing classification and recommendations.
/// Users configure their own API key in Settings → AI 功能.
@Observable
final class AIService {
    static let shared = AIService()

    private let apiKeyKey = "deepseek_api_key"
    private let baseURLKey = "deepseek_base_url"

    // MARK: - State

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: apiKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyKey) }
    }

    var baseURL: String {
        get { UserDefaults.standard.string(forKey: baseURLKey) ?? "https://api.deepseek.com" }
        set { UserDefaults.standard.set(newValue, forKey: baseURLKey) }
    }

    var isConfigured: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Image Classification

    /// Classify a clothing image and return category, color, style tags etc.
    func classifyClothing(image: UIImage) async throws -> AIClassificationResult {
        guard isConfigured else { throw AIError.notConfigured }

        guard let imageData = LocalDataService.compressImage(image, maxDimension: 512, quality: 0.7) else {
            throw AIError.imageEncodingFailed
        }
        let base64 = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64)"

        let prompt = """
        请分析这张服装图片，以 JSON 格式返回以下信息（只返回 JSON，不要额外说明）：
        {
          "category": "上衣|裤子|裙子|外套|鞋子|配饰",
          "color_hex": "#RRGGBB（主要颜色的十六进制）",
          "style_tags": ["标签1", "标签2"],
          "season": "spring|summer|autumn|winter|all",
          "confidence": 0.0-1.0,
          "description": "简短描述（中文，15字以内）"
        }
        style_tags 从以下选取1-3个：休闲、商务、运动、日系、欧美、简约、复古、街头、优雅、度假
        """

        let responseText = try await callAPI(
            userContent: [.text(prompt), .imageUrl(dataURL)],
            model: "deepseek-chat"
        )

        return parseClassificationResult(from: responseText)
    }

    /// Generate a natural-language outfit recommendation based on weather and wardrobe items.
    func generateRecommendationReason(
        items: [LocalClothingItem],
        temperature: Double?,
        weatherCondition: String?
    ) async throws -> String {
        guard isConfigured else { return "智能推荐（需配置 AI Key）" }

        let itemDesc = items.prefix(4).map {
            "\($0.categoryName ?? "衣物")\($0.name.map { "（\($0)）" } ?? "")"
        }.joined(separator: "、")

        var weatherInfo = ""
        if let temp = temperature, let cond = weatherCondition {
            weatherInfo = "当前天气：\(cond)，气温 \(Int(temp))°C。"
        }

        let prompt = """
        \(weatherInfo)
        用户今天选择了以下搭配：\(itemDesc)。
        请用一句简洁、时尚的中文（20字以内）点评这套搭配，给出穿搭建议或心情语句。
        只返回那一句话，不要任何其他内容。
        """

        return try await callAPI(userContent: [.text(prompt)], model: "deepseek-chat")
    }

    /// Test that the API key is valid.
    func testConnection() async -> Bool {
        do {
            let result = try await callAPI(userContent: [.text("你好，请回复'OK'")], model: "deepseek-chat")
            return result.lowercased().contains("ok")
        } catch {
            return false
        }
    }

    // MARK: - Private

    private func callAPI(userContent: [ChatCompletionRequest.ContentPart], model: String) async throws -> String {
        let url = URL(string: "\(baseURL)/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "user", content: userContent)
            ],
            maxTokens: 512
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIError.networkError }
        guard http.statusCode == 200 else { throw AIError.apiError("HTTP \(http.statusCode)") }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func parseClassificationResult(from json: String) -> AIClassificationResult {
        // Strip markdown code fences if present
        var cleaned = json
        if let start = cleaned.range(of: "{"), let end = cleaned.range(of: "}", options: .backwards) {
            cleaned = String(cleaned[start.lowerBound...end.upperBound])
        }

        guard
            let data = cleaned.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return AIClassificationResult(
                category: "上衣", color: "#808080", styleTags: [],
                season: "all", confidence: 0.5, description: "无法解析"
            )
        }

        return AIClassificationResult(
            category: obj["category"] as? String ?? "上衣",
            color: obj["color_hex"] as? String ?? "#808080",
            styleTags: obj["style_tags"] as? [String] ?? [],
            season: obj["season"] as? String ?? "all",
            confidence: obj["confidence"] as? Double ?? 0.7,
            description: obj["description"] as? String ?? ""
        )
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case notConfigured
    case imageEncodingFailed
    case networkError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "请先在「设置 → AI 功能」中配置 DeepSeek API Key"
        case .imageEncodingFailed:
            return "图片处理失败"
        case .networkError:
            return "网络错误，请检查网络连接"
        case .apiError(let msg):
            return "API 错误：\(msg)"
        }
    }
}
