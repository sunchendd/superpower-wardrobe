import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/clothing_repository.dart';
import '../../providers/wardrobe_provider.dart';
import '../../services/fashion_clip_service.dart';

final _fashionClipServiceProvider = Provider<FashionClipService>((ref) =>
    FashionClipService(
      baseUrl: const String.fromEnvironment(
        'FASHION_CLIP_URL',
        defaultValue: 'http://localhost:8000',
      ),
    ));

class AddClothingPage extends ConsumerStatefulWidget {
  const AddClothingPage({super.key});

  @override
  ConsumerState<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends ConsumerState<AddClothingPage> {
  XFile? _imageFile;
  String? _uploadedUrl;
  String _category = 'tops';
  String _color = 'white';
  List<String> _tags = [];
  bool _isUploading = false;
  bool _isClassifying = false;
  bool _classificationFailed = false;

  static const _categories = [
    'tops', 'bottoms', 'shoes', 'outerwear', 'accessories'
  ];
  static const _categoryLabels = {
    'tops': '上衣',
    'bottoms': '下装',
    'shoes': '鞋子',
    'outerwear': '外套',
    'accessories': '配饰',
  };
  static const _colors = [
    'white', 'black', 'blue', 'red', 'green',
    'yellow', 'grey', 'brown', 'pink', 'beige'
  ];
  static const _colorLabels = {
    'white': '白色', 'black': '黑色', 'blue': '蓝色', 'red': '红色',
    'green': '绿色', 'yellow': '黄色', 'grey': '灰色', 'brown': '棕色',
    'pink': '粉色', 'beige': '米色',
  };

  Future<void> _pickAndProcess(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _imageFile = picked;
      _isUploading = true;
      _classificationFailed = false;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? 'anon';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'clothing/$userId/$fileName';

      final bytes = await picked.readAsBytes();
      await supabase.storage.from('clothing-images').uploadBinary(path, bytes);
      final url = supabase.storage.from('clothing-images').getPublicUrl(path);

      setState(() {
        _uploadedUrl = url;
        _isUploading = false;
        _isClassifying = true;
      });

      final service = ref.read(_fashionClipServiceProvider);
      final result = await service.classify(url);

      if (result != null) {
        setState(() {
          _category = result.category;
          _color = result.color;
          _tags = result.tags;
          _isClassifying = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '识别完成：${_categoryLabels[_category]} / ${_colorLabels[_color]}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isClassifying = false;
          _classificationFailed = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('识别失败，请手动选择类别和颜色'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isClassifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_uploadedUrl == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    final item = ClothingItem(
      id: '',
      userId: userId,
      imageUrl: _uploadedUrl!,
      category: _category,
      color: _color,
      tags: _tags,
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(wardrobeProvider.notifier).addItem(item);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isUploading || _isClassifying;

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加衣物'),
        actions: [
          if (_uploadedUrl != null && !isLoading)
            TextButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image picker area
          GestureDetector(
            onTap: () => _showPickerSheet(),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('点击拍照或从相册选图',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
            ),
          ),

          // Loading states
          if (isLoading) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(_isUploading ? '上传中...' : 'AI 识别中...'),
              ],
            ),
          ],

          if (_classificationFailed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text('识别失败，请手动选择下方类别和颜色',
                      style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Category selector
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: '类别',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(_categoryLabels[c] ?? c)))
                .toList(),
            onChanged: isLoading ? null : (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),

          // Color selector
          DropdownButtonFormField<String>(
            value: _color,
            decoration: const InputDecoration(
              labelText: '颜色',
              border: OutlineInputBorder(),
            ),
            items: _colors
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(children: [
                      Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                            color: _colorToMaterial(c),
                          )),
                      Text(_colorLabels[c] ?? c),
                    ])))
                .toList(),
            onChanged: isLoading ? null : (v) => setState(() => _color = v!),
          ),

          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children:
                  _tags.map((t) => Chip(label: Text(t), labelPadding: EdgeInsets.zero)).toList(),
            ),
          ],

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: (_uploadedUrl == null || isLoading) ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('保存到衣橱'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }

  Color _colorToMaterial(String color) {
    const map = {
      'white': Colors.white,
      'black': Colors.black,
      'blue': Colors.blue,
      'red': Colors.red,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'grey': Colors.grey,
      'brown': Colors.brown,
      'pink': Colors.pink,
      'beige': Color(0xFFF5F0DC),
    };
    return map[color] ?? Colors.grey;
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcess(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcess(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
