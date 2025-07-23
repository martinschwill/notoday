import '../common_imports.dart';
import 'package:flutter/material.dart';

/// Enum representing alert severity levels
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// Enum representing alert types
enum AlertType {
  metrics,
  inactivity,
  symptoms,
  positiveEmotions,
  negativeEmotions,
  combined,
}

/// Alert model class
class Alert {
  /// Unique identifier for the alert
  final String id;
  
  /// Title of the alert
  final String title;
  
  /// Description of the alert
  final String description;
  
  /// Severity level of the alert
  final AlertSeverity severity;
  
  /// Type of alert
  final AlertType type;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Optional action to take when alert is tapped
  final VoidCallback? onTap;
  
  /// Has this alert been seen by the user
  final bool seen;
  
  /// Constructor
  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    DateTime? createdAt,
    this.onTap,
    this.seen = false,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Factory method to create an alert from a TrendAnalysis
  factory Alert.fromTrend({
    required String title,
    required String description,
    required TrendAnalysis trend,
    required AlertType type,
    VoidCallback? onTap,
  }) {
    AlertSeverity severity;
    
    if (trend.percentChange.abs() > 2) {
      severity = AlertSeverity.critical;
    } else if (trend.percentChange.abs() > 1) {
      severity = AlertSeverity.warning;
    } else {
      severity = AlertSeverity.info;
    }
    
    return Alert(
      id: "${type.name}_${DateTime.now().millisecondsSinceEpoch}",
      title: title,
      description: description,
      severity: severity,
      type: type,
      onTap: onTap,
      seen: false,
    );
  }
  
  /// Factory method to create an inactivity alert
  factory Alert.inactivity({
    required int daysSinceLastActivity,
    VoidCallback? onTap,
  }) {
    AlertSeverity severity;
    String title;
    String description;
    
    if (daysSinceLastActivity > 7) {
      severity = AlertSeverity.critical;
      title = "Długa nieaktywność";
      description = "Minęło $daysSinceLastActivity dni od ostatniej aktywności w aplikacji. Regularne monitorowanie objawów jest ważne.";
    } else if (daysSinceLastActivity > 3) {
      severity = AlertSeverity.warning;
      title = "Brak aktywności";
      description = "Minęły $daysSinceLastActivity dni od ostatniej aktywności. Pamiętaj o regularnym korzystaniu z aplikacji.";
    } else {
      severity = AlertSeverity.info;
      title = "Przypomnienie";
      description = "Minęły $daysSinceLastActivity dni od ostatniej aktywności. Warto regularnie monitorować swoje objawy i samopoczucie.";
    }
    
    return Alert(
      id: "inactivity_${DateTime.now().millisecondsSinceEpoch}",
      title: title,
      description: description,
      severity: severity,
      type: AlertType.inactivity,
      onTap: onTap,
      seen: false,
    );
  }
  
  /// Factory method for a combined alert when multiple metrics show concerning trends
  factory Alert.combinedMetrics({
    required TrendAnalysis symptomsTrend,
    required TrendAnalysis posEmotionsTrend,
    required TrendAnalysis negEmotionsTrend,
    VoidCallback? onTap,
  }) {
    const title = "Niepokojący trend";
    const description = "Wszystkie wskaźniki pokazują niepokojący trend - wzrost objawów i emocji nieprzyjemnych oraz spadek emocji przyjemnych.";
    
    // Determine worst severity based on the most concerning trend
    double worstChange = 0;
    worstChange = [
      symptomsTrend.percentChange,
      negEmotionsTrend.percentChange,
      posEmotionsTrend.percentChange.abs()
    ].reduce((max, value) => value > max ? value : max);
    
    AlertSeverity severity;
    if (worstChange > 2) {
      severity = AlertSeverity.critical;
    } else if (worstChange > 1) {
      severity = AlertSeverity.warning;
    } else {
      severity = AlertSeverity.info;
    }
    
    return Alert(
      id: "combined_${DateTime.now().millisecondsSinceEpoch}",
      title: title,
      description: description,
      severity: severity,
      type: AlertType.combined,
      onTap: onTap,
      seen: false,
    );
  }
}

class Alerting {
  /// Thresholds for basic checks
  static const double highSymptomThreshold = 3.0;
  static const double highNegEmotionThreshold = 3.0;
  static const double lowPosEmotionThreshold = 1.0;
  
  /// Days without activity that trigger alerts
  static const int moderateInactivityDays = 3;
  static const int severeInactivityDays = 7;
  
  /// Trend percentage changes that trigger alerts
  static const double moderateTrendChange = 1.0;
  static const double severeTrendChange = 5.0;
  
  /// Checks if the given value is above the threshold
  static bool isAboveThreshold(double value, double threshold) {
    return value > threshold;
  }

  /// Checks if the given value is below the threshold
  static bool isBelowThreshold(double value, double threshold) {
    return value < threshold;
  }

  /// Checks if the given value is within the acceptable range
  static bool isWithinRange(double value, double min, double max) {
    return value >= min && value <= max;
  }
  
  /// Check if the user has been inactive for too long
  static Alert? checkUserInactivity(DateTime lastActivityDate) {
    final now = DateTime.now();
    final difference = now.difference(lastActivityDate).inDays;
    
    if (difference >= moderateInactivityDays) {
      return Alert.inactivity(daysSinceLastActivity: difference);
    }
    
    return null;
  }
  
  /// Check for concerning symptom trends
  static Alert? checkSymptomsTrend(List<int> symptomsData, int daysRange) {
    final trend = analyzeTrend(symptomsData, daysRange);
    
    // Alert on significant upward trend in symptoms (bad)
    if (trend.direction == "upward" && trend.percentChange > moderateTrendChange) {
      return Alert.fromTrend(
        title: "Wzrost objawów",
        description: "Twoje objawy wzrosły o ${trend.percentChange.toStringAsFixed(1)}% w ciągu ostatnich $daysRange pomiarów.",
        trend: trend,
        type: AlertType.symptoms,
      );
    }
    
    return null;
  }
  
  /// Check for concerning positive emotions trends
  static Alert? checkPositiveEmotionsTrend(List<int> posEmotionsData, int daysRange) {
    final trend = analyzeTrend(posEmotionsData, daysRange);
    
    // Alert on significant downward trend in positive emotions (bad)
    if (trend.direction == "downward" && trend.percentChange < -moderateTrendChange) {
      return Alert.fromTrend(
        title: "Spadek przyjemnych emocji",
        description: "Twoje przyjemne emocje spadły o ${trend.percentChange.abs().toStringAsFixed(1)}% w ciągu ostatnich $daysRange pomiarów.",
        trend: trend,
        type: AlertType.positiveEmotions,
      );
    }
    
    return null;
  }
  
  /// Check for concerning negative emotions trends
  static Alert? checkNegativeEmotionsTrend(List<int> negEmotionsData, int daysRange) {
    final trend = analyzeTrend(negEmotionsData, daysRange);
    
    // Alert on significant upward trend in negative emotions (bad)
    if (trend.direction == "upward" && trend.percentChange > moderateTrendChange) {
      return Alert.fromTrend(
        title: "Wzrost nieprzyjemnych emocji",
        description: "Twoje nieprzyjemne emocje wzrosły o ${trend.percentChange.toStringAsFixed(1)}% w ciągu ostatnich $daysRange pomiarów.",
        trend: trend,
        type: AlertType.negativeEmotions,
      );
    }
    
    return null;
  }
  
  /// Check for combined negative trends across all metrics
  static Alert? checkCombinedTrends(
    List<int> symptomsData, 
    List<int> posEmotionsData, 
    List<int> negEmotionsData, 
    int daysRange
  ) {
    final symptomsTrend = analyzeTrend(symptomsData, daysRange);
    final posEmotionsTrend = analyzeTrend(posEmotionsData, daysRange);
    final negEmotionsTrend = analyzeTrend(negEmotionsData, daysRange);
    
    // Check if ALL three trends are concerning:
    // 1. Symptoms going up (bad)
    // 2. Positive emotions going down (bad) 
    // 3. Negative emotions going up (bad)
    bool symptomsIncreasing = symptomsTrend.direction == "upward" && symptomsTrend.percentChange > moderateTrendChange;
    bool posEmotionsDecreasing = posEmotionsTrend.direction == "downward" && posEmotionsTrend.percentChange < -moderateTrendChange;
    bool negEmotionsIncreasing = negEmotionsTrend.direction == "upward" && negEmotionsTrend.percentChange > moderateTrendChange;
    
    // Only create combined alert when ALL three conditions are met
    bool allTrendsConcerning = symptomsIncreasing && posEmotionsDecreasing && negEmotionsIncreasing;
    
    if (allTrendsConcerning) {
      return Alert.combinedMetrics(
        symptomsTrend: symptomsTrend,
        posEmotionsTrend: posEmotionsTrend,
        negEmotionsTrend: negEmotionsTrend,
      );
    }
    
    return null;
  }
  
  /// Generate all applicable alerts for the current user state
  static List<Alert> generateAlerts({
    required List<int> symptomsData,
    required List<int> posEmotionsData,
    required List<int> negEmotionsData,
    required DateTime lastActivityDate,
    required int daysRange,
  }) {
    debugPrint('Generating alerts with data lengths: ' +
        'symptoms=${symptomsData.length}, ' +
        'posEmotions=${posEmotionsData.length}, ' +
        'negEmotions=${negEmotionsData.length}, ' +
        'daysRange=$daysRange');
    
    // Generate a unique ID suffix to avoid duplicates within the same run
    final uniqueIdSuffix = "_${DateTime.now().millisecondsSinceEpoch}";
        
    List<Alert> alerts = [];
    
    // Check individual trend alerts
    final symptomsAlert = checkSymptomsTrend(symptomsData, daysRange);
    if (symptomsAlert != null) {
      // Add unique suffix to ID to prevent duplicates
      final uniqueAlert = Alert(
        id: "${symptomsAlert.id}$uniqueIdSuffix",
        title: symptomsAlert.title,
        description: symptomsAlert.description,
        severity: symptomsAlert.severity,
        type: symptomsAlert.type,
        createdAt: symptomsAlert.createdAt,
        onTap: symptomsAlert.onTap,
        seen: false,
      );
      debugPrint('Generated symptoms alert with severity: ${uniqueAlert.severity}');
      alerts.add(uniqueAlert);
    }
    
    final posEmotionsAlert = checkPositiveEmotionsTrend(posEmotionsData, daysRange);
    if (posEmotionsAlert != null) {
      // Add unique suffix to ID to prevent duplicates
      final uniqueAlert = Alert(
        id: "${posEmotionsAlert.id}$uniqueIdSuffix",
        title: posEmotionsAlert.title,
        description: posEmotionsAlert.description,
        severity: posEmotionsAlert.severity,
        type: posEmotionsAlert.type,
        createdAt: posEmotionsAlert.createdAt,
        onTap: posEmotionsAlert.onTap,
        seen: false,
      );
      debugPrint('Generated positive emotions alert with severity: ${uniqueAlert.severity}');
      alerts.add(uniqueAlert);
    }
    
    final negEmotionsAlert = checkNegativeEmotionsTrend(negEmotionsData, daysRange);
    if (negEmotionsAlert != null) {
      // Add unique suffix to ID to prevent duplicates
      final uniqueAlert = Alert(
        id: "${negEmotionsAlert.id}$uniqueIdSuffix",
        title: negEmotionsAlert.title,
        description: negEmotionsAlert.description,
        severity: negEmotionsAlert.severity,
        type: negEmotionsAlert.type,
        createdAt: negEmotionsAlert.createdAt,
        onTap: negEmotionsAlert.onTap,
        seen: false,
      );
      debugPrint('Generated negative emotions alert with severity: ${uniqueAlert.severity}');
      alerts.add(uniqueAlert);
    }
    
    // Check combined trends alert - this is highest priority
    final combinedAlert = checkCombinedTrends(
      symptomsData, 
      posEmotionsData, 
      negEmotionsData, 
      daysRange
    );
    if (combinedAlert != null) {
      // Add unique suffix to ID to prevent duplicates
      final uniqueAlert = Alert(
        id: "${combinedAlert.id}$uniqueIdSuffix",
        title: combinedAlert.title,
        description: combinedAlert.description,
        severity: combinedAlert.severity,
        type: combinedAlert.type,
        createdAt: combinedAlert.createdAt,
        onTap: combinedAlert.onTap,
        seen: false,
      );
      debugPrint('Generated combined alert with severity: ${uniqueAlert.severity}');
      alerts.add(uniqueAlert);
    }
    
    // Check inactivity alert
    final inactivityAlert = checkUserInactivity(lastActivityDate);
    if (inactivityAlert != null) {
      // Add unique suffix to ID to prevent duplicates
      final uniqueAlert = Alert(
        id: "${inactivityAlert.id}$uniqueIdSuffix",
        title: inactivityAlert.title,
        description: inactivityAlert.description,
        severity: inactivityAlert.severity,
        type: inactivityAlert.type,
        createdAt: inactivityAlert.createdAt,
        onTap: inactivityAlert.onTap,
        seen: false,
      );
      debugPrint('Generated inactivity alert with severity: ${uniqueAlert.severity}');
      alerts.add(uniqueAlert);
    }
    
    // Sort alerts by severity (critical first)
    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    
    debugPrint('Total alerts generated: ${alerts.length}');
    return alerts;
  }
}


