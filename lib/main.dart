import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import '../common_imports.dart'; 

/// Store the alert ID from a tapped notification for later navigation
Future<void> _storeNotificationAlertId(String? alertId) async {
  if (alertId != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tapped_notification_alert_id', alertId);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // Initialize timezone data
  
  try {
    // Initialize the AlertService
    final alertService = AlertService();
    await alertService.initialize();
    
    // Initialize the NotificationService
    final notificationService = NotificationService();
    await notificationService.initialize(
      onNotificationTapped: (alertId) {
        debugPrint('Notification tapped: $alertId');
        // Store the alert ID for later use when app is opened
        _storeNotificationAlertId(alertId);
      },
    );
    
    // Initialize the UserMetricsService and run initial alert checks
    final metricsService = UserMetricsService();
    await metricsService.runAlertChecks(showNotifications: true);
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTODAY',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(), // Set LoginPage as the initial page
    );
  }
}