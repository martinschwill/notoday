import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/alerting.dart';
import 'notification_service.dart';

/// Simple service to manage alerts and notifications
class AlertService {
  static const String _alertsKey = 'user_alerts';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  
  List<Alert> _alerts = [];
  final ValueNotifier<List<Alert>> alertsNotifier = ValueNotifier<List<Alert>>([]);
  final NotificationService _notificationService = NotificationService();
  
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();
  
  List<Alert> get alerts => List.unmodifiable(_alerts);
  
  /// Initialize the service
  Future<void> initialize() async {
    await _notificationService.initialize(
      onNotificationTapped: (alertId) async {
        debugPrint('Notification tapped: $alertId');
        await markAlertsAsSeen();
      }
    );
    await _loadAlerts();
  }
  
  /// Generate alerts from data and show notifications
  Future<List<Alert>> checkAndGenerateAlerts({
    required List<int> symptomsData,
    required List<int> posEmotionsData,
    required List<int> negEmotionsData,
    required DateTime lastActivityDate,
    required int daysRange,
    bool showNotifications = true,
  }) async {
    debugPrint('Generating alerts from data...');
    
    final newAlerts = Alerting.generateAlerts(
      symptomsData: symptomsData,
      posEmotionsData: posEmotionsData,
      negEmotionsData: negEmotionsData,
      lastActivityDate: lastActivityDate,
      daysRange: daysRange,
    );
    
    debugPrint('Generated ${newAlerts.length} alerts');
    
    if (newAlerts.isNotEmpty) {
      // Add new alerts
      _alerts.addAll(newAlerts);
      _alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      alertsNotifier.value = List.from(_alerts);
      await _saveAlerts();
      
      // Show notifications with standard delay
      if (showNotifications && await _areNotificationsEnabled()) {
        await _scheduleNotifications(newAlerts);
      }
    }
    
    return newAlerts;
  }
  
  /// Create test alert
  Future<void> createTestAlert({Duration delay = const Duration(seconds: 10)}) async {
    final alert = Alert(
      id: "test_${DateTime.now().millisecondsSinceEpoch}",
      title: "Test Alert",
      description: "This is a test notification",
      severity: AlertSeverity.critical,
      type: AlertType.combined,
      createdAt: DateTime.now(),
      seen: false,
    );
    
    _alerts.add(alert);
    alertsNotifier.value = List.from(_alerts);
    await _saveAlerts();
    
    await _notificationService.scheduleAlertNotification(alert, delay: delay);
    debugPrint('Test alert created and scheduled');
  }
  
  /// Schedule notifications for multiple alerts with standard delay
  Future<void> _scheduleNotifications(List<Alert> alerts) async {
    for (int i = 0; i < alerts.length; i++) {
      final alert = alerts[i];
      // Use 5 seconds base delay + additional time for multiple alerts
      final delay = Duration(seconds: 5 + (i * 2));
      await _notificationService.scheduleAlertNotification(alert, delay: delay);
      debugPrint('Scheduled notification for alert: ${alert.id} with ${delay.inSeconds}s delay');
    }
  }
  
  /// Mark alerts as seen
  Future<void> markAlertsAsSeen() async {
    for (int i = 0; i < _alerts.length; i++) {
      if (!_alerts[i].seen) {
        _alerts[i] = Alert(
          id: _alerts[i].id,
          title: _alerts[i].title,
          description: _alerts[i].description,
          severity: _alerts[i].severity,
          type: _alerts[i].type,
          createdAt: _alerts[i].createdAt,
          seen: true,
        );
      }
    }
    alertsNotifier.value = List.from(_alerts);
    await _saveAlerts();
    await _notificationService.clearBadgeNumbers();
  }
  
  /// Remove alert
  Future<void> removeAlert(String alertId) async {
    _alerts.removeWhere((alert) => alert.id == alertId);
    alertsNotifier.value = List.from(_alerts);
    await _saveAlerts();
  }
  
  /// Dismiss alert (alias for removeAlert)
  Future<void> dismissAlert(Alert alert) async {
    await removeAlert(alert.id);
  }
  
  /// Clear all alerts
  Future<void> clearAllAlerts() async {
    _alerts.clear();
    alertsNotifier.value = [];
    await _saveAlerts();
    await _notificationService.cancelAllNotifications();
    await _notificationService.clearBadgeNumbers();
  }
  
  /// Test notifications
  Future<bool> testImmediateNotification() async {
    return await _notificationService.sendTestNotification();
  }
  
  /// Create and show alert (simplified - removed "immediate" methods)
  Future<void> createAndShowImmediateAlert() async {
    final alert = Alert(
      id: "test_${DateTime.now().millisecondsSinceEpoch}",
      title: "Test Alert",
      description: "This should appear with standard delay",
      severity: AlertSeverity.critical,
      type: AlertType.combined,
      createdAt: DateTime.now(),
      seen: false,
    );
    
    _alerts.add(alert);
    alertsNotifier.value = List.from(_alerts);
    await _saveAlerts();
    
    await _scheduleNotifications([alert]);
    debugPrint('Test alert created with standard delay');
  }
  
  /// Show all current alerts with standard delay
  Future<void> showAllCurrentAlertsImmediately() async {
    final unseenAlerts = _alerts.where((a) => !a.seen).toList();
    if (unseenAlerts.isNotEmpty) {
      await _scheduleNotifications(unseenAlerts);
    }
  }
  
  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }
  
  /// Enable or disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    
    if (!enabled) {
      // Cancel any pending notifications if disabled
      await _notificationService.cancelAllNotifications();
      await _notificationService.clearBadgeNumbers();
    }
  }
  
  /// Check if notifications are enabled (internal method)
  Future<bool> _areNotificationsEnabled() async {
    return await areNotificationsEnabled();
  }
  
  /// Save alerts to storage
  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = _alerts.map((alert) => {
        'id': alert.id,
        'title': alert.title,
        'description': alert.description,
        'severity': alert.severity.index,
        'type': alert.type.index,
        'createdAt': alert.createdAt.toIso8601String(),
        'seen': alert.seen,
      }).toList();
      await prefs.setString(_alertsKey, jsonEncode(alertsJson));
    } catch (e) {
      debugPrint('Error saving alerts: $e');
    }
  }
  
  /// Load alerts from storage
  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsString = prefs.getString(_alertsKey);
      
      if (alertsString != null) {
        final List<dynamic> alertsList = jsonDecode(alertsString);
        _alerts = alertsList.map((json) => Alert(
          id: json['id'],
          title: json['title'],
          description: json['description'],
          severity: AlertSeverity.values[json['severity']],
          type: AlertType.values[json['type']],
          createdAt: DateTime.parse(json['createdAt']),
          seen: json['seen'] ?? false,
        )).toList();
        
        // Remove old alerts (older than 7 days)
        final now = DateTime.now();
        _alerts.removeWhere((alert) => now.difference(alert.createdAt).inDays > 7);
        
        alertsNotifier.value = List.from(_alerts);
        await _saveAlerts();
      }
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }
}