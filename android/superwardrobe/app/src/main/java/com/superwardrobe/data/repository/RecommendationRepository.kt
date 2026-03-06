package com.superwardrobe.data.repository

import com.superwardrobe.data.model.DailyRecommendation
import com.superwardrobe.data.model.PurchaseRecommendation
import com.superwardrobe.service.SupabaseService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class RecommendationRepository {

    fun getDailyRecommendations(userId: String, date: String): Flow<List<DailyRecommendation>> = flow {
        val recommendations = SupabaseService.getDailyRecommendations(userId, date)
        emit(recommendations)
    }

    suspend fun createRecommendation(recommendation: DailyRecommendation): DailyRecommendation {
        return SupabaseService.insertDailyRecommendation(recommendation)
    }

    suspend fun markAsWorn(id: String) {
        SupabaseService.markRecommendationWorn(id)
    }

    fun getPurchaseRecommendations(userId: String): Flow<List<PurchaseRecommendation>> = flow {
        val recommendations = SupabaseService.getPurchaseRecommendations(userId)
        emit(recommendations)
    }
}
