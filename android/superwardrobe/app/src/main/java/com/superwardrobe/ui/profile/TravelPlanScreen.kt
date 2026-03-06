package com.superwardrobe.ui.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.superwardrobe.data.model.TravelPlan
import com.superwardrobe.ui.common.EmptyState
import com.superwardrobe.util.toDisplayDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TravelPlanScreen(
    onBack: () -> Unit
) {
    var showCreateDialog by remember { mutableStateOf(false) }

    val plans = remember {
        mutableStateListOf(
            TravelPlan(
                id = "1",
                destination = "东京",
                startDate = "2024-04-10",
                endDate = "2024-04-17",
                notes = "樱花季旅行，需要准备春季和偏凉天气的衣物"
            ),
            TravelPlan(
                id = "2",
                destination = "三亚",
                startDate = "2024-05-01",
                endDate = "2024-05-05",
                notes = "海边度假，准备泳衣和防晒衣物"
            )
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("旅行计划") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showCreateDialog = true },
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(Icons.Default.Add, contentDescription = "新建计划")
            }
        }
    ) { padding ->
        if (plans.isEmpty()) {
            EmptyState(
                modifier = Modifier.padding(padding),
                emoji = "✈️",
                title = "还没有旅行计划",
                description = "创建旅行计划，AI帮你规划每日穿搭",
                actionText = "创建计划",
                onAction = { showCreateDialog = true }
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(plans) { plan ->
                    TravelPlanCard(
                        plan = plan,
                        onDelete = { plans.remove(plan) }
                    )
                }
            }
        }
    }

    if (showCreateDialog) {
        CreateTravelPlanDialog(
            onDismiss = { showCreateDialog = false },
            onConfirm = { destination, startDate, endDate, notes ->
                plans.add(
                    TravelPlan(
                        id = System.currentTimeMillis().toString(),
                        destination = destination,
                        startDate = startDate,
                        endDate = endDate,
                        notes = notes
                    )
                )
                showCreateDialog = false
            }
        )
    }
}

@Composable
private fun TravelPlanCard(
    plan: TravelPlan,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.LocationOn,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = plan.destination,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }
                IconButton(onClick = onDelete) {
                    Icon(
                        Icons.Default.Delete,
                        contentDescription = "删除",
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Default.DateRange,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "${plan.startDate.toDisplayDate()} - ${plan.endDate.toDisplayDate()}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            plan.notes?.let {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Button(
                onClick = { /* open day-by-day planner */ },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(8.dp)
            ) {
                Text("规划每日穿搭")
            }
        }
    }
}

@Composable
private fun CreateTravelPlanDialog(
    onDismiss: () -> Unit,
    onConfirm: (String, String, String, String?) -> Unit
) {
    var destination by remember { mutableStateOf("") }
    var startDate by remember { mutableStateOf("") }
    var endDate by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("新建旅行计划") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = destination,
                    onValueChange = { destination = it },
                    label = { Text("目的地") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = startDate,
                    onValueChange = { startDate = it },
                    label = { Text("开始日期 (YYYY-MM-DD)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = endDate,
                    onValueChange = { endDate = it },
                    label = { Text("结束日期 (YYYY-MM-DD)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("备注") },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 3
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onConfirm(destination, startDate, endDate, notes.ifBlank { null })
                },
                enabled = destination.isNotBlank() && startDate.isNotBlank() && endDate.isNotBlank()
            ) {
                Text("创建")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}
