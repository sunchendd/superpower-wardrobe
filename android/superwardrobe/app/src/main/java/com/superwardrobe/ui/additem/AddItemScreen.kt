package com.superwardrobe.ui.additem

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Link
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@Composable
fun AddItemScreen(
    onDismiss: () -> Unit
) {
    var showCamera by remember { mutableStateOf(false) }
    var showEditScreen by remember { mutableStateOf(false) }
    var capturedImageBytes by remember { mutableStateOf<ByteArray?>(null) }

    if (showCamera) {
        CameraCapture(
            onImageCaptured = { bytes ->
                capturedImageBytes = bytes
                showCamera = false
                showEditScreen = true
            },
            onDismiss = { showCamera = false }
        )
    } else if (showEditScreen) {
        ItemEditScreen(
            imageBytes = capturedImageBytes,
            onSave = { onDismiss() },
            onCancel = {
                showEditScreen = false
                capturedImageBytes = null
            }
        )
    } else {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp)
        ) {
            Text(
                text = "添加衣物",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 24.dp)
            )

            AddOptionItem(
                icon = Icons.Default.CameraAlt,
                title = "拍照添加",
                description = "使用相机拍摄衣物照片，AI自动识别分类",
                onClick = { showCamera = true }
            )

            Spacer(modifier = Modifier.height(12.dp))

            AddOptionItem(
                icon = Icons.Default.Image,
                title = "从相册选择",
                description = "从手机相册中选择衣物照片",
                onClick = {
                    showEditScreen = true
                }
            )

            Spacer(modifier = Modifier.height(12.dp))

            AddOptionItem(
                icon = Icons.Default.Link,
                title = "输入链接",
                description = "粘贴购物链接，自动获取衣物信息",
                onClick = {
                    showEditScreen = true
                }
            )
        }
    }
}

@Composable
private fun AddOptionItem(
    icon: ImageVector,
    title: String,
    description: String,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(48.dp),
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.primaryContainer
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = icon,
                        contentDescription = title,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
