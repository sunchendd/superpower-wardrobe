package com.superwardrobe.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColorScheme = lightColorScheme(
    primary = Rose500,
    onPrimary = White,
    primaryContainer = Rose100,
    onPrimaryContainer = Rose900,
    secondary = Teal500,
    onSecondary = White,
    secondaryContainer = Color(0xFFB2DFDB),
    onSecondaryContainer = Teal600,
    tertiary = Amber500,
    onTertiary = White,
    tertiaryContainer = Amber100,
    onTertiaryContainer = Amber600,
    background = Slate50,
    onBackground = Slate900,
    surface = White,
    onSurface = Slate900,
    surfaceVariant = Slate100,
    onSurfaceVariant = Slate600,
    outline = Slate300,
    outlineVariant = Slate200,
    error = Color(0xFFDC2626),
    onError = White
)

private val DarkColorScheme = darkColorScheme(
    primary = Rose400,
    onPrimary = Rose900,
    primaryContainer = Rose800,
    onPrimaryContainer = Rose100,
    secondary = Teal400,
    onSecondary = Color(0xFF003735),
    secondaryContainer = Color(0xFF00504E),
    onSecondaryContainer = Color(0xFFB2DFDB),
    tertiary = Amber400,
    onTertiary = Color(0xFF3F2E00),
    tertiaryContainer = Color(0xFF5B4300),
    onTertiaryContainer = Amber200,
    background = Slate900,
    onBackground = Slate100,
    surface = Slate800,
    onSurface = Slate100,
    surfaceVariant = Slate700,
    onSurfaceVariant = Slate300,
    outline = Slate500,
    outlineVariant = Slate600,
    error = Color(0xFFF87171),
    onError = Color(0xFF690005)
)

@Composable
fun SuperWardrobeTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.background.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        content = content
    )
}
