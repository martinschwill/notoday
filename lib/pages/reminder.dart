import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:timezone/timezone.dart' as tz;

import '../common_imports.dart'; 

class ReminderPage extends StatefulWidget {
  final String userName; 
  final int userId; 
  const ReminderPage({super.key, required this.userName , required this.userId});

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
      endDrawer: CustomDrawer(userName: widget.userName, userId: widget.userId), 
      body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Center vertically
          // crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
           Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Center(
                  child: Text(
                    'Przypomnienie \n o wypełnieniu dzienników',
                    style: const TextStyle(
                    fontSize: 24.0, // Adjust the font size as needed
                    fontWeight: FontWeight.w300, // Optional: Make the text bold
                    color: Colors.blueGrey, // Optional: Keep the color consistent
                    ),
                    textAlign: TextAlign.center, // Center the text horizontally
                    )),
                    const SizedBox(height: 32.0),
            Center(
              child: Material(
                    color: Colors.transparent, // Make the background transparent
                    child: InkWell(
                      borderRadius: BorderRadius.circular(80.0), // Match the circle shape
                      onTap: () {
                        _pickTime();
                      },
                      child: Container(
                        width: 160.0,
                        height: 160.0,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedTime == null
                              ? '--:--'
                              : '${_selectedTime!.format(context)}',
                          style: const TextStyle(
                            fontSize: 54.0,
                            fontWeight: FontWeight.w100,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 32.0),
            
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center the buttons vertically
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons to full width
                children: [
                  // Button: Czas przypomnienia
                  ElevatedButton(
                    onPressed: () {
                      _pickTime();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Wybierz czas przypomnienia'),
                  ),
                  const SizedBox(height: 20.0), // Add vertical spacing between buttons

                  // Button: Emocje
                  ElevatedButton(
                    onPressed: () {
                      _cancelNotification();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Usuń przypomnienie'),
                  ),
                  const SizedBox(height: 20.0), // Add vertical spacing between buttons

                  
                  

                  // Logout Button
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.pushReplacement(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const LoginPage()),
                  //     );
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     padding: const EdgeInsets.symmetric(vertical: 16.0),
                  //     textStyle: const TextStyle(fontSize: 18.0),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(20.0),
                  //     ),
                  //   ),
                  //   child: const Text('Wyloguj'),
                  // ),
                ],
              ),
            ),]
            ),
          ),



       ]
    ));
          
        
      
          
    
  }
}