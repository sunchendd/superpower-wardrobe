# 超能力衣橱重构设计文档

> 参考氢气衣橱 App，重构为原生双端应用（SwiftUI + Kotlin Compose），保留 Supabase 后端。

## 1. 系统架构

```
┌─────────────────────────────────────────────────┐
│              客户端 (Native Apps)                 │
│  ┌──────────────┐    ┌──────────────────┐       │
│  │ iOS (SwiftUI)│    │ Android (Compose)│       │
│  └──────┬───────┘    └────────┬─────────┘       │
│         └──────────┬──────────┘                  │
│              Supabase SDK                        │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────┐
│              Supabase Cloud                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐│
│  │   Auth   │ │ Storage  │ │   PostgreSQL DB  ││
│  └──────────┘ └──────────┘ └──────────────────┘│
│  ┌──────────────────────────────────────────┐   │
│  │         Edge Functions (Deno)            │   │
│  │  - recommend (穿搭推荐)                   │   │
│  │  - purchase-suggest (购买推荐)            │   │
│  │  - weather (天气服务)                     │   │
│  └──────────────────────┬───────────────────┘   │
└─────────────────────────┬───────────────────────┘
                          │
┌─────────────────────────┴───────────────────────┐
│           AI 微服务 (Docker)                      │
│  ┌──────────────────┐  ┌────────────────────┐   │
│  │  FashionCLIP API │  │  推荐引擎 (Python)  │   │
│  │  (分类/识别)      │  │  (个性化学习)       │   │
│  └──────────────────┘  └────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### 核心决策

- **双端共享**：通过 Supabase SDK 统一 API 调用，iOS/Android 业务逻辑保持一致
- **Auth**：Supabase Auth 提供手机号/邮箱/社交登录
- **图片存储**：Supabase Storage 管理衣物图片和穿搭照片
- **AI 服务独立**：FashionCLIP 和推荐引擎作为 Docker 微服务，Edge Functions 作为网关调用

## 2. 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| iOS 客户端 | SwiftUI + Swift Concurrency | 现代声明式 UI |
| Android 客户端 | Kotlin Compose + Coroutines | 现代声明式 UI |
| 后端 BaaS | Supabase (PostgreSQL + Auth + Storage) | 已有基础设施 |
| 服务端逻辑 | Supabase Edge Functions (Deno/TypeScript) | 推荐、天气等 |
| AI 识别 | FashionCLIP (FastAPI + PyTorch) | 衣物分类服务 |
| 推荐引擎 | Python 微服务 | 规则 + AI 混合推荐 |
| 部署 | Docker Compose + Nginx | 容器化部署 |

## 3. 数据库设计

### 3.1 users — 用户资料

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | Supabase Auth UID |
| email | text | 邮箱 |
| phone | text | 手机号 |
| avatar_url | text | 头像 |
| body_info | jsonb | 身高/体重等身材信息 |
| style_preferences | text[] | 风格偏好标签 |
| location | text | 常驻城市 |
| created_at | timestamptz | 创建时间 |

### 3.2 categories — 衣物品类

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | |
| name | text | 品类名（上衣/下装/外套/鞋子/配饰）|
| icon | text | 图标标识 |
| sort_order | int | 排序序号 |
| parent_id | uuid FK | 父分类（支持子分类）|

### 3.3 clothing_items — 衣物单品（核心表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | |
| user_id | uuid FK → users | 所属用户 |
| category_id | uuid FK → categories | 品类 |
| name | text | 名称 |
| image_url | text | 图片地址 |
| brand | text | 品牌 |
| color | text | 颜色 |
| season | text[] | 适用季节 |
| style_tags | text[] | 风格标签 |
| purchase_price | numeric | 购入价格 |
| purchase_date | date | 购入日期 |
| purchase_url | text | 购买链接 |
| wear_count | int default 0 | 穿着次数 |
| status | text | 在用/闲置/淘汰 |
| created_at | timestamptz | 录入时间 |

### 3.4 outfits — 穿搭组合

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | |
| user_id | uuid FK | |
| name | text | 穿搭名称 |
| occasion | text | 场合 |
| rating | int | 评分 |
| source | text | 手动/AI推荐/预设 |

### 3.5 outfit_items — 穿搭-单品关联

| 字段 | 类型 | 说明 |
|------|------|------|
| outfit_id | uuid FK → outfits | |
| clothing_item_id | uuid FK → clothing_items | |

### 3.6 outfit_diary — 穿搭日记

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | |
| user_id | uuid FK | |
| date | date | 日期 |
| outfit_id | uuid FK | 关联穿搭 |
| photo_url | text | 穿搭照片 |
| note | text | 笔记 |
| weather_data | jsonb | 当日天气 |
| mood | text | 心情 |
| shared_at | timestamptz | 分享时间（null=未分享）|

### 3.7 daily_recommendations — 每日推荐

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | |
| user_id | uuid FK | |
| date | date | 推荐日期 |
| outfit_id | uuid FK | 推荐穿搭 |
| weather_data | jsonb | 天气数据 |
| reason_text | text | 推荐理由 |
| accepted | boolean | 是否采纳 |
| feedback_score | int | 反馈评分 |

### 3.8 purchase_recommendations — 购买推荐

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | |
| user_id | uuid FK | |
| category_id | uuid FK | 推荐品类 |
| reason | text | 推荐原因 |
| style_tags | text[] | 风格标签 |
| season | text | 季节 |
| priority | int | 优先级 |
| status | text | 新推荐/已查看/已购买/已忽略 |

### 3.9 travel_plans — 旅行穿搭计划

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | |
| user_id | uuid FK | |
| title | text | 旅行标题 |
| destination | text | 目的地 |
| start_date | date | 开始日期 |
| end_date | date | 结束日期 |

### 3.10 travel_plan_outfits — 旅行计划-穿搭关联

| 字段 | 类型 | 说明 |
|------|------|------|
| travel_plan_id | uuid FK | |
| date | date | 日期 |
| outfit_id | uuid FK | 当天穿搭 |

## 4. 功能模块设计

### 4.1 Tab 结构（5 Tab，氢气衣橱风格）

```
┌─────┬─────┬─────┬─────┬─────┐
│ 推荐 │ 衣橱 │  +  │ 统计 │ 我的 │
└─────┴─────┴─────┴─────┴─────┘
```

### 4.2 Tab 1 — 每日推荐（首页）

- 今日天气卡片（温度、天气图标、穿衣建议）
- AI 推荐穿搭（展示完整搭配，可左右滑动切换方案）
- 一键「穿这套」→ 自动记录到穿搭日记
- 购买推荐区（你可能需要的单品）

### 4.3 Tab 2 — 我的衣橱

- 顶部品类 Tab 切换（全部/上衣/下装/外套/鞋子/配饰）
- 瀑布流网格展示衣物，长按编辑/删除
- 筛选器：颜色、季节、风格、品牌
- 搜索栏：快速找到特定单品

### 4.4 Tab 3 — 快速录入（中间大+号）

- **拍照录入**：打开相机 → 拍完 AI 自动识别品类/颜色/风格
- **相册导入**：选择图片 → AI 识别 + 手动微调
- **电商链接导入**：粘贴淘宝/京东链接 → 抓取商品图和信息
- 录入后进入编辑页：确认/修改 AI 识别的属性

### 4.5 Tab 4 — 数据统计

- 衣橱总览：总件数、总花费、平均单价
- 品类分布饼图
- 色系分布条形图
- 季节分布
- 利用率排行（最常穿 vs 最闲置）
- 月度穿衣成本（purchase_price / wear_count）

### 4.6 Tab 5 — 我的

- 穿搭日历（日历视图，点击日期查看当天穿搭照片）
- 穿搭日记列表（时间线形式浏览）
- 旅行穿搭规划（创建旅行 → 每天分配穿搭）
- 个人设置（身材信息、风格偏好、地理位置、通知设置）

## 5. AI 与推荐引擎

### 5.1 FashionCLIP 识别服务（增强）

现有能力保持：品类识别、颜色识别、风格识别。新增：

- **抠图处理**：去除背景，让衣物展示更美观
- **多标签输出**：同时识别材质、图案等
- **置信度分数**：低置信度时提示用户手动确认

### 5.2 天气穿搭推荐引擎

```
输入：用户位置 → OpenWeather API → 温度/湿度/天气
         ↓
规则层：温度区间 → 推荐品类组合
  >30°C → 短袖+短裤+凉鞋
  20-30°C → 薄衬衫+长裤+运动鞋
  10-20°C → 卫衣+外套+长裤+运动鞋
  <10°C → 保暖内衣+毛衣+厚外套+靴子
         ↓
匹配层：从用户衣橱中筛选匹配单品
         ↓
排序层：按穿着频率、用户偏好、颜色搭配打分
         ↓
输出：Top 3 推荐穿搭方案
```

### 5.3 购买推荐引擎

- **衣橱缺口分析**：统计品类/颜色/风格分布，发现短板
  - 例：8 件上衣但只有 2 条裤子 → 推荐裤子
  - 例：全是黑白灰 → 推荐彩色单品
- **季节预测**：换季前推荐即将需要的品类
- **风格匹配**：根据用户 style_preferences 推荐同风格商品
- 初期使用规则引擎，后期可接入电商 API 展示真实商品

### 5.4 数据反馈闭环

- 用户接受/拒绝推荐 → 更新偏好模型
- 穿搭日记的衣物 → 更新 wear_count
- 长期不穿的衣物 → 提示「断舍离」

## 6. 今日穿搭拍照流程

```
拍照/选照片 → 自动关联今日推荐的 outfit
            → 用户可手动调整关联的单品
            → 添加心情/笔记
            → 保存 → 可一键分享到微信/微博/小红书
```

## 7. 与现有代码的关系

### 保留复用

- Supabase 项目配置（Auth, Storage, Database）
- FashionCLIP 微服务（`services/fashion-clip/`）
- Docker Compose 部署架构
- Edge Functions 框架（`supabase/functions/`）
- Makefile 部署脚本

### 重构替换

- Flutter 应用 → SwiftUI (iOS) + Kotlin Compose (Android)
- 数据库 schema → 从 4 表扩展为 10 表
- 推荐引擎 → 重写为规则 + AI 混合引擎
- Web Demo → 可选保留作为调试工具

### 新增

- iOS 原生工程（SwiftUI）
- Android 原生工程（Kotlin Compose）
- 购买推荐 Edge Function
- 电商链接解析服务
- 社交分享集成
