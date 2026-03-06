package com.superwardrobe.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Checkroom
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.outlined.Checkroom
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PieChart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.superwardrobe.ui.additem.AddItemScreen
import com.superwardrobe.ui.profile.OutfitCalendarScreen
import com.superwardrobe.ui.profile.OutfitDiaryScreen
import com.superwardrobe.ui.profile.ProfileScreen
import com.superwardrobe.ui.profile.SettingsScreen
import com.superwardrobe.ui.profile.TravelPlanScreen
import com.superwardrobe.ui.recommendation.RecommendationScreen
import com.superwardrobe.ui.statistics.StatisticsScreen
import com.superwardrobe.ui.wardrobe.ClothingItemDetailScreen
import com.superwardrobe.ui.wardrobe.WardrobeScreen

sealed class Screen(val route: String, val label: String) {
    data object Recommendation : Screen("recommendation", "推荐")
    data object Wardrobe : Screen("wardrobe", "衣橱")
    data object AddItem : Screen("add_item", "添加")
    data object Statistics : Screen("statistics", "统计")
    data object Profile : Screen("profile", "我的")
    data object ClothingDetail : Screen("clothing_detail/{itemId}", "详情") {
        fun createRoute(itemId: String) = "clothing_detail/$itemId"
    }
    data object OutfitCalendar : Screen("outfit_calendar", "穿搭日历")
    data object OutfitDiary : Screen("outfit_diary", "穿搭日记")
    data object TravelPlan : Screen("travel_plan", "旅行计划")
    data object Settings : Screen("settings", "设置")
}

data class BottomNavItem(
    val screen: Screen,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    var showAddSheet by remember { mutableStateOf(false) }

    val bottomNavItems = listOf(
        BottomNavItem(Screen.Recommendation, Icons.Filled.Home, Icons.Outlined.Home),
        BottomNavItem(Screen.Wardrobe, Icons.Filled.Checkroom, Icons.Outlined.Checkroom),
        BottomNavItem(Screen.AddItem, Icons.Filled.Add, Icons.Filled.Add),
        BottomNavItem(Screen.Statistics, Icons.Filled.PieChart, Icons.Outlined.PieChart),
        BottomNavItem(Screen.Profile, Icons.Filled.Person, Icons.Outlined.Person)
    )

    val showBottomBar = currentRoute in listOf(
        Screen.Recommendation.route,
        Screen.Wardrobe.route,
        Screen.Statistics.route,
        Screen.Profile.route
    )

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                Box {
                    NavigationBar(
                        containerColor = MaterialTheme.colorScheme.surface,
                        tonalElevation = 8.dp
                    ) {
                        bottomNavItems.forEach { item ->
                            if (item.screen == Screen.AddItem) {
                                NavigationBarItem(
                                    selected = false,
                                    onClick = { showAddSheet = true },
                                    icon = { Box(modifier = Modifier.size(24.dp)) },
                                    label = { Text("") },
                                    colors = NavigationBarItemDefaults.colors(
                                        indicatorColor = MaterialTheme.colorScheme.surface
                                    )
                                )
                            } else {
                                val selected = currentRoute == item.screen.route
                                NavigationBarItem(
                                    selected = selected,
                                    onClick = {
                                        navController.navigate(item.screen.route) {
                                            popUpTo(navController.graph.findStartDestination().id) {
                                                saveState = true
                                            }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    },
                                    icon = {
                                        Icon(
                                            imageVector = if (selected) item.selectedIcon else item.unselectedIcon,
                                            contentDescription = item.screen.label
                                        )
                                    },
                                    label = { Text(item.screen.label) }
                                )
                            }
                        }
                    }
                    FloatingActionButton(
                        onClick = { showAddSheet = true },
                        modifier = Modifier
                            .align(Alignment.TopCenter)
                            .offset(y = (-16).dp)
                            .size(56.dp),
                        shape = CircleShape,
                        containerColor = MaterialTheme.colorScheme.primary,
                        contentColor = MaterialTheme.colorScheme.onPrimary
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Add,
                            contentDescription = "添加衣物",
                            modifier = Modifier.size(28.dp)
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            NavHost(
                navController = navController,
                startDestination = Screen.Recommendation.route
            ) {
                composable(Screen.Recommendation.route) {
                    RecommendationScreen()
                }
                composable(Screen.Wardrobe.route) {
                    WardrobeScreen(
                        onItemClick = { itemId ->
                            navController.navigate(Screen.ClothingDetail.createRoute(itemId))
                        }
                    )
                }
                composable(Screen.Statistics.route) {
                    StatisticsScreen()
                }
                composable(Screen.Profile.route) {
                    ProfileScreen(
                        onNavigateToCalendar = { navController.navigate(Screen.OutfitCalendar.route) },
                        onNavigateToDiary = { navController.navigate(Screen.OutfitDiary.route) },
                        onNavigateToTravelPlan = { navController.navigate(Screen.TravelPlan.route) },
                        onNavigateToSettings = { navController.navigate(Screen.Settings.route) }
                    )
                }
                composable(Screen.ClothingDetail.route) { backStackEntry ->
                    val itemId = backStackEntry.arguments?.getString("itemId") ?: ""
                    ClothingItemDetailScreen(
                        itemId = itemId,
                        onBack = { navController.popBackStack() }
                    )
                }
                composable(Screen.OutfitCalendar.route) {
                    OutfitCalendarScreen(onBack = { navController.popBackStack() })
                }
                composable(Screen.OutfitDiary.route) {
                    OutfitDiaryScreen(onBack = { navController.popBackStack() })
                }
                composable(Screen.TravelPlan.route) {
                    TravelPlanScreen(onBack = { navController.popBackStack() })
                }
                composable(Screen.Settings.route) {
                    SettingsScreen(onBack = { navController.popBackStack() })
                }
            }
        }

        if (showAddSheet) {
            ModalBottomSheet(onDismissRequest = { showAddSheet = false }) {
                AddItemScreen(onDismiss = { showAddSheet = false })
            }
        }
    }
}
