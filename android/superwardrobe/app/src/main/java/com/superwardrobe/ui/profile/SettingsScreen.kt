package com.superwardrobe.ui.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.superwardrobe.util.Constants

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit
) {
    var nickname by remember { mutableStateOf("时尚达人") }
    var gender by remember { mutableStateOf("女") }
    var height by remember { mutableStateOf("165") }
    var weight by remember { mutableStateOf("55") }
    var bodyType by remember { mutableStateOf("标准") }
    var location by remember { mutableStateOf("北京") }
    var selectedStyles by remember { mutableStateOf(setOf("休闲", "简约")) }
    var selectedColors by remember { mutableStateOf(setOf("黑色", "白色", "蓝色")) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("个人设置") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    TextButton(onClick = { /* save settings */ }) {
                        Text("保存")
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
                SettingsSection(title = "基本信息") {
                    OutlinedTextField(
                        value = nickname,
                        onValueChange = { nickname = it },
                        label = { Text("昵称") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    Text(
                        text = "性别",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("男", "女", "其他").forEach { g ->
                            FilterChip(
                                selected = gender == g,
                                onClick = { gender = g },
                                label = { Text(g) }
                            )
                        }
                    }
                }
            }

            item {
                SettingsSection(title = "身体信息") {
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedTextField(
                            value = height,
                            onValueChange = { height = it },
                            label = { Text("身高(cm)") },
                            modifier = Modifier.weight(1f),
                            singleLine = true
                        )
                        OutlinedTextField(
                            value = weight,
                            onValueChange = { weight = it },
                            label = { Text("体重(kg)") },
                            modifier = Modifier.weight(1f),
                            singleLine = true
                        )
                    }
                    Spacer(modifier = Modifier.height(12.dp))

                    Text(
                        text = "体型",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf("偏瘦", "标准", "微胖", "健壮").forEach { type ->
                            FilterChip(
                                selected = bodyType == type,
                                onClick = { bodyType = type },
                                label = { Text(type) }
                            )
                        }
                    }
                }
            }

            item {
                SettingsSection(title = "风格偏好") {
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
                }
            }

            item {
                SettingsSection(title = "偏好颜色") {
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
                }
            }

            item {
                SettingsSection(title = "位置") {
                    OutlinedTextField(
                        value = location,
                        onValueChange = { location = it },
                        label = { Text("所在城市") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                }
            }

            item {
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedButton(
                    onClick = { /* sign out */ },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Logout,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("退出登录")
                }
            }

            item {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
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
