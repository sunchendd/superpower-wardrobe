import 'package:supabase_flutter/supabase_flutter.dart';

class Outfit {
  final String id;
  final String userId;
  final List<String> itemIds;
  final String? occasion;
  final String source;
  final DateTime createdAt;

  const Outfit({
    required this.id,
    required this.userId,
    required this.itemIds,
    this.occasion,
    required this.source,
    required this.createdAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        itemIds: List<String>.from((json['item_ids'] as List?) ?? []),
        occasion: json['occasion'] as String?,
        source: json['source'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class OutfitRepository {
  final SupabaseClient _client;

  OutfitRepository(this._client);

  Future<List<Outfit>> getOutfits(String userId) async {
    final data = await _client
        .from('outfits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Outfit.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Outfit> savePresetAsOutfit(String userId, String presetId, String occasion) async {
    final data = await _client
        .from('outfits')
        .insert({
          'user_id': userId,
          'item_ids': <String>[],
          'occasion': occasion,
          'source': 'preset',
        })
        .select()
        .single();
    return Outfit.fromJson(data as Map<String, dynamic>);
  }
}
