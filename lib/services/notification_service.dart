import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../modules/alerting.dart';

/// Service to handle showing alerts as system notifications
class NotificationService {
  /// Plugin for local notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  /// Notification channel ID for alerts
  static const String _alertChannelId = 'alert_notification_channel';
  
  /// Notification channel name for alerts
  static const String _alertChannelName = 'Alert Notifications';
  
  /// Notification channel description for alerts
  static const String _alertChannelDescription = 'Notifications for health trend alerts';
  
  /// Notification ID base for alerts
  static const int _alertNotificationIdBase = 1000;
  
  /// Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  
  /// Factory constructor to return the singleton instance
  factory NotificationService() {
    return _instance;
  }
  
  /// Private constructor for singleton
  NotificationService._internal();
  
  /// Initialize the notification service
  Future<void> initialize({Function(String?)? onNotificationTapped}) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (onNotificationTapped != null) {
          onNotificationTapped(response.payload);
        }
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
    
    await _requestPermissions();
  }
  
  /// Request permissions for notifications
  Future<void> _requestPermissions() async {
    // iOS permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
    // Android permissions
    await Permission.notification.request();
  }
  
  /// Show an immediate notification for an alert
  Future<void> showAlertNotification(Alert alert) async {
    final int notificationId = _alertNotificationIdBase + alert.hashCode % 100;
    
    await _notificationsPlugin.show(
      notificationId,
      _getNotificationTitle(alert),
      alert.description,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          channelDescription: _alertChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'Notoday Alert',
          color: _getColorForSeverity(alert.severity),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: alert.id,
    );
  }
  
  /// Schedule a notification for an alert to appear after a delay
  Future<void> scheduleAlertNotification(Alert alert, {Duration delay = const Duration(hours: 1)}) async {
    final int notificationId = _alertNotificationIdBase + alert.hashCode % 100;
    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);
    
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      _getNotificationTitle(alert),
      alert.description,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          channelDescription: _alertChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'Notoday Alert',
          color: _getColorForSeverity(alert.severity),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: alert.id,
    );
  }
  
  /// Get notification title based on alert severity and type
  String _getNotificationTitle(Alert alert) {
    String severityText;
    switch (alert.severity) {
      case AlertSeverity.critical:
        severityText = 'Krytyczne';
        break;
      case AlertSeverity.warning:
        severityText = 'Ostrzeżenie';
        break;
      case AlertSeverity.info:
        severityText = 'Informacja';
        break;
    }
    
    return 'Notoday - $severityText: ${alert.title}';
  }
  
  /// Get color for notification based on alert severity
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
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  
  /// Cancel a specific notification by alert ID
  Future<void> cancelNotification(Alert alert) async {
    final int notificationId = _alertNotificationIdBase + alert.hashCode % 100;
    await _notificationsPlugin.cancel(notificationId);
  }
}
