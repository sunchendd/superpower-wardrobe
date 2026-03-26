# Superpower Wardrobe — Redesign Spec

**Date:** 2026-03-26
**Status:** Approved
**Approach:** Method C — Replace Service layer, keep Views & ViewModels

---

## 1. Product Overview

**超能力衣橱** — 面向效率型职场人（25-40 岁）的智能衣橱管理 iOS App。

**核心价值：** 每天 30 秒，打开 App 看到今日穿搭推荐，一键确认，关掉出门。

**商业模式：** App Store 付费下载（¥6 / $1），下载即全功能，无内购。AI 功能需用户自行申请 Qwen VL API Key 填入激活。

**目标用户：** 不想每天纠结穿什么的职场人。追求效率，不追求社交分享。

---

## 2. Architecture

### 2.1 Tech Stack

| Layer | Technology |
|-------|-----------|
| Platform | iOS 17+, SwiftUI |
| Data | SwiftData (local only) |
| Auth | Sign in with Apple (identity only) |
| AI | Qwen VL (Alibaba Cloud API, user-provided key) |
| Weather | WeatherKit (Apple native, free 500k/mo) |
| Location | Core Location |
| Purchase | Paid download (no StoreKit needed) |
| Icons | SF Symbols (Apple native) |

### 2.2 Service Layer Replacement

| Current (Delete) | New |
|-------------------|-----|
| SupabaseService (cloud DB + auth) | **Delete entirely** |
| FashionCLIPService (self-hosted ML) | **Delete entirely** |
| WeatherService (OpenWeather API) | **WeatherKitService** (Apple native) |
| AIService (Qwen + DeepSeek dual) | **QwenVLService** (Qwen VL only) |
| AuthViewModel (email/password) | **AppleAuthService** (Sign in with Apple) |

| Current (Keep & Enhance) | Changes |
|---------------------------|---------|
| LocalDataService (SwiftData) | Enhance: unified model, new fields |
| LocationService (CoreLocation) | Keep as-is |
| LocalRecommendationEngine | Enhance: AI-augmented when key available |
| PurchaseService (StoreKit 2) | **Delete** (paid download, no IAP needed) |

### 2.3 Delete List

Remove entirely from repository:
- `app/` — Flutter reference app
- `android/` — Android stub
- `web-demo/` — Static web demo
- `services/fashion-clip/` — Self-hosted ML service
- `supabase/` — Migrations, Edge Functions, seed, config
- `docker-compose.yml`, `nginx.conf`, `deploy.sh`, `Makefile`
- iOS Services: `SupabaseService.swift`, `FashionCLIPService.swift`, `AIService.swift`, `WeatherService.swift`, `PurchaseService.swift`
- iOS ViewModels: `AuthViewModel.swift` (replaced by AppleAuthService), `ProfileViewModel.swift` (merged into SettingsView)
- iOS Views: `Views/Paywall/`, `Views/Auth/` (old email/password auth), purchase-related views
- iOS Models (all Codable network models): `ClothingItem.swift`, `Outfit.swift`, `DailyRecommendation.swift`, `PurchaseRecommendation.swift`, `UserProfile.swift`, `OutfitDiary.swift`, `TravelPlan.swift`, `Category.swift`
- Supabase SDK dependency from Xcode project
- Any SPM/CocoaPods references to Supabase

### 2.4 Dependency Graph

```
SuperWardrobeApp
 ├─ AppleAuthService ─── Sign in with Apple (identity)
 └─ SwiftData Container
     ├─ ClothingItem (unified @Model)
     └─ OutfitDiary

ContentView (5 tabs)
 ├─ RecommendationView
 │   └─ RecommendationVM
 │       ├─ WeatherKitService (Apple native)
 │       ├─ LocationService (CoreLocation)
 │       ├─ LocalRecommendationEngine
 │       └─ QwenVLService? (AI enhanced reason, optional)
 │
 ├─ WardrobeView
 │   └─ WardrobeVM → SwiftData @Query
 │
 ├─ ➕ AddItemView (modal sheet from center tab)
 │   └─ AddItemVM
 │       ├─ QwenVLService (image → classify, optional)
 │       └─ Manual input fallback (no API key)
 │
 ├─ StatisticsView
 │   └─ StatisticsVM → SwiftData @Query
 │
 └─ SettingsView
     ├─ API Key config (Qwen VL)
     ├─ Apple ID info
     ├─ Theme selector (Light themes)
     └─ Body info / style preferences
```

---

## 3. Data Model

### 3.1 SwiftData @Model

```swift
@Model
class ClothingItem {
    @Attribute(.unique) var id: UUID
    var name: String              // "白色圆领T恤"
    @Attribute(.externalStorage) var imageData: Data?  // externally stored, auto-managed by SwiftData
    var category: String          // "上衣" / "裤子" / "外套" / "鞋子" / "配饰" / "裙子"
    var brand: String?
    var colorHex: String?         // "#FFFFFF"
    var colorName: String?        // "白色"
    var seasons: [String]         // ["spring", "autumn"] — supports multi-season items
    var styleTags: [String]       // ["休闲", "通勤"]
    var material: String?         // "棉" / "聚酯纤维"
    var purchasePrice: Double?
    var purchaseDate: Date?
    var wearCount: Int = 0
    var lastWornDate: Date?
    var notes: String?
    var createdAt: Date = Date()
}

@Model
class OutfitDiary {
    @Attribute(.unique) var id: UUID
    var date: Date
    @Attribute(.externalStorage) var photoData: Data?
    var mood: String?             // "😊" / "😐" / "🥶"
    var occasion: String?         // "通勤" / "约会" / "运动"
    var weatherDesc: String?
    var temperature: Double?
    var notes: String?
    @Relationship var items: [ClothingItem]  // proper relationship, not UUID array
    var createdAt: Date = Date()
}
```

**Note:** `TravelPlan` removed from v1 scope. Can be added in future version. Reduces complexity for initial release.

**Image Storage Strategy:**
- All `imageData` fields use `@Attribute(.externalStorage)` — SwiftData manages file storage automatically
- On save, compress to JPEG 0.7 quality, max 1024px dimension
- Generate 200px thumbnail stored inline for grid views (`thumbnailData: Data?`)

**Category Icon:**
- Derived from `category` via computed property, not stored per item:
```swift
extension ClothingItem {
    var categoryIcon: String {
        switch category {
        case "上衣": return "tshirt"
        case "裤子": return "figure.walk"
        // ...
        }
    }
}
```

### 3.2 UserDefaults (@AppStorage)

```swift
// User identity
@AppStorage("appleUserId")    var appleUserId: String = ""
@AppStorage("displayName")    var displayName: String = ""

// AI config — API Key stored in Keychain (not UserDefaults) for security
// Use KeychainService wrapper: KeychainService.save("qwenApiKey", value)
// @AppStorage only stores non-sensitive config:
@AppStorage("qwenBaseUrl")    var qwenBaseUrl: String = "https://dashscope.aliyuncs.com"

// Theme
@AppStorage("themeColor")     var themeColor: String = "rose"  // rose/ocean/sage/lavender
// Dark mode follows system via @Environment(\.colorScheme)

// Body info
@AppStorage("height")         var height: Double = 170
@AppStorage("weight")         var weight: Double = 65
@AppStorage("bodyType")       var bodyType: String = "standard"
@AppStorage("stylePrefs")     var stylePreferences: String = ""  // JSON
```

---

## 4. User Journey

### 4.1 First Launch (Onboarding)

1. **Welcome screen** — App name + tagline "每天 30 秒，告别穿搭纠结"
2. **Sign in with Apple** — One-tap login, skip option available
3. **Add first item** — Guide user to take a photo or skip to main app
4. **Enter main app** — Recommendation tab as home

### 4.2 Core Loop: Daily Recommendation (30s)

1. Open app → Recommendation tab (home)
2. See weather card (WeatherKit + CoreLocation)
3. See outfit suggestion (LocalRecommendationEngine, optionally AI-enhanced)
4. Tap "就穿这套" → increments wearCount + records lastWornDate + auto-creates OutfitDiary entry
5. Or tap "换一套" → next suggestion
6. Close app

### 4.5 Outfit History

- Tapping "就穿这套" auto-creates an `OutfitDiary` entry with date, weather, and selected items
- Outfit history accessible from **统计 tab** (section: "穿搭记录")
- Calendar view shows which days have outfit records
- No manual diary editing needed — keeps it effortless for efficiency users

### 4.3 Add Clothing

**Path A — With API Key (AI):**
1. Tap ➕ center tab → modal sheet
2. Take photo or pick from album
3. Qwen VL auto-classifies: category, color, material, style
4. User confirms or adjusts
5. Save to SwiftData

**Path B — Without API Key (Manual):**
1. Tap ➕ center tab → modal sheet
2. Take photo or pick from album (optional)
3. Pick category, color, season, style tags from pickers
4. Enter name, brand (optional)
5. Save to SwiftData

### 4.4 Tab Structure (5 tabs)

| Tab | Name | Icon (SF Symbol) | Content |
|-----|------|-------------------|---------|
| 1 | 推荐 | `eye` | Weather + daily outfit suggestion |
| 2 | 衣橱 | `cabinet` | Grid view with category/season filters |
| 3 | ➕ 添加 | `plus` (custom center button) | Modal `.sheet()`, not a real tab — requires custom tab bar |
| 4 | 统计 | `chart.bar` | Category distribution, utilization, idle items, outfit history |
| 5 | 设置 | `gearshape` | API key, theme, profile, about |

---

## 5. Theme System

### 5.1 Overview

- **Dark mode:** Follows system `colorScheme`, single Midnight Black theme
- **Light mode:** 4 user-selectable accent colors, stored in `@AppStorage("themeColor")`

### 5.2 Themes

| Theme | Mode | Accent | Background | Card |
|-------|------|--------|------------|------|
| Midnight Black | Dark | #BE185D | #020203 | white/4% |
| Rose 玫瑰 | Light | #BE185D | #FDF2F8 | #FFFFFF |
| Ocean 海洋 | Light | #0369A1 | #F0F9FF | #FFFFFF |
| Sage 鼠尾草 | Light | #15803D | #F0FDF4 | #FFFFFF |
| Lavender 薰衣草 | Light | #7C3AED | #F5F3FF | #FFFFFF |

### 5.3 Implementation

All colors defined as semantic Design Tokens:

```swift
enum AppTheme: String, CaseIterable {
    case rose, ocean, sage, lavender

    var accent: Color { ... }
    var background: Color { ... }
    var cardBackground: Color { ... }
    // Dark mode variants computed from colorScheme
}
```

- `@Environment(\.colorScheme)` for auto Light/Dark
- `@AppStorage("themeColor")` for Light mode accent selection
- Views only reference token names, never raw hex

### 5.4 Design Style

- **Style:** Modern Dark Cinema (dark) / Clean Minimal (light)
- **Icons:** SF Symbols only, no emoji as structural icons
- **Typography:** SF Pro (system), Dynamic Type support
- **Spacing:** 8pt grid system
- **Border radius:** 16px cards, 12px buttons, 8px small elements
- **Animation:** 150-300ms, spring physics, interruptible
- **Accessibility:** WCAG AA contrast, VoiceOver labels, Dynamic Type

---

## 6. Service Specifications

### 6.1 AppleAuthService

```swift
final class AppleAuthService {
    func signIn() async throws -> (userId: String, displayName: String?)
    var isSignedIn: Bool { get }
    var currentUserId: String? { get }
}
```

- Uses `ASAuthorizationAppleIDProvider`
- Stores `appleUserId` in @AppStorage
- Identity only, no cloud sync
- Handles credential revocation: observe `ASAuthorizationAppleIDProvider.credentialRevokedNotification`
- `checkCredentialState()` called on app launch — if revoked, clear local identity gracefully

### 6.2 QwenVLService

```swift
final class QwenVLService {
    var isConfigured: Bool { !apiKey.isEmpty }

    func classifyClothing(image: UIImage) async throws -> ClassificationResult
    func generateRecommendationReason(items: [String], weather: String?) async throws -> String
    func testConnection() async -> Bool
}

struct ClassificationResult {
    var category: String
    var colorHex: String
    var colorName: String
    var material: String?
    var styleTags: [String]
    var seasons: [String]
    var confidence: Double
}
```

- Calls Qwen VL API with user-provided API Key
- Vision model for image classification
- Text model for recommendation reasoning
- Graceful fallback: no key = manual input, no error

### 6.3 WeatherKitService

```swift
final class WeatherKitService {
    func fetchCurrentWeather(location: CLLocation) async throws -> WeatherData
}

struct WeatherData {
    var temperature: Double
    var condition: String
    var humidity: Double
    var windSpeed: Double
    var description: String
    var needUmbrella: Bool
}
```

- Uses Apple WeatherKit framework
- Free 500k API calls/month with Apple Developer account
- Requires `com.apple.developer.weatherkit` entitlement

---

## 7. Business Model

| Aspect | Detail |
|--------|--------|
| Pricing | App Store paid download ¥6 / $1 |
| In-App Purchase | None |
| AI cost | User bears own Qwen VL API cost (free tier available) |
| Revenue | One-time download fee |
| Family Sharing | Supported (Apple default for paid apps) |

**No paywall, no subscription, no IAP.** Download = full access. AI is enhancement, not requirement.

---

## 8. Design Principles

1. **30 秒原则** — Core scenario (see recommendation → confirm) under 30 seconds
2. **推荐页即首页** — First thing user sees is "what to wear today"
3. **无社交** — No sharing, no followers, pure utility tool
4. **AI 是增强不是必须** — Every feature works without API key
5. **Apple 原生优先** — SF Symbols, WeatherKit, Sign in with Apple, SwiftData
6. **零第三方依赖** — No Supabase, no pods, no SPM packages for core features

---

## 9. Error Handling & Edge Cases

| Scenario | Behavior |
|----------|----------|
| Location permission denied | Show weather as "unavailable", still recommend based on season/date only |
| WeatherKit API fails | Cache last weather, show "天气信息暂不可用" banner, recommendations still work |
| Qwen VL API error / rate limit | Show error toast, fall back to manual input mode |
| No API key configured | AI buttons show "配置 API Key" badge, all manual flows work normally |
| Zero clothing items | Empty state: "拍一件衣服开始吧" with camera button |
| Zero items for a season | Recommendation shows "当季衣物不足，试试添加更多" |
| Apple credential revoked | Clear identity, app continues working (data is local) |
| Image too large | Auto-compress to JPEG 0.7, max 1024px before storage |

**Concurrency model:** All ViewModels and services that touch SwiftData are `@MainActor`. Network calls dispatched via `async/await`.

---

## 10. Statistics Tab Detail

| Section | Content | Data Source |
|---------|---------|-------------|
| Overview cards | Total items, utilization rate, average price | ClothingItem aggregate |
| Category distribution | Horizontal bar chart (上衣/裤子/外套/鞋子/配饰) | ClothingItem.category |
| Idle items alert | Items not worn for 30+ days | ClothingItem.lastWornDate |
| Outfit history | Calendar view with outfit records | OutfitDiary entries |
| Color distribution | Color dots chart | ClothingItem.colorHex |

**Idle threshold:** 30 days = warning (amber), 60 days = alert (red).

---

## 11. Implementation Notes

- **Custom tab bar** required: SwiftUI native `TabView` doesn't support center floating button. Build custom `CustomTabBar` view with `ZStack` overlay.
- **WeatherKit** requires paid Apple Developer Program ($99/year) — prerequisite for development.
- **SwiftData migration:** Use `VersionedSchema` from v1 to support future schema changes.
- **Keychain wrapper:** Build lightweight `KeychainService` (Security framework) for API key storage. ~30 lines of code.
