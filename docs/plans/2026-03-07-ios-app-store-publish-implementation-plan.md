# iOS App Store 发布实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将Superpower Wardrobe iOS应用从SPM项目转换为Xcode项目并发布到App Store Connect (TestFlight)。

**Architecture:** 这是一个Swift Package Manager管理的iOS项目，需要转换为标准Xcode项目才能使用Xcode的Archive功能发布到App Store。转换后将保留原有SPM依赖。

**Tech Stack:** Swift 5.9+, iOS 17+, Swift Package Manager, Xcode

---

## 任务1: 确认Bundle Identifier

**Files:**
- 修改: `ios/SuperWardrobe/Package.swift` (如需要)

**Step 1: 确认Bundle Identifier**

请在Apple Developer账号中确认你想使用的Bundle Identifier（如 `com.superpower.wardrobe`），或者告诉我你希望使用的ID。

**Step 2: 我将创建Xcode项目配置**

在确认Bundle Identifier后，创建项目配置文件。

---

## 任务2: 创建Xcode项目结构

**Files:**
- 创建: `ios/SuperWardrobe/SuperWardrobe.xcodeproj/project.pbxproj`
- 创建: `ios/SuperWardrobe/SuperWardrobe.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- 创建: `ios/SuperWardrobe/SuperWardrobe.xcodeproj/project.xcconfig/SuperWardrobe.xcconfig`

**Step 1: 使用Xcode生成项目**

运行: `cd ios/SuperWardrobe && swift package generate-xcodeproj`

预期: 如果成功，生成`SuperWardrobe.xcodeproj`

**Step 2: 如失败，手动创建项目配置**

如果SPM无法生成，创建一个基础的项目配置文件。

---

## 任务3: 配置项目签名

**Files:**
- 修改: `ios/SuperWardrobe/SuperWardrobe.xcodeproj/project.pbxproj`

**Step 1: 配置Bundle Identifier**

在project.pbxproj中设置正确的Bundle Identifier。

**Step 2: 配置代码签名**

设置Automatic Signing或手动指定证书。

---

## 任务4: 验证编译

**Files:**
- 构建: 整个项目

**Step 1: 使用Xcodebuild构建**

运行: `xcodebuild -project ios/SuperWardrobe/SuperWardrobe.xcodeproj -scheme SuperWardrobe -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build`

预期: BUILD SUCCEEDED

---

## 任务5: Archive并上传

**Files:**
- 操作: App Store Connect

**Step 1: Archive**

运行: `xcodebuild -project ios/SuperWardrobe/SuperWardrobe.xcodeproj -scheme SuperWardrobe -configuration Release archive -archivePath ./SuperWardrobe.xcarchive`

**Step 2: 导出ipa**

运行: `xcodebuild -exportArchive -archivePath ./SuperWardrobe.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath ./ipa`

**Step 3: 上传到App Store Connect**

运行: `xcrun altool --upload-app -f ./ipa/SuperWardrobe.ipa -t ios -u "YOUR_APPLE_ID" -p "YOUR_APPLE_ID_PASSWORD"`

或者使用Xcode手动上传。

---

## 下一步

**请告诉我:**

1. 你希望使用的Bundle Identifier是什么？（如 `com.superpower.wardrobe`）
2. 你的Apple Developer账号是否已经创建了对应的App Record？

**Plan complete and saved to `docs/plans/2026-03-07-ios-app-store-publish-design.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**
