import 'package:flutter/material.dart';
import '../modules/analytics.dart';
import 'trend_indicator.dart';

/// A widget that displays a trend summary card with multiple trend indicators
class TrendSummaryWidget extends StatelessWidget {
  final List<int> symptomsData;
  final List<int> posEmotionsData;
  final List<int> negEmotionsData;
  final int daysRange;
  
  const TrendSummaryWidget({
    super.key,
    required this.symptomsData,
    required this.posEmotionsData,
    required this.negEmotionsData,
    required this.daysRange,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate trends for all data types
    final symptomsTrend = analyzeTrend(symptomsData, daysRange);
    final posEmotionsTrend = analyzeTrend(posEmotionsData, daysRange);
    final negEmotionsTrend = analyzeTrend(negEmotionsData, daysRange);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Podsumowanie trendów",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Display trend indicators in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrendIndicator(
                  "Objawy", 
                  symptomsTrend, 
                  Colors.blue
                ),
                _buildTrendIndicator(
                  "Emocje +", 
                  posEmotionsTrend, 
                  Colors.green,
                  invertColors: true  // Match the analysis dialog - up is green, down is red
                ),
                _buildTrendIndicator(
                  "Emocje -", 
                  negEmotionsTrend, 
                  Colors.red,
                  invertColors: true // invert so that downward is good
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrendIndicator(String label, TrendAnalysis trend, Color baseColor, {bool invertColors = false}) {
    // Determine colors based on trend direction and inversion setting
    Color arrowColor;
    if (trend.direction == "upward") {
      arrowColor = invertColors ? Colors.green : Colors.red;
    } else if (trend.direction == "downward") {
      arrowColor = invertColors ? Colors.red : Colors.green;
    } else {
      arrowColor = Colors.grey;
    }
    
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TrendIndicator(
          trend: trend.direction,
          size: 28,
          upColor: arrowColor,
          downColor: invertColors ? Colors.red : Colors.green,
        ),
        const SizedBox(height: 4),
        Text(
          "${trend.percentChange > 0 ? '+' : ''}${trend.percentChange.toStringAsFixed(1)}%",
          style: TextStyle(
            color: trend.isSignificant ? arrowColor : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
