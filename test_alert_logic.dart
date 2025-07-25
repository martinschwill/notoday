// Test alert generation with fixed trend analysis
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
  
  if (overallAvg == 0) return "stable";
  
  double relativeChange = (recentAvg - overallAvg) / overallAvg;
  
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
  double percentChange = calculateRelativeChange(values, 3, daysRange);
  
  if (direction == 'stable' && percentChange.abs() >= 1.0) {
    direction = percentChange > 0 ? 'upward' : 'downward';
  }
  
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

// Simulate alert check for symptoms
bool checkSymptomsAlert(List<int> symptomsData, int daysRange) {
  final trend = analyzeTrend(symptomsData, daysRange);
  const double moderateTrendChange = 1.0;
  
  // Alert on significant upward trend in symptoms (bad)
  bool shouldAlert = trend.direction == "upward" && trend.percentChange > moderateTrendChange;
  
  print('Symptoms trend: $trend');
  print('Should generate alert? $shouldAlert');
  print('Reason: direction=${trend.direction}, percentChange=${trend.percentChange}, threshold=$moderateTrendChange');
  
  return shouldAlert;
}

void main() {
  print('=== TESTING ALERT GENERATION ===');
  
  // Test 1: Downward trend (should NOT generate alert)
  List<int> downwardData = [];
  for (int i = 0; i < 27; i++) {
    downwardData.add(5);
  }
  downwardData.addAll([4, 4, 4]);
  
  print('\n--- Test 1: Downward trend ---');
  print('Data: $downwardData');
  checkSymptomsAlert(downwardData, 30);
  
  // Test 2: Upward trend (should generate alert)
  List<int> upwardData = [];
  for (int i = 0; i < 27; i++) {
    upwardData.add(3);
  }
  upwardData.addAll([4, 5, 5]); // Increasing symptoms
  
  print('\n--- Test 2: Upward trend ---');
  print('Data: $upwardData');
  checkSymptomsAlert(upwardData, 30);
  
  // Test 3: Small upward trend (should generate alert if > 1%)
  List<int> smallUpData = [];
  for (int i = 0; i < 27; i++) {
    smallUpData.add(4);
  }
  smallUpData.addAll([4, 4, 5]); // Small increase
  
  print('\n--- Test 3: Small upward trend ---');
  print('Data: $smallUpData');
  checkSymptomsAlert(smallUpData, 30);
}
