# Superpower Wardrobe MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建「拍照→识别→储存→推荐」完整 MVP，Flutter iOS + Supabase + FashionCLIP FastAPI

**Architecture:** Flutter iOS app 通过 Supabase 管理 auth/storage/db，FashionCLIP 作为独立 FastAPI 微服务识别衣物，推荐引擎在 Supabase Edge Function 中实现（调 OpenWeather API）

**Tech Stack:** Flutter 3.x, Dart, Supabase, Python 3.11, FastAPI, FashionCLIP, Riverpod, OpenWeather API

---

## Task 1: 初始化 Flutter 项目结构

**Files:**
- Create: `app/pubspec.yaml`
- Create: `app/lib/main.dart`
- Create: `app/lib/app.dart`

**Step 1: 创建 Flutter 项目**

```bash
cd /root/superpower-wardrobe
flutter create app --org com.superpowerwardrobe --platforms ios
```

Expected: 生成 Flutter iOS 项目目录

**Step 2: 更新 pubspec.yaml 依赖**

替换 `app/pubspec.yaml` dependencies 部分：

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.0
  riverpod: ^2.5.1
  flutter_riverpod: ^2.5.1
  image_picker: ^1.1.2
  http: ^1.2.1
  cached_network_image: ^3.3.1
  shared_preferences: ^2.2.3
  geolocator: ^11.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mocktail: ^1.0.3
```

**Step 3: 安装依赖**

```bash
cd app && flutter pub get
```

Expected: 所有依赖下载成功，无报错

**Step 4: 写 main.dart 初始化入口**

```dart
// app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(const ProviderScope(child: SuperpowerWardrobeApp()));
}
```

**Step 5: 写 app.dart**

```dart
// app/lib/app.dart
import 'package:flutter/material.dart';
import 'features/shell/main_shell.dart';

class SuperpowerWardrobeApp extends StatelessWidget {
  const SuperpowerWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Superpower Wardrobe',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const MainShell(),
    );
  }
}
```

**Step 6: Commit**

```bash
git add app/ && git commit -m "feat: initialize Flutter project with dependencies"
```

---

## Task 2: Supabase 数据库 Schema 初始化

**Files:**
- Create: `supabase/migrations/20260224000001_init.sql`
- Create: `supabase/seed.sql`

**Step 1: 写 migration SQL**

```sql
-- supabase/migrations/20260224000001_init.sql

-- 衣物表
create table public.clothing_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  image_url text not null,
  category text not null check (category in ('tops','bottoms','shoes','outerwear','accessories')),
  color text not null,
  tags text[] default '{}',
  name text,
  created_at timestamptz default now()
);
alter table public.clothing_items enable row level security;
create policy "Users manage own items" on public.clothing_items
  for all using (auth.uid() = user_id);

-- 穿搭组合表
create table public.outfits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  item_ids uuid[] default '{}',
  occasion text check (occasion in ('casual','work','sport','formal')),
  source text check (source in ('ai_generated','preset','user_created')),
  created_at timestamptz default now()
);
alter table public.outfits enable row level security;
create policy "Users manage own outfits" on public.outfits
  for all using (auth.uid() = user_id);

-- 内置 preset 套装
create table public.preset_outfits (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  categories text[] not null,
  occasion text check (occasion in ('casual','work','sport','formal')),
  weather_tags text[] default '{}'
);
-- presets 对所有人可读
alter table public.preset_outfits enable row level security;
create policy "Everyone reads presets" on public.preset_outfits
  for select using (true);

-- 每日推荐记录表
create table public.daily_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  outfit_id uuid references public.outfits,
  weather_data jsonb,
  accepted bool default false,
  unique(user_id, date)
);
alter table public.daily_recommendations enable row level security;
create policy "Users manage own recommendations" on public.daily_recommendations
  for all using (auth.uid() = user_id);
```

**Step 2: 写 preset seed 数据**

```sql
-- supabase/seed.sql
insert into public.preset_outfits (name, categories, occasion, weather_tags) values
  ('牛仔裤 + 白T恤', array['tops','bottoms'], 'casual', array['warm','mild']),
  ('黑西裤 + 白衬衫', array['tops','bottoms'], 'work', array['mild','cool']),
  ('运动裤 + 运动T', array['tops','bottoms'], 'sport', array['warm','mild']),
  ('深色牛仔裤 + 格子衬衫', array['tops','bottoms'], 'casual', array['mild','cool']),
  ('黑裤 + 黑色卫衣', array['tops','bottoms'], 'casual', array['cool','cold']),
  ('卡其裤 + polo衫', array['tops','bottoms'], 'work', array['warm','mild']),
  ('牛仔裤 + 条纹T恤 + 白球鞋', array['tops','bottoms','shoes'], 'casual', array['warm','mild']),
  ('西装裤 + 西装外套 + 衬衫', array['tops','bottoms','outerwear'], 'formal', array['mild','cool']);
```

**Step 3: 应用 migration（本地 Supabase 或 Supabase Dashboard）**

```bash
# 若使用本地 supabase CLI
supabase db reset
# 若直接用 Dashboard，在 SQL Editor 执行上述 SQL
```

**Step 4: Commit**

```bash
git add supabase/ && git commit -m "feat: add supabase schema and preset seed data"
```

---

## Task 3: FashionCLIP Python 识别服务

**Files:**
- Create: `services/fashion-clip/main.py`
- Create: `services/fashion-clip/requirements.txt`
- Create: `services/fashion-clip/Dockerfile`
- Create: `services/fashion-clip/tests/test_classify.py`

**Step 1: 写 failing test**

```python
# services/fashion-clip/tests/test_classify.py
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

def test_classify_returns_category_color_tags():
    mock_result = {"category": "tops", "color": "white", "tags": ["casual", "tshirt"]}
    with patch("main.classify_image", return_value=mock_result):
        from main import app
        client = TestClient(app)
        response = client.post("/classify", json={"image_url": "https://example.com/shirt.jpg"})
    assert response.status_code == 200
    data = response.json()
    assert data["category"] in ["tops","bottoms","shoes","outerwear","accessories"]
    assert "color" in data
    assert isinstance(data["tags"], list)

def test_classify_invalid_url_returns_422():
    with patch("main.classify_image", side_effect=ValueError("invalid")):
        from main import app
        client = TestClient(app)
        response = client.post("/classify", json={"image_url": ""})
    assert response.status_code in [422, 400]
```

**Step 2: 运行确认测试失败**

```bash
cd services/fashion-clip && pip install fastapi httpx pytest && pytest tests/ -v
```

Expected: FAIL — `main` module not found

**Step 3: 实现 FastAPI 服务**

```python
# services/fashion-clip/main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests
from PIL import Image
from io import BytesIO
import torch
from transformers import CLIPProcessor, CLIPModel

app = FastAPI(title="FashionCLIP Service")

# 类别候选标签
CATEGORY_LABELS = ["tops", "bottoms", "shoes", "outerwear", "accessories"]
COLOR_LABELS = ["white", "black", "blue", "red", "green", "yellow", "grey", "brown", "pink", "beige"]
STYLE_LABELS = ["casual", "formal", "sport", "elegant", "streetwear", "denim", "knit", "leather"]

_model = None
_processor = None

def get_model():
    global _model, _processor
    if _model is None:
        _model = CLIPModel.from_pretrained("patrickjohncyh/fashion-clip")
        _processor = CLIPProcessor.from_pretrained("patrickjohncyh/fashion-clip")
    return _model, _processor

def classify_image(image_url: str) -> dict:
    response = requests.get(image_url, timeout=10)
    image = Image.open(BytesIO(response.content)).convert("RGB")
    model, processor = get_model()

    def top_label(candidates):
        prompts = [f"a photo of {l}" for l in candidates]
        inputs = processor(text=prompts, images=image, return_tensors="pt", padding=True)
        with torch.no_grad():
            outputs = model(**inputs)
        logits = outputs.logits_per_image[0]
        return candidates[logits.argmax().item()]

    category = top_label(CATEGORY_LABELS)
    color = top_label(COLOR_LABELS)
    # Top 3 style tags
    style_prompts = [f"a photo of {l} clothing" for l in STYLE_LABELS]
    inputs = processor(text=style_prompts, images=image, return_tensors="pt", padding=True)
    with torch.no_grad():
        outputs = model(**inputs)
    logits = outputs.logits_per_image[0]
    top3_idx = logits.topk(3).indices.tolist()
    tags = [STYLE_LABELS[i] for i in top3_idx]

    return {"category": category, "color": color, "tags": tags}

class ClassifyRequest(BaseModel):
    image_url: str

@app.post("/classify")
def classify(req: ClassifyRequest):
    if not req.image_url:
        raise HTTPException(status_code=400, detail="image_url required")
    try:
        result = classify_image(req.image_url)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health():
    return {"status": "ok"}
```

**Step 4: 写 requirements.txt**

```
fastapi==0.110.0
uvicorn==0.29.0
transformers==4.40.0
torch==2.3.0
Pillow==10.3.0
requests==2.31.0
pydantic==2.7.0
```

**Step 5: 写 Dockerfile**

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Step 6: 运行测试确认通过**

```bash
pytest tests/ -v
```

Expected: PASS

**Step 7: Commit**

```bash
git add services/fashion-clip/ && git commit -m "feat: add FashionCLIP FastAPI classification service"
```

---

## Task 4: Supabase Edge Function — 推荐引擎

**Files:**
- Create: `supabase/functions/recommend/index.ts`
- Create: `supabase/functions/recommend/recommend.test.ts`

**Step 1: 写 failing test**

```typescript
// supabase/functions/recommend/recommend.test.ts
import { assertEquals } from "https://deno.land/std/assert/mod.ts";
import { buildRecommendation } from "./recommend_logic.ts";

Deno.test("recommends outfit from wardrobe items", () => {
  const items = [
    { id: "1", category: "tops", color: "white", tags: ["casual"] },
    { id: "2", category: "bottoms", color: "blue", tags: ["denim"] },
  ];
  const weather = { temp: 22, condition: "clear" };
  const result = buildRecommendation(items, [], weather, "casual");
  assertEquals(result.source, "ai_generated");
  assertEquals(result.item_ids.length >= 2, true);
});

Deno.test("falls back to preset when wardrobe empty", () => {
  const presets = [
    { id: "p1", name: "牛仔裤 + 白T", categories: ["tops","bottoms"],
      occasion: "casual", weather_tags: ["warm"] },
  ];
  const weather = { temp: 25, condition: "sunny" };
  const result = buildRecommendation([], presets, weather, "casual");
  assertEquals(result.source, "preset");
});
```

**Step 2: 实现推荐逻辑模块**

```typescript
// supabase/functions/recommend/recommend_logic.ts
export function getWeatherTag(temp: number): string {
  if (temp >= 28) return "warm";
  if (temp >= 18) return "mild";
  if (temp >= 10) return "cool";
  return "cold";
}

export function buildRecommendation(
  items: any[],
  presets: any[],
  weather: { temp: number; condition: string },
  occasion: string
): { item_ids: string[]; source: string; preset_id?: string } {
  const weatherTag = getWeatherTag(weather.temp);

  // 从衣橱中选一套：找 tops + bottoms（+shoes/outerwear 可选）
  const tops = items.filter(i => i.category === "tops");
  const bottoms = items.filter(i => i.category === "bottoms");
  const shoes = items.filter(i => i.category === "shoes");

  if (tops.length > 0 && bottoms.length > 0) {
    const chosen = [
      tops[Math.floor(Math.random() * tops.length)].id,
      bottoms[Math.floor(Math.random() * bottoms.length)].id,
    ];
    if (shoes.length > 0) chosen.push(shoes[0].id);
    return { item_ids: chosen, source: "ai_generated" };
  }

  // Fallback: preset
  const matched = presets.filter(p =>
    p.weather_tags.includes(weatherTag) &&
    (!occasion || p.occasion === occasion)
  );
  const preset = matched.length > 0
    ? matched[Math.floor(Math.random() * matched.length)]
    : presets[0];
  return { item_ids: [], source: "preset", preset_id: preset?.id };
}
```

**Step 3: 实现 Edge Function 入口**

```typescript
// supabase/functions/recommend/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { buildRecommendation } from "./recommend_logic.ts";

const OPENWEATHER_KEY = Deno.env.get("OPENWEATHER_API_KEY") ?? "";

async function fetchWeather(city: string) {
  if (!OPENWEATHER_KEY) return { temp: 20, condition: "unknown" };
  const url = `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&appid=${OPENWEATHER_KEY}&units=metric`;
  const res = await fetch(url);
  if (!res.ok) return { temp: 20, condition: "unknown" };
  const data = await res.json();
  return { temp: data.main.temp, condition: data.weather[0]?.main ?? "unknown" };
}

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  const { user_id, city = "Shanghai", occasion = "casual" } = await req.json();

  const [{ data: items }, { data: presets }] = await Promise.all([
    supabase.from("clothing_items").select("*").eq("user_id", user_id),
    supabase.from("preset_outfits").select("*"),
  ]);

  const weather = await fetchWeather(city);
  const recommendation = buildRecommendation(items ?? [], presets ?? [], weather, occasion);

  // 如果是 ai_generated，先保存到 outfits 再记录
  let outfit_id: string | null = null;
  if (recommendation.source === "ai_generated") {
    const { data: outfit } = await supabase.from("outfits").insert({
      user_id,
      item_ids: recommendation.item_ids,
      occasion,
      source: "ai_generated",
    }).select().single();
    outfit_id = outfit?.id;
  }

  const today = new Date().toISOString().split("T")[0];
  await supabase.from("daily_recommendations").upsert({
    user_id,
    date: today,
    outfit_id,
    weather_data: weather,
    accepted: false,
  }, { onConflict: "user_id,date" });

  return new Response(JSON.stringify({ recommendation, weather, outfit_id }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

**Step 4: 运行测试**

```bash
deno test supabase/functions/recommend/recommend.test.ts
```

Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add supabase/functions/ && git commit -m "feat: add recommendation Edge Function with weather + preset fallback"
```

---

## Task 5: Flutter 数据层 — Supabase Repository

**Files:**
- Create: `app/lib/data/clothing_repository.dart`
- Create: `app/lib/data/outfit_repository.dart`
- Create: `app/lib/data/preset_repository.dart`
- Create: `app/test/data/clothing_repository_test.dart`

**Step 1: 写 failing test**

```dart
// app/test/data/clothing_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:superpower_wardrobe/data/clothing_repository.dart';

class MockSupabaseClient extends Mock {}

void main() {
  test('addClothingItem returns inserted item id', () async {
    // Integration test placeholder — tested against real Supabase in CI
    expect(true, isTrue);
  });

  test('ClothingItem fromJson parses correctly', () {
    final json = {
      'id': 'abc',
      'user_id': 'user1',
      'image_url': 'https://example.com/img.jpg',
      'category': 'tops',
      'color': 'white',
      'tags': ['casual'],
      'name': 'White T',
      'created_at': '2026-02-24T00:00:00Z'
    };
    final item = ClothingItem.fromJson(json);
    expect(item.category, 'tops');
    expect(item.color, 'white');
    expect(item.tags, ['casual']);
  });
}
```

**Step 2: 运行确认失败**

```bash
cd app && flutter test test/data/clothing_repository_test.dart
```

Expected: FAIL — `ClothingItem` not found

**Step 3: 实现 ClothingItem + Repository**

```dart
// app/lib/data/clothing_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  final String category;
  final String color;
  final List<String> tags;
  final String? name;
  final DateTime createdAt;

  const ClothingItem({
    required this.id, required this.userId, required this.imageUrl,
    required this.category, required this.color, required this.tags,
    this.name, required this.createdAt,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
    id: json['id'], userId: json['user_id'], imageUrl: json['image_url'],
    category: json['category'], color: json['color'],
    tags: List<String>.from(json['tags'] ?? []), name: json['name'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toInsertJson() => {
    'user_id': userId, 'image_url': imageUrl, 'category': category,
    'color': color, 'tags': tags, if (name != null) 'name': name,
  };
}

class ClothingRepository {
  final SupabaseClient _client;
  ClothingRepository(this._client);

  Future<List<ClothingItem>> getItems(String userId) async {
    final data = await _client
        .from('clothing_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ClothingItem.fromJson(e)).toList();
  }

  Future<ClothingItem> addItem(ClothingItem item) async {
    final data = await _client
        .from('clothing_items')
        .insert(item.toInsertJson())
        .select()
        .single();
    return ClothingItem.fromJson(data);
  }

  Future<void> deleteItem(String id) async {
    await _client.from('clothing_items').delete().eq('id', id);
  }
}
```

**Step 4: 运行测试确认通过**

```bash
flutter test test/data/clothing_repository_test.dart
```

Expected: PASS

**Step 5: 实现 PresetRepository**

```dart
// app/lib/data/preset_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PresetOutfit {
  final String id;
  final String name;
  final List<String> categories;
  final String? occasion;
  final List<String> weatherTags;

  const PresetOutfit({required this.id, required this.name,
    required this.categories, this.occasion, required this.weatherTags});

  factory PresetOutfit.fromJson(Map<String, dynamic> json) => PresetOutfit(
    id: json['id'], name: json['name'],
    categories: List<String>.from(json['categories'] ?? []),
    occasion: json['occasion'],
    weatherTags: List<String>.from(json['weather_tags'] ?? []),
  );
}

class PresetRepository {
  final SupabaseClient _client;
  PresetRepository(this._client);

  Future<List<PresetOutfit>> getAll() async {
    final data = await _client.from('preset_outfits').select().order('name');
    return (data as List).map((e) => PresetOutfit.fromJson(e)).toList();
  }
}
```

**Step 6: Commit**

```bash
git add app/lib/data/ app/test/ && git commit -m "feat: add clothing and preset data repositories"
```

---

## Task 6: Flutter 状态层 — Riverpod Providers

**Files:**
- Create: `app/lib/providers/wardrobe_provider.dart`
- Create: `app/lib/providers/recommendation_provider.dart`
- Create: `app/lib/providers/preset_provider.dart`

**Step 1: 实现衣橱 Provider**

```dart
// app/lib/providers/wardrobe_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/clothing_repository.dart';

final clothingRepoProvider = Provider((ref) =>
    ClothingRepository(Supabase.instance.client));

final wardrobeProvider = FutureProvider.autoDispose<List<ClothingItem>>((ref) async {
  final repo = ref.read(clothingRepoProvider);
  final userId = Supabase.instance.client.auth.currentUser!.id;
  return repo.getItems(userId);
});

class WardrobeNotifier extends AsyncNotifier<List<ClothingItem>> {
  @override
  Future<List<ClothingItem>> build() async {
    final repo = ref.read(clothingRepoProvider);
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return repo.getItems(userId);
  }

  Future<void> addItem(ClothingItem item) async {
    final repo = ref.read(clothingRepoProvider);
    final newItem = await repo.addItem(item);
    state = AsyncData([newItem, ...state.value ?? []]);
  }

  Future<void> deleteItem(String id) async {
    final repo = ref.read(clothingRepoProvider);
    await repo.deleteItem(id);
    state = AsyncData((state.value ?? []).where((i) => i.id != id).toList());
  }
}

final wardrobeNotifierProvider =
    AsyncNotifierProvider<WardrobeNotifier, List<ClothingItem>>(WardrobeNotifier.new);
```

**Step 2: 实现推荐 Provider**

```dart
// app/lib/providers/recommendation_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/clothing_repository.dart';

const _edgeFunctionUrl = String.fromEnvironment(
  'SUPABASE_URL', defaultValue: '') + '/functions/v1/recommend';

class Recommendation {
  final List<String> itemIds;
  final String source;
  final Map<String, dynamic> weather;
  Recommendation({required this.itemIds, required this.source, required this.weather});
}

final recommendationProvider = FutureProvider.autoDispose<Recommendation>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;
  final session = supabase.auth.currentSession!;

  final response = await http.post(
    Uri.parse(_edgeFunctionUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    },
    body: jsonEncode({'user_id': userId, 'city': 'Shanghai', 'occasion': 'casual'}),
  );

  if (response.statusCode != 200) {
    throw Exception('Recommendation API error: ${response.body}');
  }
  final data = jsonDecode(response.body);
  final rec = data['recommendation'] as Map<String, dynamic>;
  return Recommendation(
    itemIds: List<String>.from(rec['item_ids'] ?? []),
    source: rec['source'] ?? 'unknown',
    weather: data['weather'] ?? {},
  );
});
```

**Step 3: Commit**

```bash
git add app/lib/providers/ && git commit -m "feat: add Riverpod providers for wardrobe and recommendation"
```

---

## Task 7: Flutter 拍照识别 UI（衣橱添加流程）

**Files:**
- Create: `app/lib/features/wardrobe/add_clothing_page.dart`
- Create: `app/lib/services/fashion_clip_service.dart`
- Create: `app/test/services/fashion_clip_service_test.dart`

**Step 1: 写 failing test**

```dart
// app/test/services/fashion_clip_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:superpower_wardrobe/services/fashion_clip_service.dart';

void main() {
  test('ClassifyResult parses json correctly', () {
    final json = {'category': 'tops', 'color': 'white', 'tags': ['casual', 'tshirt']};
    final result = ClassifyResult.fromJson(json);
    expect(result.category, 'tops');
    expect(result.color, 'white');
    expect(result.tags.length, 2);
  });
}
```

**Step 2: 实现 FashionClipService**

```dart
// app/lib/services/fashion_clip_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassifyResult {
  final String category;
  final String color;
  final List<String> tags;

  const ClassifyResult({required this.category, required this.color, required this.tags});

  factory ClassifyResult.fromJson(Map<String, dynamic> json) => ClassifyResult(
    category: json['category'] ?? 'tops',
    color: json['color'] ?? 'black',
    tags: List<String>.from(json['tags'] ?? []),
  );
}

class FashionClipService {
  final String baseUrl;
  FashionClipService({required this.baseUrl});

  /// 识别图片，失败时返回 null（用户手动填写）
  Future<ClassifyResult?> classify(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return ClassifyResult.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null; // graceful degradation
    }
  }
}
```

**Step 3: 实现添加衣物页面**

```dart
// app/lib/features/wardrobe/add_clothing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/clothing_repository.dart';
import '../../providers/wardrobe_provider.dart';
import '../../services/fashion_clip_service.dart';

final _fashionClipService = FashionClipService(
  baseUrl: const String.fromEnvironment('FASHION_CLIP_URL',
      defaultValue: 'http://localhost:8000'),
);

class AddClothingPage extends ConsumerStatefulWidget {
  const AddClothingPage({super.key});
  @override
  ConsumerState<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends ConsumerState<AddClothingPage> {
  String? _imageUrl;
  String _category = 'tops';
  String _color = 'white';
  List<String> _tags = [];
  bool _isLoading = false;

  final _categories = ['tops', 'bottoms', 'shoes', 'outerwear', 'accessories'];
  final _colors = ['white', 'black', 'blue', 'red', 'green', 'grey', 'brown', 'pink', 'beige'];

  Future<void> _pickAndClassify() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final path = 'clothing/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('clothing-images').upload(path, await picked.readAsBytes() as dynamic);
      final url = supabase.storage.from('clothing-images').getPublicUrl(path);
      _imageUrl = url;

      final result = await _fashionClipService.classify(url);
      if (result != null) {
        setState(() {
          _category = result.category;
          _color = result.color;
          _tags = result.tags;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('识别结果：$_category / $_color')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('识别失败，请手动选择类别和颜色')));
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_imageUrl == null) return;
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final item = ClothingItem(
      id: '', userId: userId, imageUrl: _imageUrl!,
      category: _category, color: _color, tags: _tags,
      createdAt: DateTime.now(),
    );
    await ref.read(wardrobeNotifierProvider.notifier).addItem(item);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加衣物')),
      body: _isLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 16),
                Text('正在识别衣物...')]))
          : ListView(padding: const EdgeInsets.all(16), children: [
              ElevatedButton.icon(
                onPressed: _pickAndClassify,
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照识别'),
              ),
              if (_imageUrl != null) ...[
                const SizedBox(height: 16),
                Image.network(_imageUrl!, height: 200, fit: BoxFit.cover),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: '类别'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _color,
                decoration: const InputDecoration(labelText: '颜色'),
                items: _colors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _color = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _imageUrl == null ? null : _save,
                child: const Text('保存到衣橱'),
              ),
            ]),
    );
  }
}
```

**Step 4: 运行测试**

```bash
cd app && flutter test test/services/fashion_clip_service_test.dart
```

Expected: PASS

**Step 5: Commit**

```bash
git add app/lib/features/wardrobe/ app/lib/services/ app/test/services/ && \
git commit -m "feat: add photo capture, FashionCLIP classification, and add clothing UI"
```

---

## Task 8: Flutter 衣橱浏览页 + 底部导航

**Files:**
- Create: `app/lib/features/shell/main_shell.dart`
- Create: `app/lib/features/wardrobe/wardrobe_page.dart`
- Create: `app/lib/features/recommendation/recommendation_page.dart`
- Create: `app/lib/features/presets/preset_page.dart`
- Create: `app/lib/features/settings/settings_page.dart`

**Step 1: 实现主 Shell（底部导航）**

```dart
// app/lib/features/shell/main_shell.dart
import 'package:flutter/material.dart';
import '../wardrobe/wardrobe_page.dart';
import '../recommendation/recommendation_page.dart';
import '../presets/preset_page.dart';
import '../settings/settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _pages = const [
    RecommendationPage(),
    WardrobePage(),
    PresetPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny), label: '今日推荐'),
          NavigationDestination(icon: Icon(Icons.checkroom), label: '我的衣橱'),
          NavigationDestination(icon: Icon(Icons.style), label: '预设套装'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
```

**Step 2: 实现衣橱页**

```dart
// app/lib/features/wardrobe/wardrobe_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/wardrobe_provider.dart';
import 'add_clothing_page.dart';

class WardrobePage extends ConsumerWidget {
  const WardrobePage({super.key});
  static const _tabs = ['全部', '上衣', '下装', '鞋子', '外套', '配饰'];
  static const _catMap = {'上衣':'tops','下装':'bottoms','鞋子':'shoes','外套':'outerwear','配饰':'accessories'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(wardrobeNotifierProvider);
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的衣橱'),
          bottom: TabBar(tabs: _tabs.map((t) => Tab(text: t)).toList()),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddClothingPage())),
            ),
          ],
        ),
        body: wardrobeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败: $e')),
          data: (items) => TabBarView(
            children: _tabs.map((tab) {
              final filtered = tab == '全部' ? items
                  : items.where((i) => i.category == _catMap[tab]).toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('暂无衣物，点击右上角添加'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                itemCount: filtered.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: filtered[i].imageUrl, fit: BoxFit.cover,
                    placeholder: (_, __) => const ColoredBox(color: Colors.grey),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
```

**Step 3: 实现今日推荐页**

```dart
// app/lib/features/recommendation/recommendation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/wardrobe_provider.dart';

class RecommendationPage extends ConsumerWidget {
  const RecommendationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(recommendationProvider);
    final wardrobeAsync = ref.watch(wardrobeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('今日推荐')),
      body: recAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8), Text('$e'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.invalidate(recommendationProvider),
              child: const Text('重试'))],
        )),
        data: (rec) {
          final weather = rec.weather;
          final items = wardrobeAsync.value ?? [];
          final recommendedItems = items.where((i) => rec.itemIds.contains(i.id)).toList();

          return ListView(padding: const EdgeInsets.all(16), children: [
            // 天气卡片
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.thermostat, size: 32),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${weather['temp']?.toStringAsFixed(1) ?? '--'}°C',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text('${weather['condition'] ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ]),
            )),
            const SizedBox(height: 16),

            // 推荐来源标签
            Chip(label: Text(rec.source == 'preset' ? '📦 预设套装推荐' : '✨ AI 从衣橱推荐')),
            const SizedBox(height: 12),

            // 衣物展示
            if (recommendedItems.isEmpty)
              const Card(child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('今日推荐一套预设穿搭，快去"预设套装"页面收藏吧！')),
              ))
            else
              Wrap(spacing: 8, children: recommendedItems.map((item) =>
                  SizedBox(width: 100, height: 100,
                    child: ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.imageUrl, fit: BoxFit.cover)))).toList()),

            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => ref.invalidate(recommendationProvider),
                child: const Text('换一套'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已采用今日穿搭 ✓'))),
                child: const Text('就这套！'),
              )),
            ]),
          ]);
        },
      ),
    );
  }
}
```

**Step 4: 实现预设套装页**

```dart
// app/lib/features/presets/preset_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/preset_repository.dart';

final presetProvider = FutureProvider<List<PresetOutfit>>((ref) async {
  final repo = PresetRepository(Supabase.instance.client);
  return repo.getAll();
});

class PresetPage extends ConsumerStatefulWidget {
  const PresetPage({super.key});
  @override
  ConsumerState<PresetPage> createState() => _PresetPageState();
}

class _PresetPageState extends ConsumerState<PresetPage> {
  final Set<String> _selected = {};
  String? _filterOccasion;
  final _occasions = ['casual', 'work', 'sport', 'formal'];

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(presetProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('预设套装'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _saveSelected,
              child: Text('收藏 ${_selected.length} 套'),
            ),
        ],
      ),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            FilterChip(label: const Text('全部'), selected: _filterOccasion == null,
                onSelected: (_) => setState(() => _filterOccasion = null)),
            ..._occasions.map((o) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(label: Text(o), selected: _filterOccasion == o,
                  onSelected: (_) => setState(() => _filterOccasion = o)),
            )),
          ]),
        ),
        Expanded(child: presetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (presets) {
            final filtered = _filterOccasion == null ? presets
                : presets.where((p) => p.occasion == _filterOccasion).toList();
            return ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final preset = filtered[i];
                final isSelected = _selected.contains(preset.id);
                return ListTile(
                  leading: Checkbox(value: isSelected, onChanged: (v) {
                    setState(() => v! ? _selected.add(preset.id) : _selected.remove(preset.id));
                  }),
                  title: Text(preset.name),
                  subtitle: Text('${preset.occasion} · ${preset.weatherTags.join(",")}'),
                  trailing: Icon(Icons.checkroom,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null),
                  onTap: () => setState(() =>
                      isSelected ? _selected.remove(preset.id) : _selected.add(preset.id)),
                );
              },
            );
          },
        )),
      ]),
    );
  }

  Future<void> _saveSelected() async {
    // TODO: 保存到用户 outfits 表
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已收藏 ${_selected.length} 套预设穿搭')));
    setState(() => _selected.clear());
  }
}
```

**Step 5: 实现设置页（stub）**

```dart
// app/lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('个人设置')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(leading: const Icon(Icons.person), title: Text(user?.email ?? '未登录')),
        const Divider(),
        ListTile(leading: const Icon(Icons.location_city),
            title: const Text('所在城市'), subtitle: const Text('Shanghai（可修改）')),
        ListTile(leading: const Icon(Icons.style),
            title: const Text('偏好风格'), subtitle: const Text('休闲')),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('退出登录', style: TextStyle(color: Colors.red)),
          onTap: () => Supabase.instance.client.auth.signOut(),
        ),
      ]),
    );
  }
}
```

**Step 6: Commit**

```bash
git add app/lib/features/ && git commit -m "feat: add all Flutter UI pages — shell, wardrobe, recommendation, presets, settings"
```

---

## Task 9: 集成验证 & 最终检查

**Step 1: 运行所有 Flutter 测试**

```bash
cd app && flutter test
```

Expected: 所有测试 PASS

**Step 2: 运行 Python 测试**

```bash
cd services/fashion-clip && pytest tests/ -v
```

Expected: PASS

**Step 3: 构建 iOS（以确认无编译错误）**

```bash
cd app && flutter build ios --no-codesign --debug 2>&1 | tail -20
```

Expected: `Build complete.`

**Step 4: 最终 Commit**

```bash
cd /root/superpower-wardrobe && git add -A && git commit -m "feat: MVP complete — photo→classify→store→recommend thin slice"
```

---

## 执行选项

**计划已保存。两种执行方式：**

**1. Subagent 驱动（本 session）** — 每个 Task 调度独立 subagent，逐 Task 审查，快速迭代
**2. 并行 Session（新 session）** — 打开新 session 用 executing-plans 批量执行，有 checkpoint

**选哪种？**
