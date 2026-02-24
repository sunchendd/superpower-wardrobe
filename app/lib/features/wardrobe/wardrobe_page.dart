import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/wardrobe_provider.dart';
import '../../data/clothing_repository.dart';
import 'add_clothing_page.dart';

class WardrobePage extends ConsumerWidget {
  const WardrobePage({super.key});

  static const _tabs = ['全部', '上衣', '下装', '鞋子', '外套', '配饰'];
  static const _catMap = {
    '上衣': 'tops',
    '下装': 'bottoms',
    '鞋子': 'shoes',
    '外套': 'outerwear',
    '配饰': 'accessories',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(wardrobeProvider);

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的衣橱'),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              tooltip: '添加衣物',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddClothingPage()),
              ),
            ),
          ],
        ),
        body: wardrobeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text('加载失败：$e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(wardrobeProvider.notifier).refresh(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
          data: (items) => TabBarView(
            children: _tabs.map((tab) {
              final filtered = tab == '全部'
                  ? items
                  : items
                      .where((i) => i.category == _catMap[tab])
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checkroom,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        tab == '全部' ? '衣橱空空的，快去添加第一件衣物吧' : '暂无$tab',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AddClothingPage()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('添加衣物'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _ClothingCard(item: filtered[i]),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ClothingCard extends ConsumerWidget {
  final ClothingItem item;
  const _ClothingCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  const ColoredBox(color: Color(0xFFEEEEEE)),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                color: Colors.black45,
                child: Text(
                  item.color,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除衣物'),
        content: const Text('确认删除这件衣物吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(wardrobeProvider.notifier).deleteItem(item.id);
    }
  }
}
