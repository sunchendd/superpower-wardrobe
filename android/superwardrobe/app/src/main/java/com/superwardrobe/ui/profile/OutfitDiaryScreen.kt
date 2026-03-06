package com.superwardrobe.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.superwardrobe.data.model.OutfitDiary
import com.superwardrobe.ui.common.EmptyState
import com.superwardrobe.util.toDisplayDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OutfitDiaryScreen(
    onBack: () -> Unit
) {
    val diaries = remember {
        mutableStateListOf(
            OutfitDiary(
                id = "1",
                date = "2024-03-14",
                mood = "😊 开心",
                note = "今天穿了最爱的白色T恤搭配牛仔裤，感觉很舒服！",
                weather = "晴",
                temperature = 22.0
            ),
            OutfitDiary(
                id = "2",
                date = "2024-03-12",
                mood = "😎 自信",
                note = "面试穿了黑色西装，感觉自己超帅！",
                weather = "多云",
                temperature = 18.0
            ),
            OutfitDiary(
                id = "3",
                date = "2024-03-10",
                mood = "😌 舒适",
                note = "周末在家穿灰色卫衣，轻松休闲的一天",
                weather = "阴",
                temperature = 15.0
            )
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("穿搭日记") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { /* add new diary */ },
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(Icons.Default.Add, contentDescription = "添加日记")
            }
        }
    ) { padding ->
        if (diaries.isEmpty()) {
            EmptyState(
                modifier = Modifier.padding(padding),
                emoji = "📔",
                title = "还没有穿搭日记",
                description = "记录每天的穿搭感受吧"
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(0.dp)
            ) {
                itemsIndexed(diaries) { index, diary ->
                    Row(modifier = Modifier.fillMaxWidth()) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.width(32.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(12.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (index == 0) MaterialTheme.colorScheme.primary
                                        else MaterialTheme.colorScheme.outline
                                    )
                            )
                            if (index < diaries.lastIndex) {
                                Box(
                                    modifier = Modifier
                                        .width(2.dp)
                                        .height(IntrinsicSize.Max)
                                        .defaultMinSize(minHeight = 120.dp)
                                        .background(MaterialTheme.colorScheme.outlineVariant)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.width(12.dp))

                        Card(
                            modifier = Modifier
                                .weight(1f)
                                .padding(bottom = 12.dp),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(
                                        text = diary.date.toDisplayDate(),
                                        style = MaterialTheme.typography.titleSmall,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                    diary.mood?.let {
                                        Text(
                                            text = it,
                                            style = MaterialTheme.typography.bodySmall
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.height(8.dp))

                                diary.photoUrl?.let { url ->
                                    AsyncImage(
                                        model = url,
                                        contentDescription = "穿搭照片",
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(180.dp)
                                            .clip(RoundedCornerShape(8.dp)),
                                        contentScale = ContentScale.Crop
                                    )
                                    Spacer(modifier = Modifier.height(8.dp))
                                }

                                diary.note?.let {
                                    Text(
                                        text = it,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }

                                Spacer(modifier = Modifier.height(8.dp))

                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    diary.weather?.let {
                                        AssistChip(
                                            onClick = {},
                                            label = {
                                                Text(
                                                    "$it ${diary.temperature?.toInt() ?: ""}°C",
                                                    style = MaterialTheme.typography.labelSmall
                                                )
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
