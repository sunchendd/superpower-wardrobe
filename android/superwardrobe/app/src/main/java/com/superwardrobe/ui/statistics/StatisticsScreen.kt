package com.superwardrobe.ui.statistics

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.superwardrobe.util.toCurrencyString

@Composable
fun StatisticsScreen() {
    val totalItems = 45
    val totalSpending = 12580.0
    val avgPrice = totalSpending / totalItems
    val categoryData = listOf(
        "上衣" to 15,
        "裤子" to 10,
        "裙装" to 5,
        "外套" to 6,
        "鞋子" to 5,
        "配饰" to 4
    )
    val colorData = listOf(
        "黑色" to 12,
        "白色" to 10,
        "蓝色" to 8,
        "灰色" to 5,
        "红色" to 4,
        "绿色" to 3,
        "其他" to 3
    )
    val utilizationData = listOf(
        Triple("白色T恤", 25, "上衣"),
        Triple("深蓝牛仔裤", 22, "裤子"),
        Triple("黑色西装外套", 18, "外套"),
        Triple("白色运动鞋", 15, "鞋子"),
        Triple("灰色卫衣", 12, "上衣"),
        Triple("黑色小脚裤", 10, "裤子"),
        Triple("米色风衣", 8, "外套"),
        Triple("粉色连衣裙", 3, "裙装"),
        Triple("红色高跟鞋", 1, "鞋子"),
        Triple("紫色围巾", 0, "配饰")
    )

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text(
                text = "衣橱统计",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                SummaryCard(
                    title = "总件数",
                    value = "${totalItems}件",
                    modifier = Modifier.weight(1f)
                )
                SummaryCard(
                    title = "总花费",
                    value = totalSpending.toCurrencyString(),
                    modifier = Modifier.weight(1f)
                )
                SummaryCard(
                    title = "均价",
                    value = avgPrice.toCurrencyString(),
                    modifier = Modifier.weight(1f)
                )
            }
        }

        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "品类分布",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )
                    CategoryPieChart(data = categoryData)
                }
            }
        }

        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "颜色分布",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )
                    ColorDistributionChart(data = colorData)
                }
            }
        }

        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "使用排行",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )
                    UtilizationRanking(data = utilizationData)
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun SummaryCard(
    title: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
        }
    }
}
