import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/wardrobe_provider.dart';

// ─── 季节常量 ───────────────────────────────────────────────────
const _seasonColors = <String, Color>{
  'summer': Color(0xFFFF9800), 'spring': Color(0xFF66BB6A),
  'autumn': Color(0xFFBF360C), 'winter': Color(0xFF42A5F5),
  'all': Colors.blueGrey,
};
const _seasonLabels = <String, String>{
  'summer': '夏季', 'spring': '春季', 'autumn': '秋季', 'winter': '冬季', 'all': '',
};
const _seasonIcons = <String, IconData>{
  'summer': Icons.wb_sunny, 'spring': Icons.local_florist,
  'autumn': Icons.eco, 'winter': Icons.ac_unit, 'all': Icons.all_inclusive,
};

class RecommendationPage extends ConsumerWidget {
  const RecommendationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(recommendationProvider);
    final wardrobeAsync = ref.watch(wardrobeProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日推荐'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(recommendationProvider),
          ),
        ],
      ),
      body: recAsync.when(
        loading: () => const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在为你匹配今日穿搭...'),
          ]),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('获取推荐失败', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$e',
                    style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.invalidate(recommendationProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ]),
          ),
        ),
        data: (rec) {
          final allItems = wardrobeAsync.value ?? [];
          final recommendedItems =
              allItems.where((i) => rec.itemIds.contains(i.id)).toList();
          final weather = rec.weather;
          final double? temp = weather['temp'] as double?;
          final condition = weather['condition'] as String? ?? '';
          final season = rec.season;
          final seasonLabel = rec.seasonLabel.isNotEmpty
              ? rec.seasonLabel
              : (_seasonLabels[season] ?? '');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 天气 + 季节卡片
              _WeatherSeasonCard(
                temp: temp,
                condition: condition,
                season: season,
                seasonLabel: seasonLabel,
              ),
              const SizedBox(height: 16),

              // 推荐来源 + 季节 badge
              Wrap(spacing: 8, children: [
                Chip(
                  avatar: Icon(
                    rec.source == 'preset' ? Icons.style : Icons.auto_awesome,
                    size: 15,
                  ),
                  label: Text(
                    rec.source == 'preset'
                        ? (rec.presetName != null
                            ? '预设：${rec.presetName}'
                            : '预设套装推荐')
                        : '从衣橱智能搭配',
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                if (seasonLabel.isNotEmpty)
                  Chip(
                    avatar: Icon(
                      _seasonIcons[season] ?? Icons.calendar_today,
                      size: 14,
                      color: _seasonColors[season],
                    ),
                    label: Text(seasonLabel,
                        style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
              ]),
              const SizedBox(height: 12),

              // 穿搭展示
              if (recommendedItems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(Icons.style,
                          size: 56, color: cs.primary.withOpacity(.6)),
                      const SizedBox(height: 12),
                      Text(
                        rec.source == 'preset' && rec.presetName != null
                            ? '今日推荐：${rec.presetName}'
                            : '今日推荐一套精选穿搭',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '快去「预设套装」收藏，或拍照添加衣物到衣橱吧',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                )
              else ...[  
                Text('推荐单品',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: recommendedItems.length > 2 ? 3 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: recommendedItems.map((item) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(fit: StackFit.expand, children: [
                        CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const ColoredBox(color: Color(0xFFEEEEEE)),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 6),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                            child: Text(
                              item.name ?? _catLabel(item.category),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ]),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),
              _OutfitAdviceCard(
                  temp: temp, season: season, condition: condition),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.invalidate(recommendationProvider),
                    icon: const Icon(Icons.shuffle),
                    label: const Text('换一套'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已记录今日穿搭 ✓'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('就穿这套'),
                  ),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  String _catLabel(String cat) {
    const m = <String, String>{
      'tops': '上衣', 'bottoms': '下装', 'shoes': '鞋子', 'outerwear': '外套',
      'accessories': '配饰', 'watch': '手表', 'hat': '帽子',
      'jewelry': '首饰', 'bag': '包包',
    };
    return m[cat] ?? cat;
  }
}

// ─── 天气+季节卡 ───────────────────────────────────────────────
class _WeatherSeasonCard extends StatelessWidget {
  final double? temp;
  final String condition;
  final String season;
  final String seasonLabel;

  const _WeatherSeasonCard({
    required this.temp,
    required this.condition,
    required this.season,
    required this.seasonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sc = _seasonColors[season] ?? Colors.blueGrey;
    final si = _seasonIcons[season] ?? Icons.calendar_today;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [sc.withOpacity(.15), sc.withOpacity(.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
                color: sc.withOpacity(.2), shape: BoxShape.circle),
            child: Center(child: _weatherIcon(condition, sc)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                temp != null ? '${temp!.toStringAsFixed(1)}°C' : '--°C',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(_conditionZh(condition),
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          if (seasonLabel.isNotEmpty)
            Column(children: [
              Icon(si, color: sc, size: 28),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: sc, borderRadius: BorderRadius.circular(12)),
                child: Text(seasonLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ]),
        ]),
      ),
    );
  }

  Widget _weatherIcon(String cond, Color color) {
    final l = cond.toLowerCase();
    IconData icon;
    if (l.contains('rain') || l.contains('drizzle')) icon = Icons.umbrella;
    else if (l.contains('snow'))   icon = Icons.ac_unit;
    else if (l.contains('thunder')) icon = Icons.thunderstorm;
    else if (l.contains('clear') || l.contains('sun')) icon = Icons.wb_sunny;
    else if (l.contains('cloud')) icon = Icons.cloud;
    else if (l.contains('mist') || l.contains('fog') || l.contains('haze')) icon = Icons.foggy;
    else icon = Icons.cloud_queue;
    return Icon(icon, size: 30, color: color);
  }

  String _conditionZh(String cond) {
    const m = <String, String>{
      'clear': '晴天', 'clouds': '多云', 'rain': '下雨',
      'drizzle': '小雨', 'snow': '下雪', 'thunderstorm': '雷暴',
      'mist': '薄雾', 'fog': '大雾', 'haze': '雾霾', 'unknown': '天气未知',
    };
    return m[cond.toLowerCase()] ?? cond;
  }
}

// ─── 穿衣建议卡 ────────────────────────────────────────────────
class _OutfitAdviceCard extends StatelessWidget {
  final double? temp;
  final String season;
  final String condition;
  const _OutfitAdviceCard(
      {required this.temp, required this.season, required this.condition});

  @override
  Widget build(BuildContext context) {
    final advice = _advice();
    if (advice.isEmpty) return const SizedBox.shrink();
    final sc = _seasonColors[season] ?? Colors.deepPurple;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Icon(Icons.tips_and_updates, color: sc, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(advice,
                  style: const TextStyle(fontSize: 13, height: 1.5))),
        ]),
      ),
    );
  }

  String _advice() {
    final parts = <String>[];
    if (temp != null) {
      if (temp! >= 30)      parts.add('今日气温较高，建议穿透气棉麻，避免深色吸热');
      else if (temp! >= 22) parts.add('天气舒适，T恤搭配轻薄裤子是不错的选择');
      else if (temp! >= 15) parts.add('早晚略凉，建议加一件薄外套或针织衫');
      else if (temp! >= 8)  parts.add('气温较低，厚外套或毛衣是今日标配');
      else                  parts.add('寒冷天气，需要大衣、围巾和帽子保暖');
    }
    final l = condition.toLowerCase();
    if (l == 'rain' || l == 'drizzle') {
      parts.add('今日有雨，出门记得带伞，避免穿浅色下装');
    }
    return parts.join('。');
  }
}
