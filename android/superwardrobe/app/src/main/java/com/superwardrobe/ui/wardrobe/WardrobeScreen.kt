package com.superwardrobe.ui.wardrobe

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.superwardrobe.data.model.Category
import com.superwardrobe.data.model.ClothingItem
import com.superwardrobe.ui.common.EmptyState

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun WardrobeScreen(
    onItemClick: (String) -> Unit = {}
) {
    var searchQuery by remember { mutableStateOf("") }
    var searchActive by remember { mutableStateOf(false) }
    var selectedCategoryIndex by remember { mutableIntStateOf(0) }
    var showFilterSheet by remember { mutableStateOf(false) }

    val categories = remember {
        mutableStateListOf(
            Category(id = "all", name = "全部", sortOrder = 0),
            Category(id = "tops", name = "上衣", sortOrder = 1),
            Category(id = "bottoms", name = "裤子", sortOrder = 2),
            Category(id = "dresses", name = "裙装", sortOrder = 3),
            Category(id = "outerwear", name = "外套", sortOrder = 4),
            Category(id = "shoes", name = "鞋子", sortOrder = 5),
            Category(id = "accessories", name = "配饰", sortOrder = 6),
            Category(id = "bags", name = "包包", sortOrder = 7)
        )
    }

    val items = remember {
        mutableStateListOf(
            ClothingItem(id = "1", name = "白色T恤", color = "白色", wearCount = 15, season = "夏"),
            ClothingItem(id = "2", name = "深蓝牛仔裤", color = "蓝色", wearCount = 12, season = "四季"),
            ClothingItem(id = "3", name = "黑色西装外套", color = "黑色", wearCount = 5, season = "四季")
        )
    }

    var contextMenuItemId by remember { mutableStateOf<String?>(null) }

    Column(modifier = Modifier.fillMaxSize()) {
        SearchBar(
            query = searchQuery,
            onQueryChange = { searchQuery = it },
            onSearch = { searchActive = false },
            active = searchActive,
            onActiveChange = { searchActive = it },
            placeholder = { Text("搜索衣物...") },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = "搜索") },
            trailingIcon = {
                IconButton(onClick = { showFilterSheet = true }) {
                    Icon(Icons.Default.FilterList, contentDescription = "筛选")
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = if (searchActive) 0.dp else 16.dp)
        ) {
            Text("搜索建议区域", modifier = Modifier.padding(16.dp))
        }

        Spacer(modifier = Modifier.height(8.dp))

        ScrollableTabRow(
            selectedTabIndex = selectedCategoryIndex,
            modifier = Modifier.fillMaxWidth(),
            edgePadding = 16.dp,
            divider = {}
        ) {
            categories.forEachIndexed { index, category ->
                Tab(
                    selected = selectedCategoryIndex == index,
                    onClick = { selectedCategoryIndex = index },
                    text = { Text(category.name) }
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        if (items.isEmpty()) {
            EmptyState(
                emoji = "👗",
                title = "衣橱还是空的",
                description = "点击下方+号添加你的第一件衣物",
                actionText = "添加衣物",
                onAction = { /* trigger add */ }
            )
        } else {
            LazyVerticalStaggeredGrid(
                columns = StaggeredGridCells.Fixed(2),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalItemSpacing = 12.dp
            ) {
                items(items, key = { it.id }) { item ->
                    Box {
                        ClothingItemCard(
                            item = item,
                            modifier = Modifier.combinedClickable(
                                onClick = { onItemClick(item.id) },
                                onLongClick = { contextMenuItemId = item.id }
                            )
                        )
                        DropdownMenu(
                            expanded = contextMenuItemId == item.id,
                            onDismissRequest = { contextMenuItemId = null }
                        ) {
                            DropdownMenuItem(
                                text = { Text("编辑") },
                                onClick = {
                                    contextMenuItemId = null
                                    onItemClick(item.id)
                                }
                            )
                            DropdownMenuItem(
                                text = { Text("删除", color = MaterialTheme.colorScheme.error) },
                                onClick = {
                                    contextMenuItemId = null
                                    items.remove(item)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    if (showFilterSheet) {
        ModalBottomSheet(onDismissRequest = { showFilterSheet = false }) {
            FilterSheet(onDismiss = { showFilterSheet = false })
        }
    }
}
