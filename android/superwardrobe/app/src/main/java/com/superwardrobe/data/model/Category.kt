package com.superwardrobe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Category(
    val id: String = "",
    val name: String = "",
    @SerialName("parent_id") val parentId: String? = null,
    val icon: String? = null,
    @SerialName("sort_order") val sortOrder: Int = 0
)
