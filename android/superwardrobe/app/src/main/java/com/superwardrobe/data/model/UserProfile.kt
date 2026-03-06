package com.superwardrobe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class UserProfile(
    val id: String = "",
    val email: String = "",
    val nickname: String? = null,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    val gender: String? = null,
    val height: Double? = null,
    val weight: Double? = null,
    @SerialName("body_type") val bodyType: String? = null,
    @SerialName("preferred_styles") val preferredStyles: List<String> = emptyList(),
    @SerialName("preferred_colors") val preferredColors: List<String> = emptyList(),
    val location: String? = null,
    @SerialName("created_at") val createdAt: String = ""
)
