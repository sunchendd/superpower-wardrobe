package com.superwardrobe.service

import com.superwardrobe.data.model.*
import com.superwardrobe.util.Constants
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.storage.Storage
import io.github.jan.supabase.storage.storage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object SupabaseService {

    val client: SupabaseClient = createSupabaseClient(
        supabaseUrl = Constants.SUPABASE_URL,
        supabaseKey = Constants.SUPABASE_ANON_KEY
    ) {
        install(Auth)
        install(Postgrest)
        install(Storage)
    }

    suspend fun signIn(email: String, password: String) = withContext(Dispatchers.IO) {
        client.auth.signInWith(Email) {
            this.email = email
            this.password = password
        }
    }

    suspend fun signUp(email: String, password: String) = withContext(Dispatchers.IO) {
        client.auth.signUpWith(Email) {
            this.email = email
            this.password = password
        }
    }

    suspend fun signOut() = withContext(Dispatchers.IO) {
        client.auth.signOut()
    }

    fun getCurrentUserId(): String? {
        return client.auth.currentUserOrNull()?.id
    }

    // ClothingItem CRUD
    suspend fun getClothingItems(userId: String): List<ClothingItem> = withContext(Dispatchers.IO) {
        client.from("clothing_items")
            .select {
                filter { eq("user_id", userId) }
                order("created_at", Order.DESCENDING)
            }
            .decodeList()
    }

    suspend fun getClothingItemById(id: String): ClothingItem = withContext(Dispatchers.IO) {
        client.from("clothing_items")
            .select {
                filter { eq("id", id) }
            }
            .decodeSingle()
    }

    suspend fun insertClothingItem(item: ClothingItem): ClothingItem = withContext(Dispatchers.IO) {
        client.from("clothing_items")
            .insert(item) { select() }
            .decodeSingle()
    }

    suspend fun updateClothingItem(item: ClothingItem) = withContext(Dispatchers.IO) {
        client.from("clothing_items")
            .update(item) {
                filter { eq("id", item.id) }
            }
    }

    suspend fun deleteClothingItem(id: String) = withContext(Dispatchers.IO) {
        client.from("clothing_items")
            .delete {
                filter { eq("id", id) }
            }
    }

    suspend fun searchClothingItems(userId: String, query: String): List<ClothingItem> = withContext(Dispatchers.IO) {
        client.from("clothing_items")
            .select {
                filter {
                    eq("user_id", userId)
                    or {
                        ilike("name", "%$query%")
                        ilike("brand", "%$query%")
                        ilike("color", "%$query%")
                    }
                }
            }
            .decodeList()
    }

    // Categories
    suspend fun getCategories(): List<Category> = withContext(Dispatchers.IO) {
        client.from("categories")
            .select {
                order("sort_order", Order.ASCENDING)
            }
            .decodeList()
    }

    // Outfits
    suspend fun getOutfits(userId: String): List<Outfit> = withContext(Dispatchers.IO) {
        client.from("outfits")
            .select {
                filter { eq("user_id", userId) }
                order("created_at", Order.DESCENDING)
            }
            .decodeList()
    }

    suspend fun insertOutfit(outfit: Outfit): Outfit = withContext(Dispatchers.IO) {
        client.from("outfits")
            .insert(outfit) { select() }
            .decodeSingle()
    }

    suspend fun updateOutfit(outfit: Outfit) = withContext(Dispatchers.IO) {
        client.from("outfits")
            .update(outfit) {
                filter { eq("id", outfit.id) }
            }
    }

    suspend fun deleteOutfit(id: String) = withContext(Dispatchers.IO) {
        client.from("outfits")
            .delete {
                filter { eq("id", id) }
            }
    }

    // OutfitDiary
    suspend fun getOutfitDiaries(userId: String): List<OutfitDiary> = withContext(Dispatchers.IO) {
        client.from("outfit_diaries")
            .select {
                filter { eq("user_id", userId) }
                order("date", Order.DESCENDING)
            }
            .decodeList()
    }

    suspend fun insertOutfitDiary(diary: OutfitDiary): OutfitDiary = withContext(Dispatchers.IO) {
        client.from("outfit_diaries")
            .insert(diary) { select() }
            .decodeSingle()
    }

    suspend fun updateOutfitDiary(diary: OutfitDiary) = withContext(Dispatchers.IO) {
        client.from("outfit_diaries")
            .update(diary) {
                filter { eq("id", diary.id) }
            }
    }

    // DailyRecommendation
    suspend fun getDailyRecommendations(userId: String, date: String): List<DailyRecommendation> = withContext(Dispatchers.IO) {
        client.from("daily_recommendations")
            .select {
                filter {
                    eq("user_id", userId)
                    eq("date", date)
                }
            }
            .decodeList()
    }

    suspend fun insertDailyRecommendation(rec: DailyRecommendation): DailyRecommendation = withContext(Dispatchers.IO) {
        client.from("daily_recommendations")
            .insert(rec) { select() }
            .decodeSingle()
    }

    suspend fun markRecommendationWorn(id: String) = withContext(Dispatchers.IO) {
        client.from("daily_recommendations")
            .update(mapOf("is_worn" to true)) {
                filter { eq("id", id) }
            }
    }

    // PurchaseRecommendation
    suspend fun getPurchaseRecommendations(userId: String): List<PurchaseRecommendation> = withContext(Dispatchers.IO) {
        client.from("purchase_recommendations")
            .select {
                filter { eq("user_id", userId) }
                order("priority", Order.DESCENDING)
            }
            .decodeList()
    }

    // TravelPlan
    suspend fun getTravelPlans(userId: String): List<TravelPlan> = withContext(Dispatchers.IO) {
        client.from("travel_plans")
            .select {
                filter { eq("user_id", userId) }
                order("start_date", Order.ASCENDING)
            }
            .decodeList()
    }

    suspend fun insertTravelPlan(plan: TravelPlan): TravelPlan = withContext(Dispatchers.IO) {
        client.from("travel_plans")
            .insert(plan) { select() }
            .decodeSingle()
    }

    suspend fun updateTravelPlan(plan: TravelPlan) = withContext(Dispatchers.IO) {
        client.from("travel_plans")
            .update(plan) {
                filter { eq("id", plan.id) }
            }
    }

    suspend fun deleteTravelPlan(id: String) = withContext(Dispatchers.IO) {
        client.from("travel_plans")
            .delete {
                filter { eq("id", id) }
            }
    }

    // UserProfile
    suspend fun getUserProfile(userId: String): UserProfile? = withContext(Dispatchers.IO) {
        client.from("user_profiles")
            .select {
                filter { eq("id", userId) }
            }
            .decodeList<UserProfile>()
            .firstOrNull()
    }

    suspend fun upsertUserProfile(profile: UserProfile) = withContext(Dispatchers.IO) {
        client.from("user_profiles")
            .upsert(profile)
    }

    // Storage
    suspend fun uploadImage(bucket: String, path: String, data: ByteArray): String = withContext(Dispatchers.IO) {
        client.storage.from(bucket).upload(path, data)
        client.storage.from(bucket).publicUrl(path)
    }
}
