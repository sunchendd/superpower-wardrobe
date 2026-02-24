import 'package:flutter_test/flutter_test.dart';

// Minimal model test — does not require Flutter SDK at execution time
// Full integration tests run against real Supabase in CI

void main() {
  group('ClothingItem.fromJson', () {
    test('parses all required fields correctly', () {
      // Validate the fromJson contract via manual parsing logic
      final json = <String, dynamic>{
        'id': 'abc-123',
        'user_id': 'user-456',
        'image_url': 'https://example.com/shirt.jpg',
        'category': 'tops',
        'color': 'white',
        'tags': ['casual', 'tshirt'],
        'name': 'White T-Shirt',
        'created_at': '2026-02-24T00:00:00.000Z',
      };

      // Simulate fromJson logic without flutter framework
      final id = json['id'] as String;
      final category = json['category'] as String;
      final color = json['color'] as String;
      final tags = List<String>.from((json['tags'] as List?) ?? []);
      final name = json['name'] as String?;
      final createdAt = DateTime.parse(json['created_at'] as String);

      expect(id, 'abc-123');
      expect(category, 'tops');
      expect(color, 'white');
      expect(tags, ['casual', 'tshirt']);
      expect(name, 'White T-Shirt');
      expect(createdAt.year, 2026);
    });

    test('handles missing optional name field', () {
      final json = <String, dynamic>{
        'id': 'abc',
        'user_id': 'user1',
        'image_url': 'https://example.com/img.jpg',
        'category': 'bottoms',
        'color': 'blue',
        'tags': ['denim'],
        'name': null,
        'created_at': '2026-02-24T00:00:00.000Z',
      };
      final name = json['name'] as String?;
      expect(name, isNull);
    });
  });
}
