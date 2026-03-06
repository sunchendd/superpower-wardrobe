package com.superwardrobe.ui.wardrobe

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.superwardrobe.data.model.ClothingItem
import com.superwardrobe.util.toColor
import com.superwardrobe.util.toCurrencyString
import com.superwardrobe.util.toDisplayDate
import com.superwardrobe.util.toWearCountLabel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ClothingItemDetailScreen(
    itemId: String,
    onBack: () -> Unit
) {
    var showDeleteDialog by remember { mutableStateOf(false) }

    val item = remember {
        mutableStateOf(
            ClothingItem(
                id = itemId,
                name = "白色T恤",
                color = "白色",
                brand = "优衣库",
                season = "夏",
                styleTags = listOf("休闲", "简约"),
                purchasePrice = 99.0,
                purchaseDate = "2024-01-15",
                wearCount = 15,
                status = "active"
            )
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(item.value.name ?: "衣物详情") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = { /* edit */ }) {
                        Icon(Icons.Default.Edit, contentDescription = "编辑")
                    }
                    IconButton(onClick = { showDeleteDialog = true }) {
                        Icon(
                            Icons.Default.Delete,
                            contentDescription = "删除",
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(300.dp),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    if (item.value.imageUrl != null) {
                        AsyncImage(
                            model = item.value.imageUrl,
                            contentDescription = item.value.name,
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .background(MaterialTheme.colorScheme.surfaceVariant),
                            contentAlignment = Alignment.Center
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(80.dp)
                                    .clip(CircleShape)
                                    .background(item.value.color.toColor())
                            )
                        }
                    }
                }
            }

            item {
                DetailSection(title = "基本信息") {
                    DetailRow("名称", item.value.name ?: "未命名")
                    DetailRow("品牌", item.value.brand ?: "未知")
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            "颜色",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.width(80.dp)
                        )
                        Box(
                            modifier = Modifier
                                .size(16.dp)
                                .clip(CircleShape)
                                .background(item.value.color.toColor())
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(item.value.color, style = MaterialTheme.typography.bodyMedium)
                    }
                    DetailRow("季节", item.value.season ?: "四季")
                    DetailRow("状态", if (item.value.status == "active") "使用中" else "已归档")
                }
            }

            item {
                DetailSection(title = "风格标签") {
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(item.value.styleTags) { tag ->
                            AssistChip(
                                onClick = {},
                                label = { Text(tag) }
                            )
                        }
                    }
                }
            }

            item {
                DetailSection(title = "穿着记录") {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatItem("穿着次数", "${item.value.wearCount}次")
                        StatItem("穿着频率", item.value.wearCount.toWearCountLabel())
                    }
                }
            }

            item {
                DetailSection(title = "购买信息") {
                    item.value.purchasePrice?.let {
                        DetailRow("购买价格", it.toCurrencyString())
                    }
                    item.value.purchaseDate?.let {
                        DetailRow("购买日期", it.toDisplayDate())
                    }
                    item.value.purchaseUrl?.let {
                        DetailRow("购买链接", it)
                    }
                }
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("确认删除") },
            text = { Text("确定要删除「${item.value.name}」吗？此操作不可撤销。") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        onBack()
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
private fun DetailSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(bottom = 12.dp)
            )
            content()
        }
    }
}

@Composable
private fun DetailRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun StatItem(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
