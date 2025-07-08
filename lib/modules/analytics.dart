
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
  final recent = dailySymptoms.reversed.take(days).toList(); 
  if (recent.isEmpty) return 0;
  final sum = recent.reduce((a, b) => a + b);
  return sum / recent.length;
}


/// Returns "upward", "downward", or "stable" trend for the last [days] of symptom counts.
/// Uses an exponential moving average approach that gives more weight to recent data
/// and is less sensitive to outliers.
String symptomTrend(List<int> dailySymptoms, int days) {
  final recent = dailySymptoms.take(days).toList();
  if (recent.length < 4) return "stable"; // Need at least 4 data points
  
  // Calculate exponential moving averages
  double alpha = 0.4; // Smoothing factor (higher value = more weight to recent observations)
  
  // Calculate short-term EMA (last week or min 7 values)
  int shortTermLength = days > 14 ? 7 : (days ~/ 2);
  if (shortTermLength < 3) shortTermLength = 3;
  List<int> shortTermData = recent.length > shortTermLength 
      ? recent.sublist(recent.length - shortTermLength)
      : recent;
  
  // Calculate long-term EMA (all available data)
  List<int> longTermData = recent;

  double shortTermEMA = _calculateEMA(shortTermData, alpha);
  double longTermEMA = _calculateEMA(longTermData, alpha);
  
  // Check if there's a significant trend between short and long term averages
  if (longTermEMA == 0) return "stable"; // Avoid division by zero
  
  double relativeChange = (shortTermEMA - longTermEMA) / longTermEMA;
  
  // Use more sensitive thresholds for better trend detection
  if (relativeChange > 0.006) return "upward";
  if (relativeChange < -0.006) return "downward";
  return "stable";
}

/// Calculate Exponential Moving Average with given smoothing factor alpha
double _calculateEMA(List<int> data, double alpha) {
  if (data.isEmpty) return 0;
  
  // Start with simple average for first value
  double ema = data[0].toDouble();
  
  // Calculate EMA for remaining values
  for (int i = 1; i < data.length; i++) {
    ema = alpha * data[i] + (1 - alpha) * ema;
  }
  
  return ema;
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
  
  // Get trend direction (upward, downward, stable)
  String direction = symptomTrend(values, daysRange);
  
  // Calculate percentage change
  double percentChange = calculateRelativeChange(values, 3, daysRange);
  
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