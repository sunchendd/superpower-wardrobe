import Foundation
import UIKit

// MARK: - AI Classification Result

struct AIClassificationResult {
    let category: String       // 上衣 / 裤子 / 裙子 / 外套 / 鞋子 / 配饰
    let colorHex: String       // e.g. "#FFFFFF"
    let styleTags: [String]    // e.g. ["休闲", "简约"]
    let season: String         // spring / summer / autumn / winter / all
    let confidence: Double     // 0-1
    let description: String    // 简短中文描述
}

// MARK: - AI Provider

enum AIProvider: String, CaseIterable, Identifiable {
    case qwen     = "通义千问（推荐·支持识图）"
    case deepseek = "DeepSeek（仅文字推荐）"

    var id: String { rawValue }

    var defaultBaseURL: String {
        switch self {
        case .qwen:     return "https://dashscope.aliyuncs.com/compatible-mode/v1"
        case .deepseek: return "https://api.deepseek.com/v1"
        }
    }

    var visionModel: String {
        switch self {
        case .qwen:     return "qwen-vl-plus"   // 支持图片
        case .deepseek: return ""               // 不支持视觉
        }
    }

    var textModel: String {
        switch self {
        case .qwen:     return "qwen-plus"
        case .deepseek: return "deepseek-chat"
        }
    }

    var supportsVision: Bool {
        switch self {
        case .qwen:     return true
        case .deepseek: return false
        }
    }

    var registrationURL: String {
        switch self {
        case .qwen:     return "https://bailian.console.aliyun.com/"
        case .deepseek: return "https://platform.deepseek.com"
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .qwen:     return "sk-..."
        case .deepseek: return "sk-..."
        }
    }

    var freeQuota: String {
        switch self {
        case .qwen:     return "免费额度：每月 100 万 tokens"
        case .deepseek: return "按量付费，价格极低"
        }
    }
}

// MARK: - Chat Request Models

private struct ChatMessage: Encodable {
    let role: String
    let content: [ContentPart]
}

private enum ContentPart: Encodable {
    case text(String)
    case imageURL(String)

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let str):
            try c.encode("text", forKey: .type)
            try c.encode(str, forKey: .text)
        case .imageURL(let url):
            try c.encode("image_url", forKey: .type)
            try c.encode(ImageURLWrapper(url: url), forKey: .imageUrl)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }

    private struct ImageURLWrapper: Encodable {
        let url: String
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int
    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

private struct ChatResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable {
        let message: Msg
    }
    struct Msg: Decodable {
        let content: String
    }
}

// MARK: - AI Service

/// Unified AI service supporting 通义千问 (vision + text) and DeepSeek (text only).
/// Users configure their own API key in Settings → AI 功能.
@Observable
final class AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - Persisted settings

    var selectedProvider: AIProvider {
        get {
            let raw = UserDefaults.standard.string(forKey: "ai_provider") ?? AIProvider.qwen.rawValue
            return AIProvider(rawValue: raw) ?? .qwen
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "ai_provider") }
    }

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "ai_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "ai_api_key") }
    }

    var isConfigured: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Image Classification (vision required)

    func classifyClothing(image: UIImage) async throws -> AIClassificationResult {
        guard isConfigured else { throw AIError.notConfigured }
        guard selectedProvider.supportsVision else { throw AIError.visionNotSupported(selectedProvider) }

        guard let data = LocalDataService.compressImage(image, maxDimension: 512, quality: 0.7) else {
            throw AIError.imageEncodingFailed
        }
        let dataURL = "data:image/jpeg;base64,\(data.base64EncodedString())"

        let prompt = """
        分析这件衣物图片，仅以 JSON 格式返回（不要任何其他内容）：
        {
          "category": "上衣|裤子|裙子|外套|鞋子|配饰",
          "color_hex": "#RRGGBB",
          "style_tags": ["标签1","标签2"],
          "season": "spring|summer|autumn|winter|all",
          "confidence": 0.0-1.0,
          "description": "简短中文描述（10字以内）"
        }
        style_tags 从以下选1-3个：休闲、商务、运动、日系、欧美、简约、复古、街头、优雅、度假
        """

        let response = try await call(
            model: selectedProvider.visionModel,
            content: [.text(prompt), .imageURL(dataURL)]
        )
        return parseClassification(response)
    }

    // MARK: - Text Recommendation

    func generateRecommendationReason(
        itemNames: [String],
        temperature: Double?,
        weatherCondition: String?
    ) async throws -> String {
        guard isConfigured else { return "今日精选搭配" }

        let items = itemNames.prefix(4).joined(separator: "、")
        var ctx = ""
        if let temp = temperature, let cond = weatherCondition {
            ctx = "天气：\(cond)，\(Int(temp))°C。"
        }

        let prompt = "\(ctx)搭配：\(items)。用一句话（20字内）点评这套搭配，语气时尚轻松。只返回那句话。"

        return try await call(model: selectedProvider.textModel, content: [.text(prompt)])
    }

    // MARK: - Test Connection

    func testConnection() async -> Bool {
        do {
            let r = try await call(model: selectedProvider.textModel, content: [.text("回复 OK")])
            return r.lowercased().contains("ok")
        } catch {
            return false
        }
    }

    // MARK: - Private

    private func call(model: String, content: [ContentPart]) async throws -> String {
        let baseURL = selectedProvider.defaultBaseURL
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.networkError
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30

        let body = ChatRequest(
            model: model,
            messages: [ChatMessage(role: "user", content: content)],
            maxTokens: 512
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AIError.networkError }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw AIError.apiError("HTTP \(http.statusCode): \(msg.prefix(200))")
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func parseClassification(_ json: String) -> AIClassificationResult {
        var cleaned = json
        // Strip markdown fences
        if cleaned.hasPrefix("```") { cleaned = cleaned.components(separatedBy: "\n").dropFirst().joined(separator: "\n") }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        if let s = cleaned.range(of: "{"), let e = cleaned.range(of: "}", options: .backwards) {
            cleaned = String(cleaned[s.lowerBound...e.upperBound])
        }

        guard
            let data = cleaned.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return AIClassificationResult(category: "上衣", colorHex: "#808080", styleTags: [],
                                          season: "all", confidence: 0.5, description: "")
        }

        return AIClassificationResult(
            category:    obj["category"]    as? String   ?? "上衣",
            colorHex:    obj["color_hex"]   as? String   ?? "#808080",
            styleTags:   obj["style_tags"]  as? [String] ?? [],
            season:      obj["season"]      as? String   ?? "all",
            confidence:  obj["confidence"]  as? Double   ?? 0.7,
            description: obj["description"] as? String   ?? ""
        )
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case notConfigured
    case visionNotSupported(AIProvider)
    case imageEncodingFailed
    case networkError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "请先在「设置 → AI 功能」中配置 API Key"
        case .visionNotSupported(let p):
            return "\(p.rawValue) 不支持图片识别，请切换到「通义千问」"
        case .imageEncodingFailed:
            return "图片处理失败"
        case .networkError:
            return "网络错误，请检查网络连接"
        case .apiError(let msg):
            return "API 错误：\(msg)"
        }
    }
}
