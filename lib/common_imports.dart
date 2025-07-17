export 'config.dart';
export 'widgets/app_bar.dart';
export 'widgets/app_bar_builder.dart';
export 'widgets/drawer.dart';
export 'widgets/chart_data_builder.dart';
export 'widgets/button_builder.dart';
export 'widgets/alert_widget.dart';
export 'widgets/alert_indicator.dart';
export '../widgets/symptoms_widget.dart';
export '../widgets/emotions_widget.dart';
export 'pages/reminder.dart';
export 'pages/daily.dart';
export 'pages/login.dart';
export 'pages/emo.dart';
export 'pages/analize.dart';
export 'pages/alerts_page.dart';
export 'pages/settings_page.dart';
export 'home.dart';
export 'modules/analytics.dart'; 
export 'modules/alerting.dart';
export 'services/alert_service.dart';
export 'services/user_metrics_service.dart';
export 'services/notification_service.dart';
export 'services/navigation_service.dart';
export 'pages/register.dart';
export 'pages/diaryemo.dart';
export 'pages/toolkit.dart'; 

export 'pages/help_page.dart';


String capitalizeFirst(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

