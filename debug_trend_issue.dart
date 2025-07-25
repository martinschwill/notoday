import 'lib/modules/analytics.dart';
import 'lib/modules/alerting.dart';

void main() {
  // Test case scenario: symptoms with -15.6% change that should trigger alert
  
  // Example data that could produce -15.6% change
  // Recent data lower than overall average by 15.6%
  List<int> testSymptomsData = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, // First 10 days: average = 5
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, // Next 10 days: average = 5  
    4, 4, 4, 4, 4, 4, 4            // Last 7 days: average = 4 (20% lower)
  ];
  
  print('=== DEBUGGING TREND ISSUE ===');
  print('Test data length: ${testSymptomsData.length}');
  print('Test data: $testSymptomsData');
  
  // Test with 30 days range
  int daysRange = 30;
  print('\nTesting with daysRange: $daysRange');
  
  // Analyze the trend
  TrendAnalysis trend = analyzeTrend(testSymptomsData, daysRange);
  print('Trend direction: ${trend.direction}');
  print('Percent change: ${trend.percentChange}%');
  print('Is significant: ${trend.isSignificant}');
  
  // Test alert generation
  Alert? alert = Alerting.checkSymptomsTrend(testSymptomsData, daysRange);
  if (alert != null) {
    print('\nAlert generated:');
    print('Title: ${alert.title}');
    print('Description: ${alert.description}');
    print('Severity: ${alert.severity}');
  } else {
    print('\nNo alert generated');
  }
  
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
  
  // Check alert threshold
  print('Moderate trend change threshold: ${Alerting.moderateTrendChange}');
  print('Should alert trigger? Direction upward: ${direction == "upward"}, Change > threshold: ${percentChange > Alerting.moderateTrendChange}');
}
