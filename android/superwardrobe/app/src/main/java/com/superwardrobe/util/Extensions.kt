package com.superwardrobe.util

import androidx.compose.ui.graphics.Color
import java.text.NumberFormat
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

fun String.toDisplayDate(): String {
    return try {
        val date = LocalDate.parse(this.take(10))
        date.format(DateTimeFormatter.ofPattern("yyyy年M月d日"))
    } catch (e: Exception) {
        this
    }
}

fun String.toShortDate(): String {
    return try {
        val date = LocalDate.parse(this.take(10))
        date.format(DateTimeFormatter.ofPattern("M/d"))
    } catch (e: Exception) {
        this
    }
}

fun Double.toCurrencyString(): String {
    val format = NumberFormat.getCurrencyInstance(Locale.CHINA)
    return format.format(this)
}

fun Double.toTemperatureString(): String {
    return "${this.toInt()}°C"
}

fun String.toColor(): Color {
    return when (this) {
        "黑色" -> Color(0xFF000000)
        "白色" -> Color(0xFFFFFFFF)
        "灰色" -> Color(0xFF9E9E9E)
        "红色" -> Color(0xFFE53935)
        "蓝色" -> Color(0xFF1E88E5)
        "绿色" -> Color(0xFF43A047)
        "黄色" -> Color(0xFFFDD835)
        "粉色" -> Color(0xFFEC407A)
        "紫色" -> Color(0xFF8E24AA)
        "橙色" -> Color(0xFFFB8C00)
        "棕色" -> Color(0xFF6D4C41)
        "米色" -> Color(0xFFF5F5DC)
        "藏青" -> Color(0xFF1A237E)
        "酒红" -> Color(0xFF880E4F)
        "卡其" -> Color(0xFFC3B091)
        "驼色" -> Color(0xFFC19A6B)
        else -> Color(0xFF9E9E9E)
    }
}

fun Int.toWearCountLabel(): String {
    return when {
        this == 0 -> "未穿过"
        this < 5 -> "穿了${this}次"
        this < 20 -> "常穿 ${this}次"
        else -> "最爱 ${this}次"
    }
}

fun List<String>.toTagString(): String {
    return if (isEmpty()) "无标签" else joinToString(" · ")
}
