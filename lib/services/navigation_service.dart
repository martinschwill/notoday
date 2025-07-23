import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/alerts_page.dart';

/// Service to handle deep linking and navigation from notifications
class NavigationService {
  static const String _tappedNotificationAlertKey = 'tapped_notification_alert_id';

  /// Navigate based on stored notification data if available
  static Future<void> handleNotificationNavigation(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alertId = prefs.getString(_tappedNotificationAlertKey);
    
    if (alertId != null) {
      debugPrint('Handling notification navigation for alert: $alertId');
      
      // Clear the stored alert ID
      await prefs.remove(_tappedNotificationAlertKey);
      
      // Navigate to alerts page
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AlertsPage()),
        );
      }
    }
  }

  /// Check if there's a pending notification navigation
  static Future<bool> hasPendingNotificationNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tappedNotificationAlertKey);
  }
}
