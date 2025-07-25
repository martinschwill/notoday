import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/analytics.dart';
import '../modules/alerting.dart';
import '../services/alert_service.dart';

/// Class to track user activity and run alert checks
class UserMetricsService {
  static const String _lastActivityKey = 'last_activity_date';
  static const String _symptomsDataKey = 'symptoms_data';
  static const String _posEmotionsDataKey = 'pos_emotions_data';
  static const String _negEmotionsDataKey = 'neg_emotions_data';
  
  /// Singleton instance
  static final UserMetricsService _instance = UserMetricsService._internal();
  
  /// Factory constructor to return the singleton instance
  factory UserMetricsService() {
    return _instance;
  }
  
  /// Private constructor for singleton
  UserMetricsService._internal();
  
  /// Record user activity and update the last activity date
  Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_lastActivityKey, now.toIso8601String());
  }
  
  /// Get the date of the last user activity
  Future<DateTime> getLastActivityDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityString = prefs.getString(_lastActivityKey);
    
    if (lastActivityString != null) {
      return DateTime.parse(lastActivityString);
    } else {
      // If no activity recorded yet, use the current date
      final now = DateTime.now();
      await prefs.setString(_lastActivityKey, now.toIso8601String());
      return now;
    }
  }
  
  /// Save symptoms data
  Future<void> saveSymptoms(List<int> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_symptomsDataKey, jsonEncode(data));
    await recordActivity();
    // await runAlertChecks();
  }
  
  /// Save positive emotions data
  Future<void> savePosEmotions(List<int> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_posEmotionsDataKey, jsonEncode(data));
    await recordActivity();
    // await runAlertChecks();
  }
  
  /// Save negative emotions data
  Future<void> saveNegEmotions(List<int> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_negEmotionsDataKey, jsonEncode(data));
    await recordActivity();
    // await runAlertChecks();
  }
  
  /// Get symptoms data
  Future<List<int>> getSymptoms() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_symptomsDataKey);
    
    if (dataString != null) {
      final List<dynamic> jsonList = jsonDecode(dataString);
      return jsonList.cast<int>();
    } else {
      return [];
    }
  }
  
  /// Get positive emotions data
  Future<List<int>> getPosEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_posEmotionsDataKey);
    
    if (dataString != null) {
      final List<dynamic> jsonList = jsonDecode(dataString);
      return jsonList.cast<int>();
    } else {
      return [];
    }
  }
  
  /// Get negative emotions data
  Future<List<int>> getNegEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_negEmotionsDataKey);
    
    if (dataString != null) {
      final List<dynamic> jsonList = jsonDecode(dataString);
      return jsonList.cast<int>();
    } else {
      return [];
    }
  }
  
  /// Run checks for alerts based on all available data
  Future<List<Alert>> runAlertChecks({bool showNotifications = true}) async {
    try {
      debugPrint('Running alert checks with showNotifications=$showNotifications');
      
      final symptomsData = await getSymptoms();
      final posEmotionsData = await getPosEmotions();
      final negEmotionsData = await getNegEmotions();
      final lastActivityDate = await getLastActivityDate();
      
      debugPrint('Data retrieved: ' +
          'symptoms=${symptomsData.length}, ' +
          'posEmotions=${posEmotionsData.length}, ' +
          'negEmotions=${negEmotionsData.length}');
      
      // Default to 30 days or available data length
      int daysRange = 30;
      if (symptomsData.isNotEmpty && symptomsData.length < daysRange) {
        daysRange = symptomsData.length;
      }
      
      if (daysRange < 7 && (symptomsData.isEmpty || posEmotionsData.isEmpty || negEmotionsData.isEmpty)) {
        debugPrint('Not enough data for trend analysis. Need at least 7 days of data.');
        
        return [];
      }
      
      // Use the alert service to generate alerts
      // Add a small delay to avoid running multiple checks at virtually the same time
      await Future.delayed(const Duration(milliseconds: 500));
      
      final alertService = AlertService();
      final newAlerts = await alertService.checkAndGenerateAlerts(
        symptomsData: symptomsData,
        posEmotionsData: posEmotionsData,
        negEmotionsData: negEmotionsData,
        lastActivityDate: lastActivityDate,
        daysRange: daysRange,
        showNotifications: showNotifications,
      );
      
      debugPrint('Generated ${newAlerts.length} alerts from metrics data');
      return newAlerts;
    } catch (e) {
      debugPrint('Error running alert checks: $e');
      return [];
    }
  }
}
