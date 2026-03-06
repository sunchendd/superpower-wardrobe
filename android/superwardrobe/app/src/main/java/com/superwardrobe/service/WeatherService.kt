package com.superwardrobe.service

import com.superwardrobe.util.Constants
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class WeatherResponse(
    val weather: List<WeatherInfo> = emptyList(),
    val main: MainInfo = MainInfo(),
    val name: String = ""
)

@Serializable
data class WeatherInfo(
    val id: Int = 0,
    val main: String = "",
    val description: String = "",
    val icon: String = ""
)

@Serializable
data class MainInfo(
    val temp: Double = 0.0,
    @SerialName("feels_like") val feelsLike: Double = 0.0,
    @SerialName("temp_min") val tempMin: Double = 0.0,
    @SerialName("temp_max") val tempMax: Double = 0.0,
    val humidity: Int = 0
)

object WeatherService {

    private val client = HttpClient(Android) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }
    }

    suspend fun getCurrentWeather(lat: Double, lon: Double): WeatherResponse {
        return client.get("https://api.openweathermap.org/data/2.5/weather") {
            parameter("lat", lat)
            parameter("lon", lon)
            parameter("appid", Constants.OPEN_WEATHER_API_KEY)
            parameter("units", "metric")
            parameter("lang", "zh_cn")
        }.body()
    }

    fun getWeatherIconUrl(iconCode: String): String {
        return "https://openweathermap.org/img/wn/${iconCode}@2x.png"
    }

    fun getWeatherEmoji(weatherMain: String): String {
        return when (weatherMain.lowercase()) {
            "clear" -> "☀️"
            "clouds" -> "☁️"
            "rain", "drizzle" -> "🌧️"
            "thunderstorm" -> "⛈️"
            "snow" -> "❄️"
            "mist", "fog", "haze" -> "🌫️"
            else -> "🌤️"
        }
    }

    fun getSuggestionForWeather(temp: Double, weatherMain: String): String {
        return when {
            temp < 5 -> "天气寒冷，建议穿厚外套、羽绒服，注意保暖"
            temp < 15 -> "天气偏凉，建议穿夹克或薄外套，搭配长裤"
            temp < 25 -> "温度舒适，建议穿长袖衬衫或薄针织衫"
            temp < 32 -> "天气温暖，建议穿短袖、短裤等轻薄衣物"
            else -> "天气炎热，建议穿最轻薄透气的衣物，注意防晒"
        } + when (weatherMain.lowercase()) {
            "rain", "drizzle", "thunderstorm" -> "，记得带伞"
            "snow" -> "，注意防滑保暖"
            else -> ""
        }
    }
}
