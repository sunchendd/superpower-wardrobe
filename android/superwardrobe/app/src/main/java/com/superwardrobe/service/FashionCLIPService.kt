package com.superwardrobe.service

import com.superwardrobe.util.Constants
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.request.forms.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class ClassificationResult(
    val category: String = "",
    val color: String = "",
    val style: List<String> = emptyList(),
    val season: String = "",
    val confidence: Double = 0.0
)

@Serializable
data class SimilarityResult(
    val score: Double = 0.0,
    val description: String = ""
)

object FashionCLIPService {

    private val client = HttpClient(Android) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }
    }

    private val baseUrl = Constants.FASHION_CLIP_BASE_URL

    suspend fun classifyImage(imageBytes: ByteArray): ClassificationResult {
        return try {
            client.submitFormWithBinaryData(
                url = "$baseUrl/classify",
                formData = formData {
                    append("image", imageBytes, Headers.build {
                        append(HttpHeaders.ContentType, "image/jpeg")
                        append(HttpHeaders.ContentDisposition, "filename=\"image.jpg\"")
                    })
                }
            ).body()
        } catch (e: Exception) {
            ClassificationResult(
                category = "未分类",
                color = "未知",
                style = emptyList(),
                season = "四季",
                confidence = 0.0
            )
        }
    }

    suspend fun getSimilarity(imageBytes1: ByteArray, imageBytes2: ByteArray): SimilarityResult {
        return try {
            client.submitFormWithBinaryData(
                url = "$baseUrl/similarity",
                formData = formData {
                    append("image1", imageBytes1, Headers.build {
                        append(HttpHeaders.ContentType, "image/jpeg")
                        append(HttpHeaders.ContentDisposition, "filename=\"image1.jpg\"")
                    })
                    append("image2", imageBytes2, Headers.build {
                        append(HttpHeaders.ContentType, "image/jpeg")
                        append(HttpHeaders.ContentDisposition, "filename=\"image2.jpg\"")
                    })
                }
            ).body()
        } catch (e: Exception) {
            SimilarityResult(score = 0.0, description = "无法计算相似度")
        }
    }

    suspend fun getOutfitScore(imageBytesList: List<ByteArray>): Double {
        return try {
            val response: Map<String, Double> = client.submitFormWithBinaryData(
                url = "$baseUrl/outfit-score",
                formData = formData {
                    imageBytesList.forEachIndexed { index, bytes ->
                        append("images", bytes, Headers.build {
                            append(HttpHeaders.ContentType, "image/jpeg")
                            append(HttpHeaders.ContentDisposition, "filename=\"image_$index.jpg\"")
                        })
                    }
                }
            ).body()
            response["score"] ?: 0.0
        } catch (e: Exception) {
            0.0
        }
    }
}
