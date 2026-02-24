# superpower-wardrobe
「超能力衣橱（superpower wardrobe）」的应用程式，具备以下功能：  拍照识别衣物，并将其导入虚拟衣橱 根据以下条件每日自动推荐穿搭：  个人偏好 地理位置 天气状况   显示数位化分身（Avatar）穿着不同服装组合的效果
Superpower 你的衣橱 — 开源生态全景
已找到非常不错的开源基础！不需要从零开始，以下是最佳路线：

🏗️ 推荐技术栈（4层架构）
层级	功能	推荐项目	License
Layer 1	衣橱 App 骨架	OpenWardrobe（Flutter + Supabase）	✅ MIT
Layer 2	拍照识别衣物	FashionCLIP（CLIP微调，492⭐）	✅ MIT
Layer 3	天气+偏好 穿搭推荐	Outfit Assistant（TF.js + OpenWeather）	🟡 无声明
Layer 4	数字分身试穿效果	OOTDiffusion（6500⭐，Stable Diffusion）	✅ Apache-2.0
🎯 各层详解
Layer 1 — OpenWardrobe
Flutter 全平台（iOS / Android / Web）+ Supabase 后端
已有：上传衣物、创建穿搭、穿搭日历、天气建议框架、无广告可自托管
⚠️ 已归档（2025年7月）→ 直接 Fork 作为你自己的主仓库
Layer 2 — FashionCLIP
700K+ 时尚图文对微调的 CLIP 模型，分类 F1 达 0.83
以 Python 微服务形式挂载到 Supabase Edge Functions
Layer 3 — 穿搭推荐引擎
Weather-to-Wear：TypeScript，实时天气 → 衣橱映射，8⭐，2025年活跃
FashionAI：Python，偏好 + 天气综合推荐，16⭐
两者都可作为算法参考，规则植入你的 Supabase Functions
Layer 4 — 数字分身试穿
模型	显存需求	License	特点
OOTDiffusion	~16GB	✅ Apache-2.0	最多星，HuggingFace Space 可直接调 API
CatVTON	<8GB	⚠️ CC BY-NC	最轻量，支持 ComfyUI，视频试穿
IDM-VTON	~16GB	⚠️ CC BY-NC	野外照片效果最佳
🚀 建议行动路线
💡 是否需要 Vibe Coding？
不需要从零开始，但需要大量集成工作：

OpenWardrobe 的 Flutter + Supabase 骨架 → 直接用
FashionCLIP + OOTDiffusion → 接 API 即可
推荐引擎逻辑 → 需要自己写业务逻辑（这里最适合 vibe coding）
想从哪一层开始动手？ 我可以帮你：

搭建 OpenWardrobe 本地开发环境 + Fork 改造
写 FashionCLIP 识别服务的 Python API
设计穿搭推荐算法（天气 + 偏好 + 场合）
对接 OOTDiffusion 试穿渲染流水线
