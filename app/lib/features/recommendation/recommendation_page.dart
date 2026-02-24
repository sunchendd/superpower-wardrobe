import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/wardrobe_provider.dart';

class RecommendationPage extends ConsumerWidget {
  const RecommendationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(recommendationProvider);
    final wardrobeAsync = ref.watch(wardrobeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日推荐'),
        centerTitle: true,
      ),
      body: recAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在为你匹配今日穿搭...'),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('获取推荐失败', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$e',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(recommendationProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
        data: (rec) {
          final allItems = wardrobeAsync.value ?? [];
          final recommendedItems =
              allItems.where((i) => rec.itemIds.contains(i.id)).toList();
          final weather = rec.weather;
          final temp = weather['temp'];
          final condition = weather['condition'] ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Weather card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _weatherIcon(condition),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            temp != null ? '${temp.toStringAsFixed(1)}°C' : '--°C',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(condition,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Source badge
              Row(
                children: [
                  Chip(
                    avatar: Icon(
                      rec.source == 'preset' ? Icons.style : Icons.auto_awesome,
                      size: 16,
                    ),
                    label: Text(
                      rec.source == 'preset'
                          ? (rec.presetName != null
                              ? '预设：${rec.presetName}'
                              : '预设套装推荐')
                          : '从衣橱智能搭配',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Outfit display
              if (recommendedItems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.style, size: 48, color: Colors.deepPurple),
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
                          '快去「预设套装」页面收藏，或拍照添加衣物到衣橱',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: recommendedItems.length > 2 ? 3 : 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: recommendedItems
                      .map((item) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const ColoredBox(color: Color(0xFFEEEEEE)),
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ))
                      .toList(),
                ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.invalidate(recommendationProvider),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('换一套'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('今日穿搭已采用 ✓'),
                          backgroundColor: Colors.green,
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('就这套！'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _weatherIcon(String condition) {
    final lower = condition.toLowerCase();
    IconData icon;
    if (lower.contains('rain') || lower.contains('drizzle')) {
      icon = Icons.umbrella;
    } else if (lower.contains('cloud')) {
      icon = Icons.cloud;
    } else if (lower.contains('snow')) {
      icon = Icons.ac_unit;
    } else if (lower.contains('clear') || lower.contains('sun')) {
      icon = Icons.wb_sunny;
    } else {
      icon = Icons.thermostat;
    }
    return Icon(icon, size: 40, color: Colors.deepPurple);
  }
}
