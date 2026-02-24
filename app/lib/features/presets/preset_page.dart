import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/preset_provider.dart';
import '../../data/preset_repository.dart';

class PresetPage extends ConsumerStatefulWidget {
  const PresetPage({super.key});

  @override
  ConsumerState<PresetPage> createState() => _PresetPageState();
}

class _PresetPageState extends ConsumerState<PresetPage> {
  final Set<String> _selected = {};
  String? _filterOccasion;

  static const _occasionLabels = {
    'casual': '日常',
    'work': '通勤',
    'sport': '运动',
    'formal': '正式',
  };

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(presetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('预设套装'),
        centerTitle: true,
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: _saveSelected,
              icon: const Icon(Icons.favorite),
              label: Text('收藏 ${_selected.length} 套'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Occasion filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: _filterOccasion == null,
                  onSelected: (_) =>
                      setState(() => _filterOccasion = null),
                ),
                ..._occasionLabels.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: _filterOccasion == e.key,
                      onSelected: (_) =>
                          setState(() => _filterOccasion = e.key),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Preset list
          Expanded(
            child: presetsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (presets) {
                final filtered = _filterOccasion == null
                    ? presets
                    : presets
                        .where((p) => p.occasion == _filterOccasion)
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('暂无此类预设套装'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final preset = filtered[i];
                    final isSelected = _selected.contains(preset.id);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.grey.shade100,
                        child: Icon(
                          isSelected ? Icons.favorite : Icons.style,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                      title: Text(preset.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        '${_occasionLabels[preset.occasion] ?? preset.occasion ?? ''} · ${preset.weatherTags.map(_weatherTagLabel).join(' / ')}',
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () => setState(() => isSelected
                          ? _selected.remove(preset.id)
                          : _selected.add(preset.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveSelected,
              icon: const Icon(Icons.favorite),
              label: Text('收藏 ${_selected.length} 套'),
            )
          : null,
    );
  }

  String _weatherTagLabel(String tag) {
    const map = {
      'warm': '暖',
      'mild': '适中',
      'cool': '凉',
      'cold': '冷',
    };
    return map[tag] ?? tag;
  }

  Future<void> _saveSelected() async {
    // TODO in v2: persist selected presets to user's saved outfits
    final count = _selected.length;
    setState(() => _selected.clear());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已收藏 $count 套预设穿搭 ❤️'),
          backgroundColor: Colors.pink,
        ),
      );
    }
  }
}
