import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/alerts_page.dart';
import '../pages/toolkit.dart';

/// Service to handle deep linking and navigation from notifications
class NavigationService {
  static const String _tappedNotificationAlertKey = 'tapped_notification_alert_id';
  
  /// Global navigator key for navigation without context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Store user data for global navigation
  static int? _currentUserId;
  static String? _currentUserName;
  
  /// Set current user data for global navigation
  static void setCurrentUser(int userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  /// Navigate based on stored notification data if available
  static Future<void> handleNotificationNavigation(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alertId = prefs.getString(_tappedNotificationAlertKey);
    final navigateTo = prefs.getString('notification_navigate_to');
    
    if (alertId != null) {
      debugPrint('Handling notification navigation for alert: $alertId');
      
      if (navigateTo == 'toolkit') {
        debugPrint('Notification navigation: Going to toolkit');
        // Clear the stored navigation intent
        await prefs.remove('notification_navigate_to');
        await prefs.remove(_tappedNotificationAlertKey);
        
        // Navigate to toolkit using global navigation
        navigateToToolkitGlobal();
      } else {
        // Clear the stored alert ID
        await prefs.remove(_tappedNotificationAlertKey);
        
        // Navigate to alerts page (default behavior)
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AlertsPage()),
          );
        }
      }
    }
  }

  /// Check if there's a pending notification navigation
  static Future<bool> hasPendingNotificationNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tappedNotificationAlertKey) || 
           prefs.containsKey('notification_navigate_to');
  }
  
  /// Navigate to toolkit page (for combined/critical alerts)
  static void navigateToToolkit(BuildContext context) {
    Navigator.pushNamed(context, '/toolkit');
  }
  
  /// Navigate to analysis page (for trend alerts)
  static void navigateToAnalysis(BuildContext context) {
    Navigator.pushNamed(context, '/analize');
  }
  
  /// Navigate to daily diary page (for inactivity alerts)
  static void navigateToDiary(BuildContext context) {
    Navigator.pushNamed(context, '/daily');
  }
  
  /// Navigate to emotions diary page (for emotion alerts)
  static void navigateToEmotions(BuildContext context) {
    Navigator.pushNamed(context, '/diaryemo');
  }
  
  /// Navigate to home page (default fallback)
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
  
  // Global navigation methods (no context required)
  
  /// Navigate to toolkit page using global key
  static void navigateToToolkitGlobal() {
    debugPrint('NavigationService: Attempting to navigate to toolkit');
    debugPrint('NavigationService: Navigator key state: ${navigatorKey.currentState}');
    debugPrint('NavigationService: Current user - ID: $_currentUserId, Name: $_currentUserName');
    
    if (navigatorKey.currentState != null && _currentUserId != null && _currentUserName != null) {
      debugPrint('NavigationService: Pushing ToolkitPage with user data');
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ToolkitPage(
            userId: _currentUserId!,
            userName: _currentUserName!,
          ),
        ),
      );
    } else {
      debugPrint('NavigationService: ERROR - Navigator key state is null or user data missing!');
      debugPrint('NavigationService: Navigator: ${navigatorKey.currentState}, UserId: $_currentUserId, UserName: $_currentUserName');
    }
  }
  
  /// Navigate to analysis page using global key
  static void navigateToAnalysisGlobal() {
    debugPrint('NavigationService: Attempting to navigate to analysis');
    navigatorKey.currentState?.pushNamed('/analize');
  }
  
  /// Navigate to daily diary page using global key
  static void navigateToDiaryGlobal() {
    debugPrint('NavigationService: Attempting to navigate to diary');
    navigatorKey.currentState?.pushNamed('/daily');
  }
  
  /// Navigate to emotions diary page using global key
  static void navigateToEmotionsGlobal() {
    debugPrint('NavigationService: Attempting to navigate to emotions');
    navigatorKey.currentState?.pushNamed('/diaryemo');
  }
  
  /// Navigate to home page using global key
  static void navigateToHomeGlobal() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }
}
