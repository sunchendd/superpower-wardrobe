package com.superwardrobe.data.repository

import com.superwardrobe.data.model.TravelPlan
import com.superwardrobe.data.model.UserProfile
import com.superwardrobe.service.SupabaseService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class UserRepository {

    suspend fun signIn(email: String, password: String) {
        SupabaseService.signIn(email, password)
    }

    suspend fun signUp(email: String, password: String) {
        SupabaseService.signUp(email, password)
    }

    suspend fun signOut() {
        SupabaseService.signOut()
    }

    fun getCurrentUserId(): String? {
        return SupabaseService.getCurrentUserId()
    }

    fun getUserProfile(userId: String): Flow<UserProfile?> = flow {
        val profile = SupabaseService.getUserProfile(userId)
        emit(profile)
    }

    suspend fun updateProfile(profile: UserProfile) {
        SupabaseService.upsertUserProfile(profile)
    }

    suspend fun uploadAvatar(imageBytes: ByteArray, fileName: String): String {
        return SupabaseService.uploadImage("avatars", fileName, imageBytes)
    }

    fun getTravelPlans(userId: String): Flow<List<TravelPlan>> = flow {
        val plans = SupabaseService.getTravelPlans(userId)
        emit(plans)
    }

    suspend fun createTravelPlan(plan: TravelPlan): TravelPlan {
        return SupabaseService.insertTravelPlan(plan)
    }

    suspend fun updateTravelPlan(plan: TravelPlan) {
        SupabaseService.updateTravelPlan(plan)
    }

    suspend fun deleteTravelPlan(id: String) {
        SupabaseService.deleteTravelPlan(id)
    }
}
