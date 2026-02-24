import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

// ─── 分类元数据 ───────────────────────────────────────────────
const _categories = [
  'tops', 'bottoms', 'shoes', 'outerwear',
  'accessories', 'watch', 'hat', 'jewelry', 'bag',
];

// ─── 颜色元数据 ───────────────────────────────────────────────
const _colors = [
  'white', 'black', 'blue', 'red', 'green',
  'yellow', 'grey', 'brown', 'pink', 'beige', 'orange', 'purple',
];
const _colorLabels = <String, String>{
  'white': '白色', 'black': '黑色', 'blue': '蓝色', 'red': '红色',
  'green': '绿色', 'yellow': '黄色', 'grey': '灰色', 'brown': '棕色',
  'pink': '粉色', 'beige': '米色', 'orange': '橙色', 'purple': '紫色',
};
const _colorValues = <String, Color>{
  'white': Color(0xFFFFFFFF), 'black': Color(0xFF212121),
  'blue': Color(0xFF2196F3), 'red': Color(0xFFF44336),
  'green': Color(0xFF4CAF50), 'yellow': Color(0xFFFFEB3B),
  'grey': Color(0xFF9E9E9E), 'brown': Color(0xFF795548),
  'pink': Color(0xFFE91E63), 'beige': Color(0xFFF5F0DC),
  'orange': Color(0xFFFF9800), 'purple': Color(0xFF9C27B0),
};

// ─── 季节元数据 ───────────────────────────────────────────────
const _seasons = ['all', 'spring', 'summer', 'autumn', 'winter'];

// ─── 输入方式 ─────────────────────────────────────────────────
enum _InputMode { photo, url }

String _catLabel(String cat) {
  const m = <String, String>{
    'tops': '上衣', 'bottoms': '下装', 'shoes': '鞋子',
    'outerwear': '外套', 'accessories': '配饰', 'watch': '手表',
    'hat': '帽子', 'jewelry': '首饰', 'bag': '包包',
  };
  return m[cat] ?? cat;
}

IconData _catIcon(String cat) {
  const m = <String, IconData>{
    'tops': Icons.dry_cleaning, 'bottoms': Icons.straighten,
    'shoes': Icons.directions_walk, 'outerwear': Icons.wind_power,
    'accessories': Icons.star_border, 'watch': Icons.watch,
    'hat': Icons.hail, 'jewelry': Icons.diamond_outlined,
    'bag': Icons.shopping_bag_outlined,
  };
  return m[cat] ?? Icons.checkroom;
}

String _seasonLabel(String s) {
  const m = <String, String>{
    'all': '全季', 'spring': '春', 'summer': '夏',
    'autumn': '秋', 'winter': '冬',
  };
  return m[s] ?? s;
}

IconData _seasonIcon(String s) {
  const m = <String, IconData>{
    'all': Icons.all_inclusive, 'spring': Icons.local_florist,
    'summer': Icons.wb_sunny, 'autumn': Icons.eco, 'winter': Icons.ac_unit,
  };
  return m[s] ?? Icons.calendar_today;
}

Color _seasonColor(String s) {
  const m = <String, Color>{
    'all': Colors.blueGrey, 'spring': Color(0xFF66BB6A),
    'summer': Color(0xFFFF9800), 'autumn': Color(0xFFBF360C),
    'winter': Color(0xFF42A5F5),
  };
  return m[s] ?? Colors.grey;
}

class AddClothingPage extends ConsumerStatefulWidget {
  const AddClothingPage({super.key});

  @override
  ConsumerState<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends ConsumerState<AddClothingPage> {
  _InputMode _inputMode = _InputMode.photo;

  // Photo mode
  XFile? _imageFile;
  String? _uploadedUrl;
  bool _isUploading = false;
  bool _isClassifying = false;
  bool _classificationFailed = false;

  // URL mode
  final _urlController = TextEditingController();

  // Common fields
  final _nameController = TextEditingController();
  String _category = 'tops';
  String _color = 'white';
  String _season = 'all';
  List<String> _tags = [];

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Photo flow ────────────────────────────────────────────

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
      final su
      final userId = supabase.auth.currentUser?.id ?? 'anon';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'clothing/$userId/$fileName';
      final bytes = await picked.readAsBytes();
      await supabase.storage.from('clothing-images').uploadBinary(path, bytes);
      final url = supabase.stor

      setState(() {
        _uploadedUrl = url;
        _isUploading = fa
        _isClassifying = true;
      });

      final service = ref.read(_fashionClipServiceProvider);
      final result = await service.classify(url);

  
        setState(() {
          _categor
          _color = result.color;
          _tags = result.tags;
          _isClassifying = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('AI识别完成：${_catLabel(_category)} / ${_colorLabels[_color]}'),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        setState(() {
          _isClassifying = false;
          _classificationFailed = true;
        });
        if (mounted) {
          Scaf
            content: Text('AI识别失败，请手动选择类别
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isClassifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('�上传失败：$e'), backgroundColor: Colors.red));
      }
    }
  }

  // ── URL flow ─────────────────────────

  Future<void> _classifyUrl() async {
    final url = _ur
    if (url.isEmpty) return;
    setState(() {
      _isClassifying = true;
      _classificationFailed = false;
    });
    final service = ref.read(_fashionClipServiceProvider);
    final result = await service.classi
    if (result != null) {
      setState(() {
        _category = result.category;
        _color = result.color;
        _tags = result.tags;
        _isClassifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('AI�识别
          backgroundCo
        ));
      }
    } else {
      setState(() {
        _isClassifying = false;
        _classificationFailed = true;
    
    }
  }

  // �── Save ─────────────────────────────────────────────────

  Future<void> _save() async {
    final url = _inputMode == _InputMode.photo
        ? _uploadedUrl
        : _urlController.text.trim();
    if (url == null || url.isEmpty) return;

    fina
    final item = ClothingItem(
      id: '',
      userId
      imageUrl: url,
      category: _category,
      color: _color,
      tags: _tags,
      season: _season,
      name: _n
 

      createdAt: DateTime.now(),
    );
    try {
      await ref.read(wardrobeProvider.notifier).addItem(item);
      if (mounted) Navigator.of(conte
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败：$e'), backgroundColor: Colors.red));
      }
    }
  }

  bool get _canSave {
    if (_isUploading || _isClassifying) return false;
    if (_inputMode == _InputMode.photo) return _uploadedUrl != null;
    return _urlController.text.trim().isNotEmpty;
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(c

    return Scaffold(
      appBar: AppBar(
        title: 
        centerTitle: true,
        actions: [
          if (_canSave)
            Padding(
              paddi
              child: FilledButto
                onPressed: _save,
                icon: const Icon(Icon
                label: const Text('保存'),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 
            SegmentedButton<_InputMode>(
              segments: const [
                ButtonSegment(
                  value: _InputMode.photo,
             
                  l
                ),
                ButtonSegment(
   
                  icon: Icon(Icons.link)

                ),
              ],
              selected: {_inputMode},
              onSelectionChanged: (s)
                  setState(() => _inputMode = s.first),
            ),
            const SizedBox(height: 20),

            // �── 图片
            if (_inputMode == _InputMode.photo) _buildPhotoInput(cs),
            if (_inputMode == _InputMode.url) _buildUrlInput(cs),
            const SizedBox(height: 16),

            // �
            if (_isUploading) _statusRow(Icons.cloud_upload, '�正在上传...', Colors.blue),
            if (_isClassifying) _statusRow(Icons.auto_awesome, 'AI识别中...', Colors.deepPur
            if (_classificationFailed)
              _statusRow(Icons.info_outline, '识别失败，请手动选择分类', Colors.orange),
            if (_isUpl
              const SizedBox(height: 6),
              const LinearProgressIndicator(
              const SizedBox(he
            ],

            //
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称（选填）',
                hintText: '例如：白色POLO衫',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
          
            const SizedBox(height: 16),

            // ── 分类选择 ──
            _label('分类'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
           
                final selected = _category == cat;
                return FilterChip(
                  avatar: Icon(_catIcon(cat),
                      size: 15,
                      color: selected ? cs.onPrimary : cs.onSurfaceVariant),
                  label: Text(_catLabel(cat)),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: cs.primary,
     
                    color: selected ? cs.onPrimary : cs.onSurface,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
      
            const SizedBox(height: 16),

            // ─
            _label('�颜色'),
            const SizedBox(height: 8),
            Wra
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((c) {
                final selected = _color == c;
                final colVal = _colorValues[c] ?? Co
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
           
                    message: _colorLabels[c] ?? c,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecor
                        color: colVal,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              selected ? cs.primary : Colors.grey.shade300,
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: cs.primary.withOpacity(.35),
                                  blurRadius: 6,
                                )
             
                            : null,
                      ),
                     
                
                              size: 16,
                              color: colVal.computeLuminance() > 0.5
                                  ? Colors
                                  : Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── 季节选择 ──
            _label('适合季节'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8
              runSpacing: 8,
        
                final selected = _season == s;
                final sc = _seasonColor(s);
                return ChoiceChip(
               
                      size: 14,
                      color: selected ? Colors.white : sc),
                  label: Text(_seasonLabel(
                  selected: selected,
  
                  labelStyle:
                      TextStyle(color: selected ? Colors.white : null),
                  onSelected: (_) => setState(() => _season = s),
                );
              }).toList(),
            ),

            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              _label('AI标签'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags
       
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          backgrou
                        ))
                    .toL
              ),
            ],

            const SizedBox(height: 28),
            FilledButton.icon(
             
              icon: const Icon(Icons.save),
              label: const Text('保存到衣橱'),
              style: FilledButton.styleFrom(
                  min
            ),
          ],
        ),
      ),
    );
  }

  // ── helpers ──────────────────

  Widget _buildPhotoInput(ColorScheme cs) {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          Image.file(File(_imageFile!.path),
              height: 240, width: double.infinit
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
              
                onPressed: () => setState(() {
                  _imageFile = null;
                  _uploadedUrl = null;
                  _tags = [];
                }),
              ),
            ),
          ),
        ]),
    
    }
    return InkWell(
      onTap: _showPickerSheet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(.4), width: 2),
          color: cs.surfaceVariant.withOpacity(.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 42, color: cs.primary),
            const S
            Text('�点击拍照或从相册选择',
                style: TextStyle(color: cs.primary, fontSize: 15)),
            const SizedBox(height: 4),
     
                style: TextStyle(color: cs.outline, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput(ColorScheme cs) {
    final previewUrl = _urlController.text.trim();
    return Column(
      c
      children: [
        Row(children: [
          Expanded(
            c
              controller: _urlController,
              onChanged: (_) => setState(() {}),
              decorat
                labelText: '图片链接（支
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
   
              ),
              keyboardType: TextInputType.url,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: (previewUrl.isNotEmpty && !_isClassifying)
                ? _classifyUrl
                : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
             
                  Icon(Icons.auto_awesome, size: 16),
                  SizedBox(height: 2),
                  Text('AI\n�识别', style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ]),
        if (previewUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              i
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: cs.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 80,
               
                child: Center(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: cs.outline),
                    const SizedBox(height: 4),
                    Text('图片预览失败', style: TextStyle(color: cs.outline, fontSize: 12)),
                  ],
                )),
    
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _statusRow(IconData icon, String msg, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 4
        child: Row(children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(
          Text(msg, style: TextS
        ]),
      );

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
           
                decoration: BoxDecorati
          
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () 
                  Navigator.pop(context);
                  _pickAndProces
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title:
                onTap: () {
                  Navigator.pop(context);
                  _pickAndProcess(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
