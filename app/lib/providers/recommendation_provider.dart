import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class Recommendation {
  final List<String> itemIds;
  final String source;
  final Map<String, dynamic> weather;
  final String? presetName;

  const Recommendation({
    required this.itemIds,
    required this.source,
    required this.weather,
    this.presetName,
  });
}

final recommendationProvider =
    FutureProvider.autoDispose<Recommendation>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  final session = supabase.auth.currentSession;

  if (user == null || session == null) {
    throw Exception('Not authenticated');
  }

  final supabaseUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );
  final url = '$supabaseUrl/functions/v1/recommend';

  final response = await http
      .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'user_id': user.id,
          'city': 'Shanghai',
          'occasion': 'casual',
        }),
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('Recommendation failed: ${response.body}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final rec = data['recommendation'] as Map<String, dynamic>;

  return Recommendation(
    itemIds: List<String>.from((rec['item_ids'] as List?) ?? []),
    source: rec['source'] as String? ?? 'unknown',
    weather: (data['weather'] as Map<String, dynamic>?) ?? {},
    presetName: rec['preset_name'] as String?,
  );
});
