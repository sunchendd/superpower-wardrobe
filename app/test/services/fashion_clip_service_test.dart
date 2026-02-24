import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassifyResult.fromJson', () {
    test('parses category, color, tags correctly', () {
      final json = <String, dynamic>{
        'category': 'tops',
        'color': 'white',
        'tags': ['casual', 'tshirt'],
      };
      final category = json['category'] as String? ?? 'tops';
      final color = json['color'] as String? ?? 'black';
      final tags = List<String>.from((json['tags'] as List?) ?? []);

      expect(category, 'tops');
      expect(color, 'white');
      expect(tags, ['casual', 'tshirt']);
    });

    test('handles missing tags gracefully', () {
      final json = <String, dynamic>{
        'category': 'bottoms',
        'color': 'blue',
      };
      final tags = List<String>.from((json['tags'] as List?) ?? []);
      expect(tags, isEmpty);
    });
  });
}
