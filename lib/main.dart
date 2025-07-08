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
    debugPrint('Initializing app services...');
    
    // Initialize the AlertService (which also initializes NotificationService)
    final alertService = AlertService();
    await alertService.initialize();
    
    // Re-initialize with our callback
    await NotificationService().initialize(
      onNotificationTapped: (alertId) {
        debugPrint('Notification tapped: $alertId');
        // Store the alert ID for later use when app is opened
        _storeNotificationAlertId(alertId);
        
        // Also immediately clear badges
        alertService.markAlertsAsSeen();
      },
    );
    
    // Initialize the UserMetricsService but don't run alert checks
    // (we'll do that after the app is fully loaded)
    final metricsService = UserMetricsService();
    
    // Wait a bit to ensure we don't have duplicate notifications at startup
    Future.delayed(const Duration(seconds: 2), () async {
      debugPrint('Running delayed alert checks after app initialization');
      await metricsService.runAlertChecks(showNotifications: true);
    });
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