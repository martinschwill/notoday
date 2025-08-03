import '../common_imports.dart';
import 'package:flutter/material.dart';
import 'dart:math'; 

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

final List <String> advise = [
  "Skorzystaj z Narzędzi, aby poprawić swoje postrzeganie rzeczywistości.",
  "Telefon do specjalisty lub trzeźwiejącego uzależnionego może być pomocne!",
  "Zastosuj techniki relaksacyjne, aby złagodzić stres.",
  "Skontaktuj się z terapeutą lub specjalistą zdrowia psychicznego.",
  "Skorzystaj ze swojej listy Narzędzi!",
  "Nie wahaj się prosić o pomoc, gdy jej potrzebujesz.",
  "Pamiętaj, że nie jesteś sam w tym, co przeżywasz.", 
  "Zastosuj techniki uważności, aby poprawić swoje samopoczucie.",
  "Regularne ćwiczenia fizyczne mogą pomóc w poprawie nastroju.",
  "Zjedzenie czegoś, co lubisz, może poprawić Twój nastrój.",
  "Pamiętaj, że zły nastrój jest jak fala - przychodzi i odchodzi. Skup się na tym, co możesz zrobić teraz.",
];

String getRandomAdvice() {
  final random = Random();
  return advise[random.nextInt(advise.length)];
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
      AlertSeverity severity;
      String title;
      String description;
      
      if (difference > 7) {
        severity = AlertSeverity.critical;
        title = "Długa nieaktywność";
        description = "Minęło $difference dni od ostatniej aktywności w aplikacji. Regularne monitorowanie objawów jest ważne.";
      } else if (difference > 3) {
        severity = AlertSeverity.warning;
        title = "Brak aktywności";
        description = "Minęły $difference dni od ostatniej aktywności. Pamiętaj o regularnym korzystaniu z aplikacji.";
      } else {
        severity = AlertSeverity.info;
        title = "Przypomnienie";
        description = "Minęły $difference dni od ostatniej aktywności. Warto regularnie monitorować swoje objawy i samopoczucie.";
      }
      
      return Alert(
        id: "inactivity_${DateTime.now().millisecondsSinceEpoch}",
        title: title,
        description: description,
        severity: severity,
        type: AlertType.inactivity,
        seen: false,
      );
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
        description: "Twoje objawy wzrosły o ${trend.percentChange.toStringAsFixed(1)}% w ciągu ostatnich $daysRange pomiarów. ${getRandomAdvice()}",
        trend: trend,
        type: AlertType.symptoms,
        onTap: () {
          NavigationService.navigateToToolkitGlobal();
        },
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
        description: "Twoje przyjemne emocje spadły o ${trend.percentChange.abs().toStringAsFixed(1)}% w ciągu ostatnich $daysRange pomiarów. ${getRandomAdvice()}" ,
        trend: trend,
        type: AlertType.positiveEmotions,
        onTap: () {
          NavigationService.navigateToToolkitGlobal();
        },
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
        description: "Twoje nieprzyjemne emocje wzrosły o ${trend.percentChange.toStringAsFixed(1)}% w ciągu ostatnich $daysRange pomiarów. ${getRandomAdvice()}",
        trend: trend,
        type: AlertType.negativeEmotions,
        onTap: () {
          NavigationService.navigateToToolkitGlobal();
        }
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
    
    // Count how many concerning trends we have
    int concerningTrendsCount = 0;
    if (symptomsIncreasing) concerningTrendsCount++;
    if (posEmotionsDecreasing) concerningTrendsCount++;
    if (negEmotionsIncreasing) concerningTrendsCount++;
    
    // Create alert if 2 or more conditions are met
    if (concerningTrendsCount >= 2) {
      String title;
      String description;
      AlertSeverity severity;
      
      if (concerningTrendsCount == 3) {
        // All three conditions met - ALWAYS CRITICAL
        title = "Zagrażający trend";
        description = "Wszystkie wskaźniki pokazują niepokojący trend - wzrost objawów i emocji nieprzyjemnych oraz spadek emocji przyjemnych. To bardzo niebezpieczny stan, który wymaga natychmiastowej uwagi. Skorzystaj z Narzędzi! Skontaktuj się z grupą, terapeutą lub swoim sponsorem!";
        severity = AlertSeverity.critical;
      } else {
        // Two conditions met - severity based on worst change
        title = "Niepokojący trend";
        description = "Kilka wskaźników pokazuje niepokojący trend. Warto zwrócić uwagę na swoje samopoczucie i myślenie. ${getRandomAdvice()}";
        
        // Determine severity based on the most concerning trend
        double worstChange = 0;
        worstChange = [
          symptomsTrend.percentChange,
          negEmotionsTrend.percentChange,
          posEmotionsTrend.percentChange.abs()
        ].reduce((max, value) => value > max ? value : max);
        
        if (worstChange > 2) {
          severity = AlertSeverity.critical;
        } else if (worstChange > 1) {
          severity = AlertSeverity.warning;
        } else {
          severity = AlertSeverity.info;
        }
      }
      
      return Alert(
        id: "combined_${DateTime.now().millisecondsSinceEpoch}",
        title: title,
        description: description,
        severity: severity,
        type: AlertType.combined,
        seen: false,
        onTap: () {
          NavigationService.navigateToToolkitGlobal();
        },
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


