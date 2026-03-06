package com.superwardrobe.ui.recommendation

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.superwardrobe.data.model.ClothingItem
import com.superwardrobe.data.model.DailyRecommendation
import com.superwardrobe.data.model.PurchaseRecommendation
import com.superwardrobe.ui.common.EmptyState
import com.superwardrobe.ui.common.LoadingIndicator

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun RecommendationScreen() {
    var isRefreshing by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }

    val weatherData = remember {
        mutableStateOf(
            WeatherDisplayData(
                temperature = 22.0,
                feelsLike = 20.0,
                description = "晴朗",
                emoji = "☀️",
                suggestion = "温度舒适，建议穿长袖衬衫或薄针织衫",
                city = "北京",
                tempMin = 18.0,
                tempMax = 26.0,
                humidity = 45
            )
        )
    }

    val recommendations = remember {
        mutableStateListOf(
            DailyRecommendation(
                id = "1",
                date = "2024-03-15",
                reason = "今日气温舒适，推荐休闲风格搭配",
                weather = "晴",
                temperature = 22.0,
                occasion = "日常",
                score = 0.92,
                outfitItems = listOf(
                    ClothingItem(id = "c1", name = "白色衬衫", color = "白色", wearCount = 12),
                    ClothingItem(id = "c2", name = "深蓝牛仔裤", color = "蓝色", wearCount = 8),
                    ClothingItem(id = "c3", name = "白色运动鞋", color = "白色", wearCount = 15)
                )
            )
        )
    }

    val purchaseSuggestions = remember {
        mutableStateListOf(
            PurchaseRecommendation(
                id = "p1",
                category = "外套",
                reason = "您的衣橱缺少春季薄外套，建议添置一件",
                suggestedColor = "米色",
                suggestedStyle = "休闲",
                priceRangeMin = 200.0,
                priceRangeMax = 500.0,
                priority = 1
            )
        )
    }

    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = {
            isRefreshing = true
            isRefreshing = false
        }
    ) {
        if (isLoading) {
            LoadingIndicator(message = "正在为你搭配...")
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 16.dp)
            ) {
                item {
                    Text(
                        text = "今日推荐",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(start = 16.dp, top = 16.dp, bottom = 8.dp)
                    )
                }

                item {
                    WeatherCard(data = weatherData.value)
                }

                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "穿搭推荐",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.SemiBold
                        )
                        IconButton(onClick = { /* refresh recommendations */ }) {
                            Icon(Icons.Default.Refresh, contentDescription = "换一批")
                        }
                    }
                }

                if (recommendations.isEmpty()) {
                    item {
                        EmptyState(
                            emoji = "✨",
                            title = "暂无推荐",
                            description = "添加更多衣物后将为你智能搭配"
                        )
                    }
                } else {
                    item {
                        val pagerState = rememberPagerState(pageCount = { recommendations.size })
                        HorizontalPager(
                            state = pagerState,
                            modifier = Modifier.fillMaxWidth(),
                            contentPadding = PaddingValues(horizontal = 16.dp),
                            pageSpacing = 12.dp
                        ) { page ->
                            OutfitCard(
                                recommendation = recommendations[page],
                                onWearClick = { /* mark as worn */ }
                            )
                        }
                    }
                }

                if (purchaseSuggestions.isNotEmpty()) {
                    item {
                        Spacer(modifier = Modifier.height(24.dp))
                        Text(
                            text = "购物建议",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(horizontal = 16.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }

                    items(purchaseSuggestions) { suggestion ->
                        PurchaseSuggestionItem(
                            suggestion = suggestion,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                        )
                    }
                }
            }
        }
    }
}

data class WeatherDisplayData(
    val temperature: Double,
    val feelsLike: Double,
    val description: String,
    val emoji: String,
    val suggestion: String,
    val city: String,
    val tempMin: Double,
    val tempMax: Double,
    val humidity: Int
)
