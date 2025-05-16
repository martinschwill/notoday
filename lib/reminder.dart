import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:timezone/timezone.dart' as tz;
import 'widgets/app_bar.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  TimeOfDay? _selectedTime;
  
  @override
  void initState() {
    super.initState();
    _loadSelectedTime();
    _requestPermissions();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings =
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings, 
        );
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
    },
    );
  }

  void _requestPermissions() async {
    // iOS
  await _notificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    // Android
  if (Theme.of(context).platform == TargetPlatform.android) {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}

//Save and load selected time
Future<void> _saveSelectedTime(TimeOfDay time) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('reminder_hour', time.hour);
  await prefs.setInt('reminder_minute', time.minute);
}

Future<void> _loadSelectedTime() async {
  final prefs = await SharedPreferences.getInstance();
  final hour = prefs.getInt('reminder_hour');
  final minute = prefs.getInt('reminder_minute');
  if (hour != null && minute != null) {
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }
}

  void _scheduleNotification(TimeOfDay time) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      0,
      'Notoday - przypomnienie',
      'Wypełnij dzienniczki!',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime, // Add this line

    );
  }

  void _cancelNotification() async {
    await _notificationsPlugin.cancel(0);
    setState(() {
      _selectedTime = null; // Reset the selected time
    });
  }


  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
      _saveSelectedTime(pickedTime);
      _scheduleNotification(pickedTime);
    }

}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'NOTODAY'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                children: [
                  Text(
                    _selectedTime == null
                        ? 'Brak przypomnienia'
                        : 'Przypomnij o \n\n\n${_selectedTime!.format(context)}',
                    style: const TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.w300,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: () {
                      _pickTime();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Adjust padding for a larger button
                      textStyle: const TextStyle(fontSize: 18.0), // Bigger font size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0), // Match the roundness of the date background
                      ),
                    ),
                    child: const Text('Wybierz czas przypomnienia'),
                  ),
                  const SizedBox(height: 30.0), // Space between buttons
                  ElevatedButton(
                    onPressed: () {
                      _cancelNotification();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Adjust padding for a larger button
                      textStyle: const TextStyle(fontSize: 18.0), // Bigger font size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0), // Match the roundness of the date background
                      ),
                    ),
                    child: const Text('Anuluj przypomnienie'),
                  ),
                  
                ],
              ),
            ),
          ],
        ),
      ),
          
    );
  }
}