package com.superwardrobe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class OutfitDiary(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    @SerialName("outfit_id") val outfitId: String? = null,
    val date: String = "",
    val mood: String? = null,
    val note: String? = null,
    @SerialName("photo_url") val photoUrl: String? = null,
    val weather: String? = null,
    val temperature: Double? = null,
    @SerialName("created_at") val createdAt: String = ""
)
