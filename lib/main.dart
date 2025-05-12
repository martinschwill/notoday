import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'login.dart';

void main() {
  tz.initializeTimeZones(); // Initialize timezone data
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