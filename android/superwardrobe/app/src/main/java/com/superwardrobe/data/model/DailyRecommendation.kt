package com.superwardrobe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class DailyRecommendation(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val date: String = "",
    @SerialName("outfit_id") val outfitId: String? = null,
    @SerialName("outfit_items") val outfitItems: List<ClothingItem> = emptyList(),
    val reason: String? = null,
    val weather: String? = null,
    val temperature: Double? = null,
    @SerialName("min_temperature") val minTemperature: Double? = null,
    @SerialName("max_temperature") val maxTemperature: Double? = null,
    val occasion: String? = null,
    val score: Double? = null,
    @SerialName("is_worn") val isWorn: Boolean = false,
    @SerialName("created_at") val createdAt: String = ""
)
