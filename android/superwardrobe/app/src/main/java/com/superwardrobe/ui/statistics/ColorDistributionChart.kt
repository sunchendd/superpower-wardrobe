package com.superwardrobe.ui.statistics

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.superwardrobe.util.toColor

@Composable
fun ColorDistributionChart(
    data: List<Pair<String, Int>>,
    modifier: Modifier = Modifier
) {
    val maxCount = data.maxOfOrNull { it.second } ?: 1

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        data.forEach { (colorName, count) ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = colorName,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.width(48.dp)
                )

                Spacer(modifier = Modifier.width(8.dp))

                Box(modifier = Modifier
                    .weight(1f)
                    .height(20.dp)
                ) {
                    val barColor = colorName.toColor()
                    val fraction = count.toFloat() / maxCount.toFloat()

                    Canvas(modifier = Modifier.fillMaxSize()) {
                        drawRoundRect(
                            color = barColor.copy(alpha = 0.15f),
                            size = size,
                            cornerRadius = CornerRadius(6f, 6f)
                        )
                        drawRoundRect(
                            color = barColor,
                            size = Size(size.width * fraction, size.height),
                            cornerRadius = CornerRadius(6f, 6f)
                        )
                    }
                }

                Spacer(modifier = Modifier.width(8.dp))

                Text(
                    text = "$count",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.width(24.dp)
                )
            }
        }
    }
}
