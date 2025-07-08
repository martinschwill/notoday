import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../modules/alerting.dart';

/// Service to handle showing alerts as system notifications
/// Rebuilt for simplicity and reliability
class NotificationService {
  // MARK: - Properties
  
  /// Plugin for local notifications
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  /// Notification channel configuration
  static const String _channelId = 'notoday_alert_channel';
  static const String _channelName = 'Alert Notifications';
  static const String _channelDesc = 'Health trend alerts and reminders';
  
  /// Base ID for alert notifications
  static const int _notificationBaseId = 1000;
  
  /// Callback for when a notification is tapped
  Function(String?)? _onNotificationTapped;
  
  /// Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  
  // MARK: - Constructor
  
  /// Factory constructor to return the singleton instance
  factory NotificationService() => _instance;
  
  /// Private constructor for singleton
  NotificationService._internal();
  
  // MARK: - Public Methods
  
  /// Initialize the notification service
  Future<bool> initialize({Function(String?)? onNotificationTapped}) async {
    _onNotificationTapped = onNotificationTapped;
    
    // Configure platform-specific settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestProvisionalPermission: true,
      requestCriticalPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    
    // Initialize plugin with settings
    final success = await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    // Request permissions immediately
    final permissionsGranted = await requestPermissions();
    
    debugPrint('NotificationService initialized: $success, permissions granted: $permissionsGranted');
    return success ?? false;
  }
  
  /// Request notification permissions
  Future<bool> requestPermissions() async {
    bool permissionsGranted = false;
    
    try {
      // iOS permissions
      final iOSPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
          
      if (iOSPlugin != null) {
        final result = await iOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
          provisional: true,
        );
        permissionsGranted = result ?? false;
        debugPrint('iOS notification permissions granted: $permissionsGranted');
      }
      
      // Android permissions
      if (await Permission.notification.request().isGranted) {
        permissionsGranted = true;
        debugPrint('Android notification permissions granted');
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    
    return permissionsGranted;
  }
  
  /// Show an alert as a notification immediately
  Future<bool> showAlertNotification(Alert alert) async {
    try {
      final int notificationId = _notificationBaseId + alert.hashCode.abs() % 900;
      debugPrint('Showing immediate notification for alert: ${alert.id} with ID: $notificationId');
      
      // Show notification
      await _plugin.show(
        notificationId,
        _getTitle(alert),
        alert.description,
        NotificationDetails(
          android: _getAndroidDetails(alert),
          iOS: _getIOSDetails(alert),
        ),
        payload: alert.id,
      );
      
      debugPrint('Immediate notification sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error showing notification: $e');
      return false;
    }
  }
  
  /// Schedule an alert notification to appear after a delay
  Future<bool> scheduleAlertNotification(Alert alert, {Duration delay = const Duration(seconds: 5)}) async {
    try {
      // For very short delays, show immediately
      if (delay.inSeconds < 2) {
        return showAlertNotification(alert);
      }
      
      // Ensure permissions before scheduling
      await requestPermissions();
      
      final int notificationId = _notificationBaseId + alert.hashCode.abs() % 900;
      final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);
      
      debugPrint('Scheduling notification for alert: ${alert.id} at ${scheduledTime.toIso8601String()} with ID: $notificationId');
      
      // Schedule notification
      await _plugin.zonedSchedule(
        notificationId,
        _getTitle(alert),
        alert.description,
        scheduledTime,
        NotificationDetails(
          android: _getAndroidDetails(alert),
          iOS: _getIOSDetails(alert),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: alert.id,
      );
      
      // Verify scheduling
      final iOSPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iOSPlugin != null) {
        final pendingRequests = await iOSPlugin.pendingNotificationRequests();
        final scheduled = pendingRequests.any((request) => request.id == notificationId.toString());
        debugPrint('Notification scheduled successfully: $scheduled (${pendingRequests.length} pending)');
      }
      
      return true;
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      return false;
    }
  }
  
  /// Cancel a specific notification for an alert
  Future<void> cancelNotification(Alert alert) async {
    try {
      final int notificationId = _notificationBaseId + alert.hashCode.abs() % 900;
      await _plugin.cancel(notificationId);
      debugPrint('Cancelled notification with ID: $notificationId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
  
  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      debugPrint('Cancelled all pending notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
  
  /// Reset badge count to zero
  Future<void> clearBadge() async {
    try {
      final iOSPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iOSPlugin != null) {
        // Use a simple silent notification with badge 0
        await _plugin.show(
          9999,
          null, 
          null,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: false,
              presentSound: false,
              presentBadge: true,
              badgeNumber: 0,
            ),
            android: null,
          ),
        );
        debugPrint('Badge count cleared');
      }
    } catch (e) {
      debugPrint('Error clearing badge: $e');
    }
  }
  
  /// Update badge based on number of alerts
  Future<void> updateBadgeCount(int count) async {
    try {
      final iOSPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iOSPlugin != null) {
        // Use a silent notification to update badge count
        await _plugin.show(
          9998,
          null,
          null,
          NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: false,
              presentSound: false,
              presentBadge: true,
              badgeNumber: count,
            ),
            android: null,
          ),
        );
        debugPrint('Badge count updated to $count');
      }
    } catch (e) {
      debugPrint('Error updating badge count: $e');
    }
  }
  
  /// Send a test notification to verify system is working
  Future<bool> sendTestNotification() async {
    try {
      await requestPermissions();
      
      final now = DateTime.now();
      final id = now.millisecondsSinceEpoch % 1000;
      
      // Show an immediate test notification
      await _plugin.show(
        id,
        'Test Notification',
        'This is a test notification sent at ${now.hour}:${now.minute}:${now.second}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.max,
            color: Colors.blue,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            badgeNumber: 1,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: 'test_notification',
      );
      
      debugPrint('Test notification sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      return false;
    }
  }
  
  // MARK: - Private Methods
  
  /// Get notification title based on alert severity
  String _getTitle(Alert alert) {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return 'Ważne powiadomienie!';
      case AlertSeverity.warning:
        return 'Ostrzeżenie';
      case AlertSeverity.info:
        return 'Informacja';
    }
  }
  
  /// This method intentionally kept for compatibility reasons despite not being directly referenced
  /// It may be called through reflection or other means in the existing codebase
  @pragma('vm:entry-point')
  String _getNotificationTitle(Alert alert) => _getTitle(alert);
  
  /// Get Android notification details based on alert severity
  AndroidNotificationDetails _getAndroidDetails(Alert alert) {
    Color color;
    
    switch (alert.severity) {
      case AlertSeverity.critical:
        color = Colors.red;
        break;
      case AlertSeverity.warning:
        color = Colors.orange;
        break;
      case AlertSeverity.info:
        color = Colors.blue;
        break;
    }
    
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Notoday Alert',
      color: color,
      category: alert.severity == AlertSeverity.critical 
          ? AndroidNotificationCategory.alarm 
          : AndroidNotificationCategory.recommendation,
    );
  }
  
  /// Get iOS notification details based on alert severity
  DarwinNotificationDetails _getIOSDetails(Alert alert) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      badgeNumber: 1,
      sound: 'default',
      interruptionLevel: alert.severity == AlertSeverity.critical 
          ? InterruptionLevel.timeSensitive
          : InterruptionLevel.active,
    );
  }
  
  /// Handle notification response (when user taps on notification)
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    _onNotificationTapped?.call(response.payload);
  }
  
  /// This method intentionally kept for compatibility reasons despite not being directly referenced
  /// It may be called through reflection or other means in the existing codebase
  @pragma('vm:entry-point')
  Color _getColorForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }
  
  // MARK: - Compatibility Methods
  
  /// Legacy method to clear badge numbers
  Future<void> clearBadgeNumbers() async {
    await clearBadge();
  }
  
  /// Legacy method for badge updating
  Future<void> refreshBadgeCount() async {
    try {
      final iOSPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
          
      if (iOSPlugin != null) {
        // Get count of pending notifications
        final pendingRequests = await iOSPlugin.pendingNotificationRequests();
        final badgeCount = pendingRequests.length;
        await updateBadgeCount(badgeCount);
      }
    } catch (e) {
      debugPrint('Error refreshing badge count: $e');
    }
  }
  
  /// Legacy method to test if notifications are working
  Future<bool> testDeviceNotifications() async {
    return sendTestNotification();
  }
  
  /// Legacy method to show test notification
  Future<void> showTestNotification() async {
    await sendTestNotification();
  }
  
  /// Legacy method to reset badge when app is opened
  Future<void> resetBadgeOnAppOpen() async {
    await clearBadge();
  }
  
  /// Legacy method for scheduling test notifications
  Future<void> scheduleTestNotifications() async {
    try {
      await requestPermissions();
      
      // Schedule test alerts at 5s and 10s
      final testAlert1 = Alert(
        id: 'test-5s',
        title: 'Test Alert (5s)',
        description: 'This is a test alert scheduled for 5 seconds',
        severity: AlertSeverity.info,
        type: AlertType.combined,
        seen: false,
      );
      
      final testAlert2 = Alert(
        id: 'test-10s',
        title: 'Test Alert (10s)',
        description: 'This is a test alert scheduled for 10 seconds',
        severity: AlertSeverity.warning,
        type: AlertType.combined,
        seen: false, 
      );
      
      await scheduleAlertNotification(testAlert1, delay: const Duration(seconds: 5));
      await scheduleAlertNotification(testAlert2, delay: const Duration(seconds: 10));
      
      debugPrint('Two test notifications scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling test notifications: $e');
    }
  }
  
  // Legacy methods removed: _clearBadgeNumber and _updateBadgeCount are now directly using clearBadge and refreshBadgeCount
}