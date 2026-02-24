import 'package:supabase_flutter/supabase_flutter.dart';

class PresetOutfit {
  final String id;
  final String name;
  final List<String> categories;
  final String? occasion;
  final List<String> weatherTags;

  const PresetOutfit({
    required this.id,
    required this.name,
    required this.categories,
    this.occasion,
    required this.weatherTags,
  });

  factory PresetOutfit.fromJson(Map<String, dynamic> json) => PresetOutfit(
        id: json['id'] as String,
        name: json['name'] as String,
        categories: List<String>.from((json['categories'] as List?) ?? []),
        occasion: json['occasion'] as String?,
        weatherTags: List<String>.from((json['weather_tags'] as List?) ?? []),
      );
}

class PresetRepository {
  final SupabaseClient _client;

  PresetRepository(this._client);

  Future<List<PresetOutfit>> getAll() async {
    final data = await _client.from('preset_outfits').select().order('name');
    return (data as List).map((e) => PresetOutfit.fromJson(e as Map<String, dynamic>)).toList();
  }
}
