// import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart'; // using flutter_app_badger instead 
// import 'package:flutter_app_badger/flutter_app_badger.dart'; //using flutter_app_badger instead 
import 'package:app_badge_plus/app_badge_plus.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/alerting.dart';
import 'dart:io'; 

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
  
  /// Key for storing notification data
  static const String _tappedNotificationAlertKey = 'tapped_notification_alert_id';
  
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
    
    // Initialize timezone data first
    tz_data.initializeTimeZones();
    
    // Configure platform-specific settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestProvisionalPermission: false,
      requestCriticalPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'ALERT_CATEGORY',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain('view', 'View'),
          ],
        ),
      ],
    );
    
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    
    // Initialize plugin with settings
    final success = await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    // Create notification channel for Android
    await _createNotificationChannel();
    
    // Request permissions immediately
    final permissionsGranted = await requestPermissions();
    
    debugPrint('NotificationService initialized: $success, permissions granted: $permissionsGranted');
    return success ?? false;
  }
  
  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );
      
      await androidPlugin.createNotificationChannel(channel);
      debugPrint('Android notification channel created');
    }
  }
  
  /// Request notification permissions
  Future<bool> requestPermissions() async {
    bool permissionsGranted = false;
    
    try {
      // iOS permissions - be more explicit
      final iOSPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
          
      if (iOSPlugin != null) {
        final result = await iOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: false,
          provisional: false,
        );
        permissionsGranted = result ?? false;
        debugPrint('iOS notification permissions granted: $permissionsGranted');
      }
      
      // Android permissions
      if (Platform.isAndroid) {
        // Request basic notification permission
        if (await Permission.notification.request().isGranted) {
          permissionsGranted = true;
          debugPrint('Android notification permissions granted');
          
          // For Android 12+, also request exact alarm permission if available
          try {
            final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
            if (exactAlarmStatus.isDenied) {
              final exactAlarmResult = await Permission.scheduleExactAlarm.request();
              debugPrint('Android exact alarm permission: ${exactAlarmResult.isGranted ? "granted" : "denied"}');
            } else {
              debugPrint('Android exact alarm permission already granted or not needed');
            }
          } catch (e) {
            debugPrint('Exact alarm permission not available or error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    
    return permissionsGranted;
  }
  
  /// Show an alert as a notification immediately
  Future<bool> showAlertNotification(Alert alert) async {
    try {
      // Ensure permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        debugPrint('No notification permissions, cannot show alert');
        return false;
      }
      
      final int notificationId = _notificationBaseId + alert.hashCode.abs() % 900;
      debugPrint('Showing immediate notification for alert: ${alert.id} with ID: $notificationId');
      debugPrint('Alert details - Title: ${_getTitle(alert)}, Description: ${alert.description}');
      
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
  Future<bool> scheduleAlertNotification(Alert alert, {Duration delay = const Duration(minutes: 3)}) async {
    try {
      // Ensure permissions before scheduling
      await requestPermissions();
      
      final int notificationId = _notificationBaseId + alert.hashCode.abs() % 900;
      final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);
      
      debugPrint('Scheduling notification for alert: ${alert.id} at ${scheduledTime.toIso8601String()} with ID: $notificationId');
      
      // Try exact scheduling first, then fall back to inexact
      try {
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
        debugPrint('Notification scheduled with exact timing');
      } catch (exactError) {
        debugPrint('Exact scheduling failed: $exactError, trying inexact');
        
        await _plugin.zonedSchedule(
          notificationId,
          _getTitle(alert),
          alert.description,
          scheduledTime,
          NotificationDetails(
            android: _getAndroidDetails(alert),
            iOS: _getIOSDetails(alert),
          ),
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: alert.id,
        );
        debugPrint('Notification scheduled with inexact timing');
      }
      
      debugPrint('Notification scheduled successfully for ${delay.inMinutes} minutes from now');
      return true;
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      
      // Fallback: try to show immediate notification if scheduling fails
      debugPrint('Attempting to show immediate notification as fallback');
      return await showAlertNotification(alert);
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
  
  /// Update badge count to match number of alerts
  updateBadgeCount(int count) async {
    if (Platform.isIOS) {
      try {
        await AppBadgePlus.updateBadge(count);
      } catch (e) {
        debugPrint('Error updating badge count: $e');
      }
    } else {
      debugPrint('Badge count update skipped - not iOS platform');
    }
  }
  
  /// Send a test notification to verify system is working
  Future<bool> sendTestNotification() async {
    try {
      final hasPermissions = await requestPermissions();
      debugPrint('Test notification - permissions granted: $hasPermissions');
      
      if (!hasPermissions) {
        debugPrint('Cannot send test notification - no permissions');
        return false;
      }
      
      final now = DateTime.now();
      final id = now.millisecondsSinceEpoch % 1000;
      
      debugPrint('Sending test notification with ID: $id');
      
      // Show an immediate test notification
      await _plugin.show(
        id,
        'Test Notification - Notoday',
        'Test powiadomienia na ekranie blokady ${now.hour}:${now.minute}:${now.second}. Jeśli to widzisz, system działa!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.max,
            color: Colors.blue,
            icon: '@drawable/ic_notification', // Add icon for test notification
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showWhen: true,
            when: now.millisecondsSinceEpoch,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
            badgeNumber: 1,
            interruptionLevel: InterruptionLevel.timeSensitive,
            sound: 'default',
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
      priority: Priority.high,
      ticker: 'Notoday Alert',
      color: color,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification', // Dedicated small notification icon
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Large icon for notification
      styleInformation: const BigTextStyleInformation(''), // Allows for expanded text
      fullScreenIntent: alert.severity == AlertSeverity.critical,
      category: alert.severity == AlertSeverity.critical 
          ? AndroidNotificationCategory.alarm 
          : AndroidNotificationCategory.recommendation,
    );
  }
  
  /// Get iOS notification details based on alert severity
  DarwinNotificationDetails _getIOSDetails(Alert alert) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      // badgeNumber: 1,
      categoryIdentifier: 'ALERT_CATEGORY',
      interruptionLevel: alert.severity == AlertSeverity.critical 
          ? InterruptionLevel.timeSensitive
          : InterruptionLevel.active,
    );
  }
  
  /// Handle notification response (when user taps on notification)
  void _onNotificationResponse(NotificationResponse response) async {
    debugPrint('Notification banner tapped: ${response.payload}');
    
    if (response.payload != null) {
      // Store the alert ID for navigation when app opens (for backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tappedNotificationAlertKey, response.payload!);
      
      // Store a flag indicating we should navigate to toolkit
      await prefs.setString('notification_navigate_to', 'toolkit');
      
      debugPrint('Notification banner: Stored navigation intent for toolkit');
    }
    
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
}