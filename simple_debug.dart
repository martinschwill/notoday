// Simple debug script to analyze trend issue without Flutter dependencies
import 'dart:math';

// Define the TrendAnalysis class
class TrendAnalysis {
  final String direction;
  final double percentChange;
  
  TrendAnalysis(this.direction, this.percentChange);
  
  bool get isSignificant => percentChange.abs() > 10.0;
  
  @override
  String toString() => '$direction (${percentChange.toStringAsFixed(2)}%)';
}

// Copy of the analytics functions
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
  
  double alpha = 0.4;
  int initWindow = max(2, (recent.length * 0.3).round());
  
  // Initial EMA calculation
  double ema = recent.sublist(0, initWindow).fold(0.0, (sum, val) => sum + val) / initWindow;
  
  double startEma = ema;
  
  for (int i = initWindow; i < recent.length; i++) {
    ema = alpha * recent[i] + (1 - alpha) * ema;
  }
  
  double changePercent = ((ema - startEma) / startEma).abs() * 100;
  
  if (changePercent < 0.5) return "stable";
  
  return ema > startEma ? "upward" : "downward";
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
  
  if (direction == 'stable' && percentChange.abs() >= 0.1) {
    direction = percentChange > 0 ? 'upward' : 'downward';
  }
  if (percentChange == 0.0) {
    return TrendAnalysis('stable', 0.0);
  }
  return TrendAnalysis(direction, percentChange);
}

void main() {
  // Test case scenario: symptoms with -15.6% change but showing as upward with red arrow
  
  // Create test data that would produce approximately -15.6% change
  List<int> testSymptomsData = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, // First 10 days: average = 5
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, // Next 10 days: average = 5  
    4, 4, 4, 4, 4, 4, 4, 3, 3, 3  // Last 10 days: should be lower to get -15.6%
  ];
  
  print('=== DEBUGGING TREND ISSUE ===');
  print('Test data length: ${testSymptomsData.length}');
  print('Test data: $testSymptomsData');
  
  int daysRange = 30;
  print('\nTesting with daysRange: $daysRange');
  
  // Analyze the trend
  TrendAnalysis trend = analyzeTrend(testSymptomsData, daysRange);
  print('Trend direction: ${trend.direction}');
  print('Percent change: ${trend.percentChange}%');
  print('Is significant: ${trend.isSignificant}');
  
  // Debug the individual functions
  print('\n=== DETAILED DEBUG ===');
  String direction = symptomTrend(testSymptomsData, daysRange);
  print('Direction from symptomTrend(): $direction');
  
  double percentChange = calculateRelativeChange(testSymptomsData, 3, daysRange);
  print('Percent change from calculateRelativeChange(): $percentChange%');
  
  // Test manual calculation
  double recentAvg = averageOfSymptoms(testSymptomsData, 3);
  double overallAvg = averageOfSymptoms(testSymptomsData, daysRange);
  print('Recent average (3 days): $recentAvg');
  print('Overall average ($daysRange days): $overallAvg');
  print('Manual percent change: ${((recentAvg / overallAvg) - 1) * 100}%');
  
  // Check what would trigger a symptoms alert
  const double moderateTrendChange = 1.0; // From alerting.dart
  print('\nAlert logic:');
  print('Moderate trend change threshold: $moderateTrendChange');
  print('Should alert trigger? Direction upward: ${direction == "upward"}, Change > threshold: ${percentChange > moderateTrendChange}');
  
  // Test with data that would produce -15.6% change
  print('\n=== CREATING EXACT -15.6% SCENARIO ===');
  List<int> exactTestData = [];
  // Add 27 days of value 5
  for (int i = 0; i < 27; i++) {
    exactTestData.add(5);
  }
  // Add 3 days that would create -15.6% change
  // Recent average needs to be 5 * (1 - 0.156) = 4.22
  exactTestData.addAll([4, 4, 5]); // Average = 4.33, which is about -13.4%
  
  // Try with values that would be closer to -15.6%
  exactTestData = [];
  for (int i = 0; i < 27; i++) {
    exactTestData.add(5);
  }
  exactTestData.addAll([4, 4, 4]); // Average = 4, which is -20%
  
  print('Exact test data: $exactTestData');
  TrendAnalysis exactTrend = analyzeTrend(exactTestData, 30);
  print('Exact trend direction: ${exactTrend.direction}');
  print('Exact percent change: ${exactTrend.percentChange}%');
  
  double exactRecentAvg = averageOfSymptoms(exactTestData, 3);
  double exactOverallAvg = averageOfSymptoms(exactTestData, 30);
  print('Exact recent average (3 days): $exactRecentAvg');
  print('Exact overall average (30 days): $exactOverallAvg');
  print('Exact manual percent change: ${((exactRecentAvg / exactOverallAvg) - 1) * 100}%');
}
