
/// Class to hold trend analysis results
class TrendAnalysis {
  /// Direction of the trend: "upward", "downward", or "stable"
  final String direction;
  
  /// Percentage change (positive for increase, negative for decrease)
  final double percentChange;
  
  /// Constructor
  TrendAnalysis(this.direction, this.percentChange);
  
  /// Whether the trend is significant in either direction
  bool get isSignificant => percentChange.abs() > 10.0;
  
  @override
  String toString() => '$direction (${percentChange.toStringAsFixed(2)}%)';
}

class Analytics {
  final int userId;
  final String? userName; 

  const Analytics({
    required this.userId,
    this.userName,
  });
  
}

double averageOfSymptoms(List<int> dailySymptoms, int days) {
  if (dailySymptoms.isEmpty) return 0;
  
  // Take the most recent 'days' data points
  final recent = dailySymptoms.length > days 
      ? dailySymptoms.sublist(dailySymptoms.length - days)
      : dailySymptoms;
  
  if (recent.isEmpty) return 0;
  final sum = recent.reduce((a, b) => a + b);
  return sum / recent.length;
}


/// Returns "upward", "downward", or "stable" trend for the last [days] of symptom counts.
/// Uses a simpler and more reliable approach comparing recent vs overall averages.
String symptomTrend(List<int> dailySymptoms, int days) {
  // Take the most recent 'days' data points (from the end of the list)
  final recent = dailySymptoms.length > days 
      ? dailySymptoms.sublist(dailySymptoms.length - days)
      : dailySymptoms;
  
  if (recent.length < 4) return "stable"; // Need at least 4 data points
  
  // Use simple average comparison which is more reliable than EMA for this use case
  // Compare recent 3-7 days with overall average
  int recentDays = recent.length >= 7 ? 3 : 2; // Use last 3 days if we have enough data, otherwise 2
  
  double recentAvg = averageOfSymptoms(recent, recentDays);
  double overallAvg = averageOfSymptoms(recent, recent.length);
  
  if (overallAvg == 0) return "stable"; // Avoid division by zero
  
  double relativeChange = (recentAvg - overallAvg) / overallAvg;
  
  // Use more sensitive thresholds for better trend detection
  // 1% change threshold means we detect trends when recent average is 1% different from overall
  if (relativeChange > 0.01) return "upward";
  if (relativeChange < -0.01) return "downward";
  return "stable";
}

/// Calculate relative change between recent average and overall average
/// Returns a percentage value (e.g. 20.5 means 20.5% increase)
double calculateRelativeChange(List<int> values, int recentDays, int totalDays) {
  if (values.isEmpty) return 0.0;
  
  // Get recent and overall averages
  double recentAvg = averageOfSymptoms(values, recentDays);
  double overallAvg = averageOfSymptoms(values, totalDays);
  
  // Avoid division by zero
  if (overallAvg == 0) {
    return recentAvg > 0 ? 100.0 : 0.0; // If recent has values but overall is 0, it's a 100% increase
  }
  
  // Calculate relative change in percentage
  return ((recentAvg / overallAvg) - 1) * 100;
}

/// Enhanced trend calculation that combines both moving averages and relative changes
/// Returns a TrendAnalysis object with all trend information
TrendAnalysis analyzeTrend(List<int> values, int daysRange) {
  if (values.isEmpty) {
    return TrendAnalysis('stable', 0.0);
  }
  
  // Get trend direction using the improved symptom trend function
  String direction = symptomTrend(values, daysRange);
  
  // Calculate percentage change for display
  double percentChange = calculateRelativeChange(values, 3, daysRange);
  
  // If symptomTrend still returns stable but we have significant percentage change,
  // override with the direction indicated by percentage change
  if (direction == 'stable' && percentChange.abs() >= 1.0) {
    direction = percentChange > 0 ? 'upward' : 'downward';
  }
  
  // Ensure consistency: if direction is not stable, percentage should match direction
  if (direction == 'upward' && percentChange < 0) {
    direction = 'downward';
  } else if (direction == 'downward' && percentChange > 0) {
    direction = 'upward';
  }
  
  if (percentChange == 0.0) {
    return TrendAnalysis('stable', 0.0);
  }
  
  return TrendAnalysis(direction, percentChange);
}

String performCalculation(symptomsRaw, emoPlusRaw, emoMinusRaw, _daysRange) {
  String message = "Objawy: "; 
  // Analyze all trends
  TrendAnalysis symptomsTrend = analyzeTrend(symptomsRaw, _daysRange);
  TrendAnalysis emoPlusTrend = analyzeTrend(emoPlusRaw, _daysRange);
  TrendAnalysis emoMinusTrend = analyzeTrend(emoMinusRaw, _daysRange);
  
  // Build message for symptoms
  if (symptomsTrend.percentChange > 10) {
    message += "Wzrost o ${symptomsTrend.percentChange.toStringAsFixed(2)}% \n";
  } else if (symptomsTrend.percentChange < -10) {
    message += "Spadek o ${symptomsTrend.percentChange.abs().toStringAsFixed(2)}% \n";
  } else {
    message += "Stabilne \n";
  }
  
  message += "Trend objawów: ";
  if (symptomsTrend.direction == "upward") {
    message += "Wzrostowy \n\n";
  } else if (symptomsTrend.direction == "downward") {
    message += "Spadkowy \n\n";
  } else {
    message += "Stabilny \n\n";
  }
  
  // Build message for positive emotions
  message += "Emocje przyjemne: ";
  if (emoPlusTrend.percentChange > 10) {
    message += "Wzrost o ${emoPlusTrend.percentChange.toStringAsFixed(2)}% \n";
  } else if (emoPlusTrend.percentChange < -10) {
    message += "Spadek o ${emoPlusTrend.percentChange.abs().toStringAsFixed(2)}% \n";
  } else {
    message += "Stabilne \n";
  }
  
  message += "Trend emocji przyjemnych: ";
  if (emoPlusTrend.direction == "upward") {
    message += "Wzrostowy \n\n";
  } else if (emoPlusTrend.direction == "downward") {
    message += "Spadkowy \n\n";
  } else {
    message += "Stabilny \n\n";
  }
  
  // Build message for negative emotions
  message += "Emocje nieprzyjemne: ";
  if (emoMinusTrend.percentChange > 10) {
    message += "Wzrost o ${emoMinusTrend.percentChange.toStringAsFixed(2)}% \n";
  } else if (emoMinusTrend.percentChange < -10) {
    message += "Spadek o ${emoMinusTrend.percentChange.abs().toStringAsFixed(2)}% \n";
  } else {
    message += "Stabilne \n";
  }
  
  message += "Trend emocji nieprzyjemnych: ";
  if (emoMinusTrend.direction == "upward") {
    message += "Wzrostowy \n\n";
  } else if (emoMinusTrend.direction == "downward") {
    message += "Spadkowy \n\n";
  } else {
    message += "Stabilny \n\n";
  }

  return message;
}

List<String> performWarning(symptomsRaw, emoPlusRaw, emoMinusRaw, _daysRange) {
  List<String> alert = []; 
  
  // Get trend analysis for all types of data
  TrendAnalysis symptomsTrend = analyzeTrend(symptomsRaw, _daysRange);
  TrendAnalysis emoPlusTrend = analyzeTrend(emoPlusRaw, _daysRange);
  TrendAnalysis emoMinusTrend = analyzeTrend(emoMinusRaw, _daysRange);
  
  // Add warnings for significant upward trends
  if (symptomsTrend.percentChange > 15 && symptomsTrend.direction == "upward") {
     alert.add('symptoms'); 
  }
  
  if (emoMinusTrend.percentChange > 15 && emoMinusTrend.direction == "upward") {
    alert.add('emoMinus'); // Corrected - this was reversed in original code
  }
  
  if (emoPlusTrend.percentChange < -15 && emoPlusTrend.direction == "downward") {
    alert.add('emoPlus'); // Add alert if positive emotions are decreasing significantly
  }
  
  return alert;  
}


  ///TO DO: USER IT SOMEWHERE IN THE APP TO CREATE A WARNING