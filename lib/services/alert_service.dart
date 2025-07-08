import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/alerting.dart';
import 'notification_service.dart';

/// Service to manage alerts - store, retrieve, update alerts and handle notifications
class AlertService {
  // MARK: - Properties
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
      onNotificationTapped: (alertId) async {
        // Handle when user taps on notification
        if (alertId != null) {
          debugPrint('Alert notification tapped: $alertId');
          
          // Immediately clear badge when notification is tapped
          await markAlertsAsSeen();
          
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
        // For combined alerts, use a short delay (30 seconds) for development
        // Otherwise use the standard 1 hour delay
        Duration notificationDelay = const Duration(seconds: 30); 
            
        await _notificationService.scheduleAlertNotification(
          alert, 
          delay: notificationDelay
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
    final notificationsEnabled = await areNotificationsEnabled();
    if (changed) {
      _sortAlertsByPriority();
      alertsNotifier.value = List.from(_currentAlerts);
      await _saveAlerts();
      
      // Schedule notifications for new alerts if requested and notifications are enabled
      debugPrint('Scheduling notifications: showNotifications=$showNotifications, notificationsEnabled=$notificationsEnabled');
      
      if (showNotifications && notificationsEnabled) {
        // First send a test notification to verify system
        if (actuallyAddedAlerts.isNotEmpty) {
          debugPrint('Sending immediate test notification for debugging');
          await _notificationService.showTestNotification();
        }
        
        // Schedule notifications for each alert with shorter delays for testing
        for (final alert in actuallyAddedAlerts) {
          // Always notify for all alerts in debug mode
          debugPrint('Scheduling notification for alert: ${alert.id} with severity: ${alert.severity}');
          
          // Use shorter delays for testing during development
          Duration notificationDelay;
          
          if (alert.severity == AlertSeverity.critical) {
            notificationDelay = const Duration(seconds: 5);
          } else if (alert.type == AlertType.combined) {
            notificationDelay = const Duration(seconds: 10);
          } else {
            notificationDelay = const Duration(seconds: 15);
          }
          
          await _notificationService.scheduleAlertNotification(
            alert, 
            delay: notificationDelay
          );
          debugPrint('Notification scheduled for alert: ${alert.id} with ${notificationDelay.inSeconds}s delay');
        }
      }
    } else {
      debugPrint('Notifications not scheduled: showNotifications=$showNotifications, notificationsEnabled=$notificationsEnabled');
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
      
      // If no more alerts, clear badge completely, otherwise update badge count
      if (_currentAlerts.isEmpty) {
        await _notificationService.clearBadgeNumbers();
      } else {
        await _notificationService.refreshBadgeCount();
      }
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
    
    // Also cancel all pending notifications and clear badge
    await _notificationService.cancelAllNotifications();
    
    // Ensure badge is completely cleared (double-check)
    await _notificationService.clearBadgeNumbers();
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
    debugPrint('Running alert checks with showNotifications=$showNotifications');
    
    // First, cancel any existing pending notifications to prevent duplicates
    if (showNotifications) {
      debugPrint('Canceling existing pending notifications before generating new alerts');
      await _notificationService.cancelAllNotifications();
    }
    
    // Generate alerts from data
    final newAlerts = Alerting.generateAlerts(
      symptomsData: symptomsData,
      posEmotionsData: posEmotionsData,
      negEmotionsData: negEmotionsData,
      lastActivityDate: lastActivityDate,
      daysRange: daysRange,
    );
    
    debugPrint('Generated ${newAlerts.length} new alerts');
    
    // Enhanced deduplication - check not just IDs but also types and content
    final List<Alert> filteredNewAlerts = [];
    
    for (final newAlert in newAlerts) {
      bool isDuplicate = false;
      
      // Check if there's a similar alert already in the list
      for (final existingAlert in _currentAlerts) {
        // First check by ID
        if (existingAlert.id == newAlert.id) {
          isDuplicate = true;
          break;
        }
        
        // Then check by type and similarity
        if (existingAlert.type == newAlert.type && 
            existingAlert.severity == newAlert.severity &&
            DateTime.now().difference(existingAlert.createdAt).inHours < 24) {
          // Same type, severity and created within last 24 hours - likely duplicate
          isDuplicate = true;
          debugPrint('Skipping likely duplicate alert of type ${newAlert.type}');
          break;
        }
      }
      
      if (!isDuplicate) {
        filteredNewAlerts.add(newAlert);
      }
    }
    
    debugPrint('${filteredNewAlerts.length} alerts are unique (not duplicates)');
    
    if (filteredNewAlerts.isNotEmpty) {
      debugPrint('Saving unique alerts: ${filteredNewAlerts.map((a) => a.id).join(', ')}');
      
      // The addAlerts method already handles notification scheduling based on showNotifications
      await addAlerts(filteredNewAlerts, showNotifications: showNotifications);
      debugPrint('Added ${filteredNewAlerts.length} alerts with showNotifications=$showNotifications');
    }

    return newAlerts;
  }
  
  /// Sort alerts by priority: critical severity first, then unseen alerts, then newest
  void _sortAlertsByPriority() {
    _currentAlerts.sort((a, b) {
      // First by severity (critical first)
      final severityComparison = b.severity.index.compareTo(a.severity.index);
      if (severityComparison != 0) return severityComparison;
      
      // Then by seen status (unseen first)
      if (a.seen != b.seen) return a.seen ? 1 : -1;
      
      // Then by date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }
  
  /// Create a test notification alert (only for development/testing)
  Future<void> createTestAlert({Duration delay = const Duration(seconds: 5)}) async {
    final timestamp = DateTime.now();
    final testAlert = Alert(
      id: "test_${timestamp.millisecondsSinceEpoch}",
      title: "Alert testowy",
      description: "To jest alert testowy stworzony do przetestowania systemu powiadomień o ${timestamp.hour}:${timestamp.minute}:${timestamp.second}.",
      severity: AlertSeverity.critical, // Use critical for higher visibility
      type: AlertType.combined, // Use combined type for better visibility
      createdAt: timestamp,
      seen: false,
    );
    
    debugPrint('Creating test alert with delay: ${delay.inSeconds} seconds');
    
    // Add the alert to the list
    _currentAlerts.add(testAlert);
    _sortAlertsByPriority();
    alertsNotifier.value = List.from(_currentAlerts);
    await _saveAlerts();
    
    // Check notification permissions and request them if needed
    final notificationsEnabled = await areNotificationsEnabled();
    debugPrint('Test alert notifications enabled: $notificationsEnabled');
    
    // Force request permissions to ensure notifications can be shown
    await _notificationService.requestPermissions();
    
    // First send an immediate test notification
    debugPrint('Sending immediate test notification...');
    await _notificationService.showTestNotification();
    
    // Then schedule the alert notification with delay
    debugPrint('Also scheduling delayed notification...');
    await _notificationService.scheduleAlertNotification(
      testAlert, 
      delay: delay
    );
    
    debugPrint('Test alert scheduled with ID: ${testAlert.id}');
  }
  
  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_notificationsEnabledKey) ?? true; // Default to true
    debugPrint('Notifications enabled: $enabled');
    return enabled;
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
      final List<Map<String, dynamic>> alertsJson = _currentAlerts.map((alert) {
        return {
          'id': alert.id,
          'title': alert.title,
          'description': alert.description,
          'severity': alert.severity.index,
          'type': alert.type.index,
          'createdAt': alert.createdAt.toIso8601String(),
          'seen': alert.seen,
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
            createdAt: alertJson['createdAt'] is String 
                ? DateTime.parse(alertJson['createdAt']) 
                : DateTime.fromMillisecondsSinceEpoch(alertJson['createdAt']),
            seen: alertJson['seen'] ?? false,
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

  /// Update badge count to reflect the current number of alerts and mark alerts as seen
  /// Call this when the user views alerts but doesn't delete them
  Future<void> markAlertsAsSeen() async {
    bool changed = false;
    
    for (final alert in _currentAlerts) {
      if (!alert.seen) {
        // Mark as seen (we'll use a new alert instance since Alert is immutable)
        final seenIndex = _currentAlerts.indexOf(alert);
        if (seenIndex >= 0) {
          _currentAlerts[seenIndex] = Alert(
            id: alert.id,
            title: alert.title,
            description: alert.description,
            severity: alert.severity,
            type: alert.type,
            createdAt: alert.createdAt,
            seen: true,
          );
          changed = true;
        }
      }
    }
    
    if (changed) {
      alertsNotifier.value = List.from(_currentAlerts);
      await _saveAlerts();
    }
    
    // Clear badges immediately
    await _notificationService.clearBadgeNumbers();
    
    // Double-check after a delay to ensure iOS really clears the badge
    await Future.delayed(const Duration(milliseconds: 500));
    await _notificationService.clearBadgeNumbers();
    
    debugPrint('Alerts marked as seen and badges cleared');
  }
  
  /// Test the notification system by sending test notifications
  Future<bool> testNotifications() async {
    try {
      // First check if notifications are enabled
      final enabled = await areNotificationsEnabled();
      if (!enabled) {
        debugPrint('Notifications are disabled, cannot test');
        return false;
      }
      
      // Create a test alert which will handle the notification
      await createTestAlert(delay: const Duration(seconds: 5));
      
      return true;
    } catch (e) {
      debugPrint('Error testing notifications: $e');
      return false;
    }
  }
}