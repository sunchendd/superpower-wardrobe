package com.superwardrobe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ClothingItem(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    @SerialName("category_id") val categoryId: String? = null,
    val name: String? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    val brand: String? = null,
    val color: String = "",
    val season: String? = null,
    @SerialName("style_tags") val styleTags: List<String> = emptyList(),
    @SerialName("purchase_price") val purchasePrice: Double? = null,
    @SerialName("purchase_date") val purchaseDate: String? = null,
    @SerialName("purchase_url") val purchaseUrl: String? = null,
    @SerialName("wear_count") val wearCount: Int = 0,
    val status: String = "active",
    @SerialName("created_at") val createdAt: String = ""
)
