package com.superwardrobe.ui.wardrobe

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.superwardrobe.util.Constants

@Composable
fun FilterSheet(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedSeason by remember { mutableStateOf<String?>(null) }
    var selectedColors by remember { mutableStateOf(setOf<String>()) }
    var selectedStyles by remember { mutableStateOf(setOf<String>()) }
    var sortBy by remember { mutableStateOf("最近添加") }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(bottom = 32.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Text(
            text = "筛选与排序",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 20.dp)
        )

        Text(
            text = "排序方式",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            listOf("最近添加", "穿着最多", "穿着最少", "价格最高", "价格最低").forEach { option ->
                FilterChip(
                    selected = sortBy == option,
                    onClick = { sortBy = option },
                    label = { Text(option) }
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "季节",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Constants.Seasons.ALL.forEach { season ->
                FilterChip(
                    selected = selectedSeason == season,
                    onClick = { selectedSeason = if (selectedSeason == season) null else season },
                    label = { Text(season) }
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "颜色",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Constants.Colors.COMMON.forEach { color ->
                FilterChip(
                    selected = color in selectedColors,
                    onClick = {
                        selectedColors = if (color in selectedColors) {
                            selectedColors - color
                        } else {
                            selectedColors + color
                        }
                    },
                    label = { Text(color) }
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "风格",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Constants.Styles.ALL.forEach { style ->
                FilterChip(
                    selected = style in selectedStyles,
                    onClick = {
                        selectedStyles = if (style in selectedStyles) {
                            selectedStyles - style
                        } else {
                            selectedStyles + style
                        }
                    },
                    label = { Text(style) }
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OutlinedButton(
                onClick = {
                    selectedSeason = null
                    selectedColors = emptySet()
                    selectedStyles = emptySet()
                    sortBy = "最近添加"
                },
                modifier = Modifier.weight(1f)
            ) {
                Text("重置")
            }
            Button(
                onClick = onDismiss,
                modifier = Modifier.weight(1f)
            ) {
                Text("应用")
            }
        }
    }
}
