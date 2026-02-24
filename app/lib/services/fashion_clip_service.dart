import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassifyResult {
  final String category;
  final String color;
  final List<String> tags;

  const ClassifyResult({
    required this.category,
    required this.color,
    required this.tags,
  });

  factory ClassifyResult.fromJson(Map<String, dynamic> json) => ClassifyResult(
        category: json['category'] as String? ?? 'tops',
        color: json['color'] as String? ?? 'black',
        tags: List<String>.from((json['tags'] as List?) ?? []),
      );
}

class FashionClipService {
  final String baseUrl;

  FashionClipService({required this.baseUrl});

  /// Classifies a clothing image by URL.
  /// Returns null on failure — caller should gracefully degrade to manual input.
  Future<ClassifyResult?> classify(String imageUrl) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/classify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image_url': imageUrl}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return ClassifyResult.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null; // graceful degradation
    }
  }
}
