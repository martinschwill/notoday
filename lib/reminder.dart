import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

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
    _initializeNotifications();
    _requestPermissions();
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

  void _requestPermissions() {
  _notificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
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
      _scheduleNotification(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOTODAY',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier New',
            color: Colors.blueGrey,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 71, 0, 119),
      ),
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
                        : 'Przypomnij o ${_selectedTime!.format(context)}',
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
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