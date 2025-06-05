import 'package:flutter/material.dart';

/// A widget that displays a visual trend indicator (up, down or stable)
class TrendIndicator extends StatelessWidget {
  /// The trend direction: "upward", "downward", or "stable"
  final String trend;
  
  /// Size of the indicator
  final double size;
  
  /// Optional custom colors
  final Color? upColor;
  final Color? downColor;
  final Color? stableColor;
  
  /// Constructor
  const TrendIndicator({
    super.key, 
    required this.trend, 
    this.size = 24.0,
    this.upColor,
    this.downColor,
    this.stableColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color arrowUpColor = upColor ?? Colors.red;
    final Color arrowDownColor = downColor ?? Colors.green;
    final Color stableLineColor = stableColor ?? Colors.grey;
    
    Icon icon;
    String tooltip;
    
    switch (trend.toLowerCase()) {
      case "upward":
        icon = Icon(
          Icons.arrow_upward,
          color: arrowUpColor,
          size: size,
        );
        tooltip = "Wzrostowy"; // Rising trend
        break;
      case "downward":
        icon = Icon(
          Icons.arrow_downward,
          color: arrowDownColor,
          size: size,
        );
        tooltip = "Spadkowy"; // Falling trend
        break;
      default: // stable
        icon = Icon(
          Icons.trending_flat,
          color: stableLineColor,
          size: size,
        );
        tooltip = "Stabilny"; // Stable trend
    }
    
    return Tooltip(
      message: tooltip,
      child: icon,
    );
  }
}

/// A more detailed trend indicator that shows a card with trend information
class DetailedTrendIndicator extends StatelessWidget {
  /// The trend direction: "upward", "downward", or "stable"
  final String trend;
  
  /// The percentage change
  final double percentChange;
  
  /// Display a label for the trend
  final String label;
  
  /// Whether to invert the colors (for metrics where down is good, up is bad)
  final bool invertColors;
  
  /// Optional styling
  final TextStyle? labelStyle;
  final TextStyle? percentStyle;
  
  /// Constructor
  const DetailedTrendIndicator({
    super.key, 
    required this.trend,
    required this.percentChange,
    required this.label,
    this.invertColors = false,
    this.labelStyle,
    this.percentStyle,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _getBackgroundColor();
    final Color textColor = Colors.white;
    
    return Card(
      elevation: 2,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TrendIndicator(
              trend: trend, 
              size: 20,
              upColor: Colors.white,
              downColor: Colors.white,
              stableColor: Colors.white,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: labelStyle ?? TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  '${percentChange.abs().toStringAsFixed(1)}%',
                  style: percentStyle ?? TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
  
  Color _getBackgroundColor() {
    switch (trend.toLowerCase()) {
      case "upward":
        return invertColors ? Colors.green.shade700 : Colors.red.shade700;
      case "downward":
        return invertColors ? Colors.red.shade700 : Colors.green.shade700;
      default: // stable
        return Colors.grey.shade600;
    }
  }
}
