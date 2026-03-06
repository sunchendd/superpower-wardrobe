package com.superwardrobe

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.superwardrobe.navigation.AppNavigation
import com.superwardrobe.ui.theme.SuperWardrobeTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SuperWardrobeTheme {
                AppNavigation()
            }
        }
    }
}
