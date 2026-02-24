import 'package:supabase_flutter/supabase_flutter.dart';

class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  final String category;
  final String color;
  final List<String> tags;
  final String? name;
  final String season; // spring / summer / autumn / winter / all
  final DateTime createdAt;

  const ClothingItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.category,
    required this.color,
    required this.tags,
    this.name,
    this.season = 'all',
    required this.createdAt,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        imageUrl: json['image_url'] as String? ?? '',
        category: json['category'] as String,
        color: json['color'] as String,
        tags: List<String>.from((json['tags'] as List?) ?? []),
        name: json['name'] as String?,
        season: json['season'] as String? ?? 'all',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'image_url': imageUrl,
        'category': category,
        'color': color,
        'tags': tags,
        'season': season,
        if (name != null) 'name': name,
      };
}

class ClothingRepository {
  final SupabaseClient _client;

  ClothingRepository(this._client);

  Future<List<ClothingItem>> getItems(String userId) async {
    final data = await _client
        .from('clothing_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ClothingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClothingItem> addItem(ClothingItem item) async {
    final data = await _client
        .from('clothing_items')
        .insert(item.toInsertJson())
        .select()
        .single();
    return ClothingItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteItem(String id) async {
    await _client.from('clothing_items').delete().eq('id', id);
  }
}
