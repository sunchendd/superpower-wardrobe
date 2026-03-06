import Foundation
import UIKit

struct ClassificationResult: Codable {
    let category: String
    let color: String
    let style: [String]
    let confidence: Double
}

final class FashionCLIPService {
    static let shared = FashionCLIPService()
    private let baseURL: String

    private init() {
        baseURL = Constants.fashionCLIPBaseURL
    }

    func classifyImage(_ image: UIImage) async throws -> ClassificationResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FashionCLIPError.invalidImage
        }

        let url = URL(string: "\(baseURL)/classify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FashionCLIPError.serverError
        }

        return try JSONDecoder().decode(ClassificationResult.self, from: data)
    }

    func removeBackground(_ image: UIImage) async throws -> UIImage {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FashionCLIPError.invalidImage
        }

        let url = URL(string: "\(baseURL)/remove-background")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let resultImage = UIImage(data: data) else {
            throw FashionCLIPError.invalidResponse
        }
        return resultImage
    }

    func batchClassify(_ images: [UIImage]) async throws -> [ClassificationResult] {
        try await withThrowingTaskGroup(of: ClassificationResult.self) { group in
            for image in images {
                group.addTask {
                    try await self.classifyImage(image)
                }
            }
            var results: [ClassificationResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

enum FashionCLIPError: LocalizedError {
    case invalidImage
    case serverError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "无法处理图片"
        case .serverError: return "服务器错误"
        case .invalidResponse: return "无效的响应数据"
        }
    }
}
