// Debug the exact analyzeTrend logic
import 'dart:math';

class TrendAnalysis {
  final String direction;
  final double percentChange;
  
  TrendAnalysis(this.direction, this.percentChange);
  
  @override
  String toString() => '$direction (${percentChange.toStringAsFixed(2)}%)';
}

double averageOfSymptoms(List<int> dailySymptoms, int days) {
  if (dailySymptoms.isEmpty) return 0;
  
  final recent = dailySymptoms.length > days 
      ? dailySymptoms.sublist(dailySymptoms.length - days)
      : dailySymptoms;
  
  if (recent.isEmpty) return 0;
  final sum = recent.reduce((a, b) => a + b);
  return sum / recent.length;
}

double _calculateEMA(List<int> data, double alpha) {
  if (data.isEmpty) return 0;
  if (data.length == 1) return data[0].toDouble();
  
  int initWindow = (data.length * 0.2).ceil().clamp(1, 3);
  double ema = data.take(initWindow).fold(0.0, (sum, val) => sum + val) / initWindow;
  
  for (int i = initWindow; i < data.length; i++) {
    ema = alpha * data[i] + (1 - alpha) * ema;
  }
  
  return ema;
}

String symptomTrend(List<int> dailySymptoms, int days) {
  final recent = dailySymptoms.length > days 
      ? dailySymptoms.sublist(dailySymptoms.length - days)
      : dailySymptoms;
  
  if (recent.length < 4) return "stable";
  
  double alpha = 0.4;
  
  int shortTermLength = days > 14 ? 7 : (days ~/ 2);
  if (shortTermLength < 3) shortTermLength = 3;
  List<int> shortTermData = recent.length > shortTermLength 
      ? recent.sublist(recent.length - shortTermLength)
      : recent;
  
  List<int> longTermData = recent;

  double shortTermEMA = _calculateEMA(shortTermData, alpha);
  double longTermEMA = _calculateEMA(longTermData, alpha);
  
  print('Short-term EMA: $shortTermEMA');
  print('Long-term EMA: $longTermEMA');
  
  if (longTermEMA == 0) return "stable";
  
  double relativeChange = (shortTermEMA - longTermEMA) / longTermEMA;
  print('EMA relative change: $relativeChange');
  
  if (relativeChange > 0.006) return "upward";
  if (relativeChange < -0.006) return "downward";
  return "stable";
}

double calculateRelativeChange(List<int> values, int recentDays, int totalDays) {
  if (values.isEmpty) return 0.0;
  
  double recentAvg = averageOfSymptoms(values, recentDays);
  double overallAvg = averageOfSymptoms(values, totalDays);
  
  if (overallAvg == 0) {
    return recentAvg > 0 ? 100.0 : 0.0;
  }
  
  return ((recentAvg / overallAvg) - 1) * 100;
}

TrendAnalysis analyzeTrend(List<int> values, int daysRange) {
  if (values.isEmpty) {
    return TrendAnalysis('stable', 0.0);
  }
  
  // Get trend direction (upward, downward, stable)
  String direction = symptomTrend(values, daysRange);
  print('Initial direction from symptomTrend: $direction');
  
  // Calculate percentage change
  double percentChange = calculateRelativeChange(values, 3, daysRange);
  print('Percent change from calculateRelativeChange: $percentChange');
  
  print('Before override - direction: $direction, percentChange: $percentChange');
  
  if (direction == 'stable' && percentChange.abs() >= 0.1) {
    String newDirection = percentChange > 0 ? 'upward' : 'downward';
    print('Overriding direction from $direction to $newDirection');
    direction = newDirection;
  }
  
  if (percentChange == 0.0) {
    return TrendAnalysis('stable', 0.0);
  }
  return TrendAnalysis(direction, percentChange);
}

void main() {
  // Test with data that should show downward trend but might show upward
  List<int> problemData = [];
  
  // 27 days of value 5
  for (int i = 0; i < 27; i++) {
    problemData.add(5);
  }
  // Last 3 days: lower values to create downward trend
  problemData.addAll([4, 4, 4]); // Should be -18.4% change
  
  print('=== DEBUGGING ANALYZE TREND ===');
  print('Test data: $problemData');
  print('Data length: ${problemData.length}');
  
  TrendAnalysis result = analyzeTrend(problemData, 30);
  print('\nFinal result: $result');
  
  // Test with data that might trigger the EMA "stable" issue
  List<int> emaStableData = [];
  // Create data that EMA might see as stable but simple average sees as declining
  for (int i = 0; i < 25; i++) {
    emaStableData.add(5);
  }
  // Add gradual decline that might not trigger EMA threshold
  emaStableData.addAll([5, 4, 4, 4, 4]); // Last 5 days slightly lower
  
  print('\n=== TESTING EMA STABLE CASE ===');
  print('EMA test data: $emaStableData');
  TrendAnalysis emaResult = analyzeTrend(emaStableData, 30);
  print('EMA test result: $emaResult');
}
