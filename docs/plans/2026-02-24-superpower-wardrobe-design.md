# Superpower Wardrobe — MVP Design Document

> **Date:** 2026-02-24  
> **Status:** Approved  
> **Scope:** MVP v1 — 拍照 → 辨识 → 储存 → 推荐（试穿 v2）

---

## 1. 整体架构

**平台：** Flutter iOS（mobile-first）  
**架构：** Flutter + Supabase + Python 微服务（方案 A）

```
┌─────────────────────────────────────────────┐
│            Flutter iOS App                  │
│  - 拍照/相册选图                              │
│  - 衣橱浏览（列表/网格）                       │
│  - 每日推荐穿搭页                             │
│  - Supabase Auth（邮箱/Apple Sign-In）        │
└────────────┬──────────────┬─────────────────┘
             │              │
             ▼              ▼
    ┌─────────────┐   ┌───────────────────┐
    │  Supabase   │   │  FashionCLIP API  │
    │  - Auth     │   │  Python FastAPI   │
    │  - Storage  │   │  部署: Fly.io     │
    │  - Postgres │   │  POST /classify   │
    │  - Edge Fn  │   │  返回: 类别+颜色   │
    └─────────────┘   └───────────────────┘
           │
           ▼
    ┌─────────────────────┐
    │  Edge Function      │
    │  /recommend         │
    │  - 读用户衣橱        │
    │  - 调 OpenWeather   │
    │  - 输出今日穿搭      │
    └─────────────────────┘
```

**核心数据流：**
1. 用户拍照 → Flutter 上传图片到 Supabase Storage
2. 调 FashionCLIP FastAPI → 返回 `{category, color, tags}`
3. 存入 Supabase `clothing_items` 表
4. 每日打开 App → 调 Edge Function `/recommend` → 返回今日穿搭组合

---

## 2. 数据库结构

```sql
-- 用户衣橱：每件实际衣物
clothing_items
  id uuid PK
  user_id uuid FK
  image_url text
  category text       -- tops / bottoms / shoes / outerwear / accessories
  color text          -- white / black / blue / ...
  tags text[]         -- ["casual","denim","slim"]（FashionCLIP 输出）
  name text           -- 用户可自定义，可选
  created_at timestamptz

-- 穿搭组合：多件衣物组成一套
outfits
  id uuid PK
  user_id uuid FK
  item_ids uuid[]     -- clothing_items id 数组
  occasion text       -- casual / work / sport / formal
  source text         -- 'ai_generated' | 'preset' | 'user_created'
  created_at timestamptz

-- 内置常规模板
preset_outfits
  id uuid PK
  name text           -- "牛仔裤 + 白T" / "黑西裤 + 白衬衫"
  categories text[]   -- [tops, bottoms]
  occasion text
  weather_tags text[] -- ["warm","mild"]

-- 每日推荐记录
daily_recommendations
  id uuid PK
  user_id uuid FK
  date date
  outfit_id uuid FK
  weather_data jsonb  -- { temp, condition, city }
  accepted bool
```

**推荐逻辑：**
- 优先从用户真实衣橱匹配
- 用户衣橱 < 3 件时 fallback 到 `preset_outfits`（按天气+场合匹配）
- 用户可在「预设套装」页多选 preset，收藏到自己的穿搭列表

---

## 3. Flutter App 页面结构

```
底部导航栏（4 tab）
├── 🏠 今日推荐
│   ├── 天气卡片（城市/温度/状况）
│   ├── 推荐穿搭组合（衣物图片拼图）
│   ├── 「换一套」按钮
│   └── 「采用」/ 「加入日历」
│
├── 👕 我的衣橱
│   ├── 分类 tab（全部/上衣/下装/鞋/外套）
│   ├── 网格列表（衣物卡片）
│   └── ＋ 拍照添加按钮
│       ├── 拍照 / 相册选图
│       ├── 上传 → 调 FashionCLIP
│       └── 确认识别结果（可修正）
│
├── 📦 预设套装（Preset Browse）
│   ├── 按场合筛选（日常/通勤/运动/正式）
│   ├── 套装卡片列表
│   └── 多选 → 「加入我的穿搭」
│
└── 👤 个人设置
    ├── 偏好风格（休闲/商务/运动）
    ├── 所在城市（用于天气）
    └── 账号（Supabase Auth）
```

**Flutter 技术选型：**
- `supabase_flutter` — auth + storage + db
- `image_picker` — 拍照/相册
- `http` — 调 FashionCLIP FastAPI
- `riverpod` — 状态管理
- `cached_network_image` — 衣物图片缓存

---

## 4. 错误处理 & 测试策略

### 错误处理

| 场景 | 处理方式 |
|------|---------|
| FashionCLIP 超时/不可用 | 跳过识别，让用户手动输入类别+颜色 |
| OpenWeather API 失败 | fallback：只按偏好风格推荐，不考虑天气 |
| Supabase 网络错误 | 本地缓存上次衣橱（`shared_preferences`），离线可浏览 |
| 图片上传失败 | 重试 3 次，失败后提示用户 |
| 衣橱为空时首次推荐 | 引导用户选 preset 套装或添加第一件衣物 |

### 测试策略（TDD）

- **单元测试**：推荐引擎逻辑（天气映射、类别匹配、fallback 逻辑）
- **Widget 测试**：衣橱列表、今日推荐卡片渲染
- **集成测试**：拍照→识别→存储完整流程（mock FashionCLIP）
- **Python 端**：FashionCLIP FastAPI `/classify` endpoint 单元测试

---

## 5. 交付范围（v1 MVP）

✅ 拍照识别 → 存入衣橱  
✅ 内置 preset 套装（可多选收藏）  
✅ 天气+偏好每日推荐  
✅ 基础 Auth（邮箱登录）  

🔜 v2：OOTDiffusion 数字分身试穿
