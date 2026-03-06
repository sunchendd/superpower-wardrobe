package com.superwardrobe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Outfit(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val name: String = "",
    val description: String? = null,
    @SerialName("item_ids") val itemIds: List<String> = emptyList(),
    @SerialName("cover_image_url") val coverImageUrl: String? = null,
    val occasion: String? = null,
    val season: String? = null,
    val rating: Int? = null,
    @SerialName("created_at") val createdAt: String = ""
)
