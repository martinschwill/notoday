export 'config.dart';
export 'widgets/app_bar.dart';
export 'widgets/drawer.dart';
export 'widgets/chart_data_builder.dart';
export 'widgets/button_builder.dart';
export 'pages/reminder.dart';
export 'pages/daily.dart';
export 'pages/login.dart';
export 'pages/emo.dart';
export 'pages/analize.dart';
export 'home.dart';
export 'modules/analytics.dart'; 


String capitalizeFirst(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

