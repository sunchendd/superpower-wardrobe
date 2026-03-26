import Foundation
import Observation
import UIKit

@Observable
final class QwenVLService {
    static let shared = QwenVLService()

    private enum Constants {
        static let apiKeyAccount = "qwen_vl_api_key"
        static let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"
        static let modelName = "qwen-vl-plus"
    }

    enum QwenVLServiceError: LocalizedError {
        case notConfigured
        case invalidRequest
        case invalidResponse
        case emptyResponse
        case httpStatus(Int, String)
        case transport(Error)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Qwen VL is not configured"
            case .invalidRequest:
                return "Unable to build Qwen VL request"
            case .invalidResponse:
                return "Invalid Qwen VL response"
            case .emptyResponse:
                return "Qwen VL returned an empty response"
            case .httpStatus(let status, let body):
                return "Qwen VL HTTP \(status): \(body)"
            case .transport(let error):
                return error.localizedDescription
            }
        }
    }

    private struct ChatMessage: Encodable {
        let role: String
        let content: [ContentPart]
    }

    private enum ContentPart: Encodable {
        case text(String)
        case imageURL(String)

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let value):
                try container.encode("text", forKey: .type)
                try container.encode(value, forKey: .text)
            case .imageURL(let url):
                try container.encode("image_url", forKey: .type)
                try container.encode(ImageURLPayload(url: url), forKey: .imageURL)
            }
        }

        enum CodingKeys: String, CodingKey {
            case type, text
            case imageURL = "image_url"
        }

        private struct ImageURLPayload: Encodable {
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
            let message: Message
        }

        struct Message: Decodable {
            let content: String
        }
    }

    private let keychain = KeychainService.shared

    private init() {}

    var apiKey: String {
        get {
            (try? keychain.load(for: Constants.apiKeyAccount)) ?? ""
        }
        set {
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try? keychain.delete(for: Constants.apiKeyAccount)
            } else {
                try? keychain.save(newValue, for: Constants.apiKeyAccount)
            }
        }
    }

    var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func classifyClothing(image: UIImage) async throws -> AIClassificationResult {
        guard isConfigured else { throw QwenVLServiceError.notConfigured }
        guard let imageData = LocalDataService.compressImage(image, maxDimension: 768, quality: 0.75) else {
            throw QwenVLServiceError.invalidRequest
        }

        let prompt = """
        请分析图片中的衣物，仅返回 JSON：
        {
          "category": "上衣|裤子|裙子|外套|鞋子|配饰",
          "color_hex": "#RRGGBB",
          "style_tags": ["休闲","简约"],
          "season": "spring|summer|autumn|winter|all",
          "confidence": 0.0-1.0,
          "description": "简短中文描述"
        }
        """

        let response = try await performChat(
            content: [
                .text(prompt),
                .imageURL("data:image/jpeg;base64,\(imageData.base64EncodedString())")
            ],
            maxTokens: 512
        )

        return parseClassificationResult(from: response)
    }

    func generateReason(
        itemNames: [String],
        temperature: Double? = nil,
        weatherCondition: String? = nil
    ) async throws -> String {
        guard isConfigured else { throw QwenVLServiceError.notConfigured }

        let items = itemNames.prefix(4).joined(separator: "、")
        let weatherText: String
        if let temperature, let weatherCondition {
            weatherText = "天气：\(weatherCondition)，\(Int(temperature))°C。"
        } else {
            weatherText = ""
        }

        let prompt = "\(weatherText)搭配：\(items)。请用一句话点评，20字以内，只返回点评文本。"
        let response = try await performChat(content: [.text(prompt)], maxTokens: 128)
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func testAPI() async throws -> Bool {
        guard isConfigured else { throw QwenVLServiceError.notConfigured }
        let response = try await performChat(content: [.text("回复 OK")], maxTokens: 16)
        return response.localizedCaseInsensitiveContains("ok")
    }

    private func performChat(content: [ContentPart], maxTokens: Int) async throws -> String {
        guard let url = URL(string: "\(Constants.baseURL)/chat/completions") else {
            throw QwenVLServiceError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONEncoder().encode(
                ChatRequest(
                    model: Constants.modelName,
                    messages: [ChatMessage(role: "user", content: content)],
                    maxTokens: maxTokens
                )
            )
        } catch {
            throw QwenVLServiceError.invalidRequest
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw QwenVLServiceError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw QwenVLServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw QwenVLServiceError.httpStatus(http.statusCode, String(body.prefix(300)))
        }

        do {
            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            let text = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else { throw QwenVLServiceError.emptyResponse }
            return text
        } catch let error as QwenVLServiceError {
            throw error
        } catch {
            throw QwenVLServiceError.invalidResponse
        }
    }

    private func parseClassificationResult(from text: String) -> AIClassificationResult {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }

        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start...end])
        }

        guard
            let data = cleaned.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return AIClassificationResult(
                category: "上衣",
                colorHex: "#808080",
                styleTags: [],
                season: "all",
                confidence: 0.5,
                description: ""
            )
        }

        return AIClassificationResult(
            category: json["category"] as? String ?? "上衣",
            colorHex: json["color_hex"] as? String ?? "#808080",
            styleTags: json["style_tags"] as? [String] ?? [],
            season: json["season"] as? String ?? "all",
            confidence: json["confidence"] as? Double ?? 0.5,
            description: json["description"] as? String ?? ""
        )
    }
}
