// Test the fixed analyzeTrend logic
class TrendAnalysis {
  final String direction;
  final double percentChange;
  
  TrendAnalysis(this.direction, this.percentChange);
  
  bool get isSignificant => percentChange.abs() > 10.0;
  
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

String symptomTrend(List<int> dailySymptoms, int days) {
  final recent = dailySymptoms.length > days 
      ? dailySymptoms.sublist(dailySymptoms.length - days)
      : dailySymptoms;
  
  if (recent.length < 4) return "stable";
  
  int recentDays = recent.length >= 7 ? 3 : 2;
  
  double recentAvg = averageOfSymptoms(recent, recentDays);
  double overallAvg = averageOfSymptoms(recent, recent.length);
  
  print('Recent avg ($recentDays days): $recentAvg');
  print('Overall avg (${recent.length} days): $overallAvg');
  
  if (overallAvg == 0) return "stable";
  
  double relativeChange = (recentAvg - overallAvg) / overallAvg;
  print('Symptom trend relative change: $relativeChange');
  
  if (relativeChange > 0.01) return "upward";
  if (relativeChange < -0.01) return "downward";
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
  
  String direction = symptomTrend(values, daysRange);
  print('Initial direction from symptomTrend: $direction');
  
  double percentChange = calculateRelativeChange(values, 3, daysRange);
  print('Percent change from calculateRelativeChange: $percentChange');
  
  if (direction == 'stable' && percentChange.abs() >= 1.0) {
    String newDirection = percentChange > 0 ? 'upward' : 'downward';
    print('Overriding direction from $direction to $newDirection (percentChange >= 1.0)');
    direction = newDirection;
  }
  
  if (direction == 'upward' && percentChange < 0) {
    print('Fixing inconsistency: direction was upward but percentChange is negative');
    direction = 'downward';
  } else if (direction == 'downward' && percentChange > 0) {
    print('Fixing inconsistency: direction was downward but percentChange is positive');
    direction = 'upward';
  }
  
  if (percentChange == 0.0) {
    return TrendAnalysis('stable', 0.0);
  }
  
  return TrendAnalysis(direction, percentChange);
}

void main() {
  // Test with data that should show clear downward trend
  List<int> testData = [];
  
  // 27 days of value 5
  for (int i = 0; i < 27; i++) {
    testData.add(5);
  }
  // Last 3 days: lower values to create downward trend
  testData.addAll([4, 4, 4]); // Should be -18.4% change
  
  print('=== TESTING FIXED ANALYZE TREND ===');
  print('Test data: $testData');
  print('Data length: ${testData.length}');
  
  TrendAnalysis result = analyzeTrend(testData, 30);
  print('\nFinal result: $result');
  
  // Test edge case where symptomTrend might not detect the trend
  List<int> edgeCase = [];
  for (int i = 0; i < 28; i++) {
    edgeCase.add(5);
  }
  edgeCase.addAll([4, 4]); // Smaller change, last 2 days
  
  print('\n=== TESTING EDGE CASE ===');
  print('Edge case data: $edgeCase');
  TrendAnalysis edgeResult = analyzeTrend(edgeCase, 30);
  print('Edge case result: $edgeResult');
}
