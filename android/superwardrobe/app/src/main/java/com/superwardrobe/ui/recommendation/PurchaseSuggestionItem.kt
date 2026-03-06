package com.superwardrobe.ui.recommendation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.superwardrobe.data.model.PurchaseRecommendation
import com.superwardrobe.util.toCurrencyString

@Composable
fun PurchaseSuggestionItem(
    suggestion: PurchaseRecommendation,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.ShoppingBag,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.secondary,
                modifier = Modifier.size(32.dp)
            )

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = suggestion.category,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = suggestion.reason,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
                )
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(top = 4.dp)
                ) {
                    suggestion.suggestedColor?.let {
                        AssistChip(
                            onClick = {},
                            label = { Text(it, style = MaterialTheme.typography.labelSmall) }
                        )
                    }
                    suggestion.suggestedStyle?.let {
                        AssistChip(
                            onClick = {},
                            label = { Text(it, style = MaterialTheme.typography.labelSmall) }
                        )
                    }
                    if (suggestion.priceRangeMin != null && suggestion.priceRangeMax != null) {
                        Text(
                            text = "${suggestion.priceRangeMin.toCurrencyString()} - ${suggestion.priceRangeMax.toCurrencyString()}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.6f),
                            modifier = Modifier.align(Alignment.CenterVertically)
                        )
                    }
                }
            }

            IconButton(onClick = { /* navigate to shopping */ }) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = "查看",
                    tint = MaterialTheme.colorScheme.secondary
                )
            }
        }
    }
}
