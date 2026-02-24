import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class Recommendation {
  final List<String> itemIds;
  final String source;
  final Map<String, dynamic> weather;
  final String? presetName;
  final String season;
  final String seasonLabel;

  const Recommendation({
    required this.itemIds,
    required this.source,
    required this.weather,
    this.presetName,
    this.season = 'all',
    this.seasonLabel = '',
  });
}

final recommendationProvider =
    FutureProvider.autoDispose<Recommendation>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  final session = supabase.auth.currentSession;

  if (user == null || session == null) {
    throw Exception('请先登录后再获取今日推荐');
  }

  // Build the functions URL from the Supabase URL env variable
  final supabaseUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gdoqygotjkxedkptimyh.supabase.co',
  );
  final url = '$supabaseUrl/functions/v1/recommend';

  final http.Response response;
  try {
    response = await http
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
        .timeout(const Duration(seconds: 20));
  } catch (e) {
    throw Exception('网络请求失败：$e\n\n请检查网络或稍后重试');
  }

  if (response.statusCode != 200) {
    final body = response.body;
    throw Exception(
        '推荐服务返回错误 ${response.statusCode}\n$body\n\n'
        '提示：请确认 Supabase Edge Function 已部署，且 OPENWEATHER_API_KEY 已配置');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final rec = data['recommendation'] as Map<String, dynamic>;
  final weatherMap = (data['weather'] as Map<String, dynamic>?) ?? {};

  return Recommendation(
    itemIds: List<String>.from((rec['item_ids'] as List?) ?? []),
    source: rec['source'] as String? ?? 'unknown',
    weather: weatherMap,
    presetName: rec['preset_name'] as String?,
    season: weatherMap['season'] as String? ?? 'all',
    seasonLabel: weatherMap['seasonLabel'] as String? ?? '',
  );
});
