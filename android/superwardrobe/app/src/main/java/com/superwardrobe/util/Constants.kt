package com.superwardrobe.util

object Constants {
    const val SUPABASE_URL = "YOUR_SUPABASE_URL"
    const val SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY"
    const val FASHION_CLIP_BASE_URL = "http://10.0.2.2:8000"
    const val OPEN_WEATHER_API_KEY = "YOUR_OPENWEATHER_KEY"

    object Tables {
        const val CLOTHING_ITEMS = "clothing_items"
        const val CATEGORIES = "categories"
        const val OUTFITS = "outfits"
        const val OUTFIT_DIARIES = "outfit_diaries"
        const val DAILY_RECOMMENDATIONS = "daily_recommendations"
        const val PURCHASE_RECOMMENDATIONS = "purchase_recommendations"
        const val TRAVEL_PLANS = "travel_plans"
        const val USER_PROFILES = "user_profiles"
    }

    object Buckets {
        const val CLOTHING_IMAGES = "clothing-images"
        const val AVATARS = "avatars"
        const val DIARY_PHOTOS = "diary-photos"
    }

    object Seasons {
        val ALL = listOf("春", "夏", "秋", "冬", "四季")
    }

    object Moods {
        val ALL = listOf("😊 开心", "😎 自信", "😌 舒适", "🤩 惊艳", "😐 普通", "😔 不满意")
    }

    object Colors {
        val COMMON = listOf(
            "黑色", "白色", "灰色", "红色", "蓝色", "绿色",
            "黄色", "粉色", "紫色", "橙色", "棕色", "米色",
            "藏青", "酒红", "卡其", "驼色"
        )
    }

    object Styles {
        val ALL = listOf(
            "休闲", "正式", "运动", "街头", "复古", "简约",
            "甜美", "优雅", "中性", "波西米亚", "朋克", "学院"
        )
    }
}
