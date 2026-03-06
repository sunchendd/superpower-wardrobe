package com.superwardrobe.data.repository

import com.superwardrobe.data.model.Category
import com.superwardrobe.data.model.ClothingItem
import com.superwardrobe.service.SupabaseService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class WardrobeRepository {

    fun getClothingItems(userId: String): Flow<List<ClothingItem>> = flow {
        val items = SupabaseService.getClothingItems(userId)
        emit(items)
    }

    fun getClothingItemsByCategory(userId: String, categoryId: String): Flow<List<ClothingItem>> = flow {
        val items = SupabaseService.getClothingItems(userId).filter { it.categoryId == categoryId }
        emit(items)
    }

    fun searchItems(userId: String, query: String): Flow<List<ClothingItem>> = flow {
        val items = SupabaseService.searchClothingItems(userId, query)
        emit(items)
    }

    suspend fun getItemById(id: String): ClothingItem {
        return SupabaseService.getClothingItemById(id)
    }

    suspend fun addItem(item: ClothingItem): ClothingItem {
        return SupabaseService.insertClothingItem(item)
    }

    suspend fun updateItem(item: ClothingItem) {
        SupabaseService.updateClothingItem(item)
    }

    suspend fun deleteItem(id: String) {
        SupabaseService.deleteClothingItem(id)
    }

    suspend fun incrementWearCount(item: ClothingItem) {
        SupabaseService.updateClothingItem(item.copy(wearCount = item.wearCount + 1))
    }

    fun getCategories(): Flow<List<Category>> = flow {
        val categories = SupabaseService.getCategories()
        emit(categories)
    }

    suspend fun uploadItemImage(imageBytes: ByteArray, fileName: String): String {
        return SupabaseService.uploadImage("clothing-images", fileName, imageBytes)
    }
}
