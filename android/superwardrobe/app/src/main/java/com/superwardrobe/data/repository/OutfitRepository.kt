package com.superwardrobe.data.repository

import com.superwardrobe.data.model.Outfit
import com.superwardrobe.data.model.OutfitDiary
import com.superwardrobe.service.SupabaseService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class OutfitRepository {

    fun getOutfits(userId: String): Flow<List<Outfit>> = flow {
        val outfits = SupabaseService.getOutfits(userId)
        emit(outfits)
    }

    suspend fun createOutfit(outfit: Outfit): Outfit {
        return SupabaseService.insertOutfit(outfit)
    }

    suspend fun updateOutfit(outfit: Outfit) {
        SupabaseService.updateOutfit(outfit)
    }

    suspend fun deleteOutfit(id: String) {
        SupabaseService.deleteOutfit(id)
    }

    fun getOutfitDiaries(userId: String): Flow<List<OutfitDiary>> = flow {
        val diaries = SupabaseService.getOutfitDiaries(userId)
        emit(diaries)
    }

    suspend fun createDiaryEntry(diary: OutfitDiary): OutfitDiary {
        return SupabaseService.insertOutfitDiary(diary)
    }

    suspend fun updateDiaryEntry(diary: OutfitDiary) {
        SupabaseService.updateOutfitDiary(diary)
    }

    fun getDiariesForMonth(userId: String, yearMonth: String): Flow<List<OutfitDiary>> = flow {
        val diaries = SupabaseService.getOutfitDiaries(userId)
            .filter { it.date.startsWith(yearMonth) }
        emit(diaries)
    }
}
