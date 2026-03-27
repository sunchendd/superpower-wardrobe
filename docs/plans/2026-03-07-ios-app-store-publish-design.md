# iOS App 验证与发布设计

**日期**: 2026-03-07

## 项目概述

将Superpower Wardrobe iOS应用从Swift Package Manager项目转换为标准Xcode项目，并发布到App Store Connect (TestFlight)。

## 项目状态

- **项目类型**: Swift Package Manager (SPM)
- **依赖**: Supabase 2.0.0+, Kingfisher 7.0.0+
- **最低iOS版本**: iOS 17
- **Swift版本**: 5.9+

## 方案选择

选择**方案A: 转换为Xcode项目发布**
- 创建`.xcodeproj`文件，添加为标准iOS项目
- 使用Xcode内置的App Store Connect功能
- 流程: Xcode → Archive → Upload → TestFlight → App Store

## 实施步骤

### 步骤1: 创建Xcode项目配置

1. 创建`SuperWardrobe.xcodeproj`
2. 配置Bundle Identifier (需要 Apple Developer账号)
3. 配置版本号(Version)和构建号(Build Number)
4. 添加所需Entitlements:
   - 推送通知
   - 相册访问
   - 位置服务

### 步骤2: 配置App Store Connect

1. 登录Apple Developer网站
2. 创建App Record (Bundle ID需匹配)
3. 配置App信息: 名称、描述、截图
4. 生成或导入发布证书
5. 创建App Store描述文件

### 步骤3: 验证编译

1. 使用Xcode构建项目到iOS Simulator
2. 确认无编译错误和警告
3. 验证所有依赖正确链接

### 步骤4: Archive并发布

1. Product → Archive
2. Organizer中选择刚Archive的版本
3. Distribute App → App Store Connect
4. 上传完成后在App Store Connect查看
5. 提交TestFlight审核

## 注意事项

- SPM项目需要转换为传统Xcode项目才能使用完整的发布流程
- Bundle Identifier必须全局唯一
- 需要有效的Apple Developer账号
