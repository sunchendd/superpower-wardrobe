package com.superwardrobe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class TravelPlan(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val destination: String = "",
    @SerialName("start_date") val startDate: String = "",
    @SerialName("end_date") val endDate: String = "",
    @SerialName("daily_outfits") val dailyOutfits: Map<String, List<String>> = emptyMap(),
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String = ""
)
