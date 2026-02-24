import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/wardrobe_provider.dart';
import '../../data/clothing_repository.dart';
import 'add_clothing_page.dart';

// ─── 分类 tab 元数据 ──────────────────────────────────────────
const _tabs = ['全部', '上衣', '下装', '鞋子', '外套', '配饰', '手表', '帽子', '首饰', '包包'];
const _catMap = <String, String>{
  '上衣': 'tops', '下装': 'bottoms', '鞋子': 'shoes', '外套': 'outerwear',
  '配饰': 'accessories', '手表': 'watch', '帽子': 'hat', '首饰': 'jewelry', '包包': 'bag',
};

// ─── 季节 ──────────────────────────────────────────────────────
const _seasonFilters = ['all', 'spring', 'summer', 'autumn', 'winter'];
const _seasonLabels  = <String, String>{
  'all': '全季', 'spring': '春', 'summer': '夏', 'autumn': '秋', 'winter': '冬',
};
const _seasonColors = <String, Color>{
  'all': Colors.blueGrey, 'spring': Color(0xFF66BB6A),
  'summer': Color(0xFFFF9800), 'autumn': Color(0xFFBF360C), 'winter': Color(0xFF42A5F5),
};
const _seasonIcons = <String, IconData>{
  'all': Icons.all_inclusive, 'spring': Icons.local_florist,
  'summer': Icons.wb_sunny, 'autumn': Icons.eco, 'winter': Icons.ac_unit,
};

class WardrobePage extends ConsumerStatefulWidget {
  const WardrobePage({super.key});

  @override
  ConsumerState<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends ConsumerState<WardrobePage> {
  String _seasonFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final wardrobeAsync = ref.watch(wardrobeProvider);
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的衣橱'),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
        body: Column(
          children: [
            // ── 季节筛选条 ──────────────────────────────────
            Container(
              color: cs.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text('季节：',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _seasonFilters.map((s) {
                          final sel = _seasonFilter == s;
                          final sc = _seasonColors[s]!;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              avatar: Icon(_seasonIcons[s],
                                  size: 13,
                                  color: sel ? Colors.white : sc),
                              label: Text(_seasonLabels[s]!,
                                  style: const TextStyle(fontSize: 12)),
                              selected: sel,
                              selectedColor: sc,
                              visualDensity: VisualDensity.compact,
                              labelStyle: TextStyle(
                                  color: sel ? Colors.white : null),
                              onSelected: (_) =>
                                  setState(() => _seasonFilter
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Grid 内容 ──────────────────────────────────
            Expanded(
              child: wardrobeAsync.when(
                loading: () =>
        
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('加载失败：$e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(wardrobeProvider.notifier).refresh(),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  // Apply season filter first
                  final seasonItems = _seasonFilter == 'all'
                      ? items
                      : items
                          .where((i) =>
                              i.season == _seasonFilter || i.season == 'all')
                          .toList();

                  return TabBarView(
                    children: _tabs.map((tab) {
                      final filtered = tab == '全部'
                          ? seasonItems
                          : seasonItems
                              .where((i) => i.category == _catMap[tab])
            

                      if (filt
                        return _EmptyState(
                          tab: tab,
                          seasonFilter: _seasonFilter,
                        );


                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                    
              
                          mainAxisSpacing: 6,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _ClothingCard(item: filtered[i]),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
      
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddClothingPage()),
          ),
          tooltip: '添加衣物',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// ─── 空状态 ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidg
  final String tab;
  final String seasonFilter;
  const _EmptyState({required this.tab, required this.seasonFilter});

  @override
  Widget build(BuildContext context) {
    final seasonHint = seasonFilter == 'all'
        ? ''
        : '（${_seasonLabels[sea
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            tab == '全部'
                ? '衣橱空空的，快去添加第一件衣物吧'
                : '暂无$tab$seasonHint',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddClothingPage()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('添加衣物'),
          ),
        ],
      ),
    );
  }
}

// ─── 衣物卡片 ──────────────────────────────────────────────────
class _ClothingCard extends Consu
  final ClothingItem item;
  const _Clot

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(fit: StackFit.expand, children: [
          item.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: 
                  placeholder: (_, __) =>
                      const ColoredBox(color: Color(0xFFEEEEEE)),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFF5F5F5),
                    child: Center(child: Icon(Icons.broken_image)),
                 
                )
              : const ColoredBox(
                  color: Color(0xFFF0F0F0),
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
          // 季节角标
          if (item.season != 'all')
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: (_seasonColors[item.season] ?? Colors.blueGrey)
      
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _seasonLabels[item.season] ?? it
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          // 底部名称/颜色栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 3
              decoration: const BoxDecoration(
                gradient: LinearGr
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
           
              child: Text(
                item.name ??
                    '${_catLabel(item.category)} · ${_colorLabelShort(item.color)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _catLabel(String cat) {
    const m = <String, String>{
      'tops': '
      'accessories': '配饰', 'watch': '手表', 'hat': '帽子', 'jewelry': '首饰', 'bag': '包包',
    };
    return m[cat] ?? cat;
  }

  String _colorLabelShort(String color) {
    const m = <String, String>{
     
      'yellow': '
      'orange': '�橙', 'purp
    };
    return m[color] ?? color;
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        t
        content: con
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
    if (co
      await ref.read(wardrobeProvider.notifier).deleteItem(item.id);
    }
  }
}
