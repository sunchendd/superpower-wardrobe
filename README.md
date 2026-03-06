# 超能力衣橱 Superpower Wardrobe

> 参考氢气衣橱 App 设计，原生双端智能衣橱管理应用。

## ✨ 功能特性

| 功能 | 说明 |
|------|------|
| 🗂️ 衣物管理 | 拍照/相册/电商链接录入，AI 自动识别品类/颜色/风格 |
| 👔 品类分类 | 上衣/下装/外套/鞋子/配饰，支持子分类 |
| 🌤️ 每日推荐 | 基于天气+场合+个人偏好的智能穿搭推荐 |
| 🛒 购买建议 | 衣橱缺口分析 + 当季趋势 + 风格匹配 |
| 📸 穿搭日记 | 拍照记录每日穿搭，支持社交分享 |
| 📊 数据统计 | 品类/色系/利用率/花费可视化分析 |
| 📅 穿搭日历 | 日历视图回顾历史穿搭 |
| ✈️ 旅行规划 | 提前规划出行每日穿搭 |

## 🏗️ 技术架构

```
┌────────────────────────────────────────┐
│         客户端 (Native Apps)            │
│  iOS (SwiftUI)  │  Android (Compose)   │
│         └───── Supabase SDK ─────┘     │
└────────────────────┬───────────────────┘
                     │
┌────────────────────┴───────────────────┐
│          Supabase Cloud                │
│  Auth │ Storage │ PostgreSQL │ Edge Fn │
└────────────────────┬───────────────────┘
                     │
┌────────────────────┴───────────────────┐
│          AI 微服务 (Docker)             │
│  FashionCLIP (识别) │ 推荐引擎 (Python) │
└────────────────────────────────────────┘
```

## 📁 项目结构

```
superpower-wardrobe/
├── ios/                    # iOS 原生应用 (SwiftUI)
│   └── SuperWardrobe/
├── android/                # Android 原生应用 (Kotlin Compose)
│   └── superwardrobe/
├── services/
│   └── fashion-clip/       # FashionCLIP AI 识别服务 (FastAPI)
├── supabase/
│   ├── migrations/         # 数据库迁移 (PostgreSQL)
│   └── functions/          # Edge Functions
│       ├── recommend/      # 穿搭推荐
│       └── purchase-suggest/  # 购买建议
├── web-demo/               # Web 测试界面
├── docs/                   # 设计文档
├── docker-compose.yml      # Docker 部署
└── Makefile                # 一键部署命令
```

## 🚀 快速开始

### 1. 部署后端服务

```bash
cp .env.example .env       # 填写配置
source .env

# 部署 Supabase（数据库 + Edge Functions）
make setup-all ACCESS_TOKEN=your_token OPENWEATHER_KEY=your_key

# 启动 AI 服务（FashionCLIP + Web Demo）
make docker-up
```

### 2. iOS 开发

```bash
cd ios/SuperWardrobe
open Package.swift          # 用 Xcode 打开
# 修改 Constants.swift 中的 Supabase 配置
# Command + R 运行
```

### 3. Android 开发

```bash
cd android/superwardrobe
# 用 Android Studio 打开项目
# 修改 Constants.kt 中的 Supabase 配置
# 运行
```

### 服务端口

| 服务 | 地址 |
|------|------|
| FashionCLIP API | http://localhost:8000/docs |
| Web Demo | http://localhost:80 |
| Supabase | https://\<project-ref\>.supabase.co |

## 📖 文档

- [重构设计文档](docs/plans/2026-03-06-wardrobe-refactor-design.md)
- [MVP 设计文档](docs/2026-02-24-superpower-wardrobe-design.md)
- [MVP 实施计划](docs/2026-02-24-superpower-wardrobe-mvp-plan.md)

