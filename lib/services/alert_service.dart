import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/alerting.dart';
import 'notification_service.dart';

/// Service to manage alerts - store, retrieve, and update alerts
class AlertService {
  /// Key for storing notification preferences
  static const String _notificationsEnabledKey = 'notifications_enabled';
  
  static const String _alertsKey = 'user_alerts';
  
  /// Current list of active alerts
  List<Alert> _currentAlerts = [];
  
  /// Stream controller to notify listeners of alerts changes
  final ValueNotifier<List<Alert>> alertsNotifier = ValueNotifier<List<Alert>>([]);
  
  /// Notification service to display alerts
  final NotificationService _notificationService = NotificationService();
  
  /// Singleton instance
  static final AlertService _instance = AlertService._internal();
  
  /// Factory constructor to return the singleton instance
  factory AlertService() {
    return _instance;
  }
  
  /// Private constructor for singleton
  AlertService._internal();
  
  /// Initialize the service and load saved alerts
  Future<void> initialize() async {
    // Initialize notification service
    await _notificationService.initialize(
      onNotificationTapped: (alertId) {
        // Handle when user taps on notification
        if (alertId != null) {
          debugPrint('Alert notification tapped: $alertId');
          // Could navigate to alerts page or specific alert detail
        }
      }
    );
    
    await _loadAlerts();
  }
  
  /// Get all current alerts
  List<Alert> get alerts => List.unmodifiable(_currentAlerts);
  
  /// Add a new alert and show notification
  Future<void> addAlert(Alert alert, {bool showNotification = true}) async {
    // Add only if not already present with same ID
    if (!_currentAlerts.any((a) => a.id == alert.id)) {
      _currentAlerts.add(alert);
      _sortAlertsByPriority();
      alertsNotifier.value = List.from(_currentAlerts);
      await _saveAlerts();
      
      // Show notification for the alert if requested
      if (showNotification) {
        // Schedule the notification to appear 1 hour from now
        await _notificationService.scheduleAlertNotification(
          alert, 
          delay: const Duration(hours: 1)
        );
      }
    }
  }
  
  /// Add multiple alerts at once
  Future<void> addAlerts(List<Alert> newAlerts, {bool showNotifications = true}) async {
    bool changed = false;
    final List<Alert> actuallyAddedAlerts = [];
    
    for (final alert in newAlerts) {
      if (!_currentAlerts.any((a) => a.id == alert.id)) {
        _currentAlerts.add(alert);
        actuallyAddedAlerts.add(alert);
        changed = true;
      }
    }
    
    if (changed) {
      _sortAlertsByPriority();
      alertsNotifier.value = List.from(_currentAlerts);
      await _saveAlerts();
      
      // Schedule notifications for new alerts if requested and notifications are enabled
      if (showNotifications && await areNotificationsEnabled()) {
        for (final alert in actuallyAddedAlerts) {
          // Only notify for high priority alerts (critical or warning)
          if (alert.severity != AlertSeverity.info) {
            await _notificationService.scheduleAlertNotification(
              alert, 
              delay: const Duration(hours: 1)
            );
          }
        }
      }
    }
  }
  
  /// Remove an alert by ID
  Future<void> removeAlert(String alertId) async {
    final alertIndex = _currentAlerts.indexWhere((alert) => alert.id == alertId);
    
    if (alertIndex >= 0) {
      final alertToRemove = _currentAlerts[alertIndex];
      _currentAlerts.removeAt(alertIndex);
      alertsNotifier.value = List.from(_currentAlerts);
      await _saveAlerts();
      
      // Also cancel any pending notification for this alert
      await _notificationService.cancelNotification(alertToRemove);
    }
  }
  
  /// Remove an alert
  Future<void> dismissAlert(Alert alert) async {
    await removeAlert(alert.id);
  }
  
  /// Clear all alerts
  Future<void> clearAllAlerts() async {
    _currentAlerts.clear();
    alertsNotifier.value = [];
    await _saveAlerts();
    
    // Also cancel all pending notifications
    await _notificationService.cancelAllNotifications();
  }
  
  /// Generate new alerts based on current data
  Future<List<Alert>> checkAndGenerateAlerts({
    required List<int> symptomsData,
    required List<int> posEmotionsData,
    required List<int> negEmotionsData,
    required DateTime lastActivityDate,
    required int daysRange,
    bool showNotifications = true,
  }) async {
    final newAlerts = Alerting.generateAlerts(
      symptomsData: symptomsData,
      posEmotionsData: posEmotionsData,
      negEmotionsData: negEmotionsData,
      lastActivityDate: lastActivityDate,
      daysRange: daysRange,
    );
    
    if (newAlerts.isNotEmpty) {
      await addAlerts(newAlerts, showNotifications: showNotifications);
    }
    
    return newAlerts;
  }
  
  /// Sort alerts with critical severity first, then by date (newest first)
  void _sortAlertsByPriority() {
    _currentAlerts.sort((a, b) {
      // First sort by severity (critical first)
      final severityComparison = b.severity.index.compareTo(a.severity.index);
      if (severityComparison != 0) {
        return severityComparison;
      }
      
      // Then sort by date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }
  
  /// Create a test notification alert (only for development/testing)
  Future<void> createTestAlert({Duration delay = const Duration(seconds: 10)}) async {
    final testAlert = Alert(
      id: "test_${DateTime.now().millisecondsSinceEpoch}",
      title: "Alert testowy",
      description: "To jest alert testowy stworzony do przetestowania systemu powiadomień.",
      severity: AlertSeverity.warning,
      type: AlertType.symptoms,
    );
    
    await addAlert(testAlert, showNotification: true);
  }
  
  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Default to true
  }
  
  /// Enable or disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    
    if (!enabled) {
      // Cancel any pending notifications if disabled
      await _notificationService.cancelAllNotifications();
    }
  }
  
  /// Save alerts to shared preferences
  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = _currentAlerts.map((alert) {
        return {
          'id': alert.id,
          'title': alert.title,
          'description': alert.description,
          'severity': alert.severity.index,
          'type': alert.type.index,
          'createdAt': alert.createdAt.millisecondsSinceEpoch,
        };
      }).toList();
      
      await prefs.setString(_alertsKey, jsonEncode(alertsJson));
    } catch (e) {
      debugPrint('Error saving alerts: $e');
    }
  }
  
  /// Load alerts from shared preferences
  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsString = prefs.getString(_alertsKey);
      
      if (alertsString != null) {
        final List<dynamic> alertsList = jsonDecode(alertsString);
        _currentAlerts = alertsList.map((alertJson) {
          return Alert(
            id: alertJson['id'],
            title: alertJson['title'],
            description: alertJson['description'],
            severity: AlertSeverity.values[alertJson['severity']],
            type: AlertType.values[alertJson['type']],
            createdAt: DateTime.fromMillisecondsSinceEpoch(alertJson['createdAt']),
          );
        }).toList();
        
        // Remove alerts older than 7 days
        final now = DateTime.now();
        _currentAlerts.removeWhere(
          (alert) => now.difference(alert.createdAt).inDays > 7
        );
        
        _sortAlertsByPriority();
        alertsNotifier.value = List.from(_currentAlerts);
        
        // Save alerts after filtering out old ones
        await _saveAlerts();
      }
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }
}
