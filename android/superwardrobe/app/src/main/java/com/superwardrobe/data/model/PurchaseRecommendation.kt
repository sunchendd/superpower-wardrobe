package com.superwardrobe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PurchaseRecommendation(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val category: String = "",
    val reason: String = "",
    @SerialName("suggested_color") val suggestedColor: String? = null,
    @SerialName("suggested_style") val suggestedStyle: String? = null,
    @SerialName("price_range_min") val priceRangeMin: Double? = null,
    @SerialName("price_range_max") val priceRangeMax: Double? = null,
    @SerialName("reference_url") val referenceUrl: String? = null,
    @SerialName("reference_image_url") val referenceImageUrl: String? = null,
    val priority: Int = 0,
    @SerialName("created_at") val createdAt: String = ""
)
