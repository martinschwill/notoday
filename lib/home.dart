import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common_imports.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String userName;
  final bool wasOpened; // Flag to check if the page was opened

  const HomePage({super.key, required this.userId, required this.userName, required this.wasOpened});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int daysSinceSober = 0; // Variable to store the number of days
  bool isFirstTime = true; 
  String date = ""; // Variable to store the date

  Future<void> _fetchDaysSinceSober() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/${widget.userId}/days_since_sober'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          daysSinceSober = data['days_since_sober']; // Parse the integer from the response
          isFirstTime = false; 
        });
      } else {
        print('Failed to fetch days since sober');
      }
    } catch (e) {
      print('Error fetching days since sober: $e');
    }
  }

  Future<bool> _isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'already_ran_${widget.userId}';
    final alreadyRan = prefs.getBool(key) ?? false;
    if (!alreadyRan) {
      await prefs.setBool(key, true);
      return true; // This is the first run for this user
    }
    return false; // Not the first run for this user
  }


  // Notification service to manage app badge
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchDaysSinceSober(); // Fetch the number of days when the widget is initialized
    
    // Clear app icon badge when the app is opened
    _notificationService.resetBadgeOnAppOpen();
    
    _isFirstRun().then((firstTime){ // check if it's the first run
      if(firstTime) { 
        _showDatePickerPopup();  // if yes show datepicker to setup first dates 
      }else {
        if(!widget.wasOpened) { // if no and the page was not opened during this session, show the sobriety popup
          WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSobrietyPopup(); 
          });
        }
      }
    }); 
    
    // Check for notifications after a short delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService.handleNotificationNavigation(context);
    });
  }

  void _showSobrietyPopup() {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent closing the dialog by tapping outside
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Zachowujesz trzeźwość?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the first popup
                  _showDatePickerPopup(); // Show the date picker popup
                },
                child: const Text('Nie'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the first popup
                },
                child: const Text('Tak'),
              ),
            ],
          );
        },
      );
  }

  void _showDatePickerPopup() {
    DateTime selectedDate = DateTime.now(); // Default to the current date
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kiedy ostatnio użyłeś?'),
          content: SizedBox(
            width: double.maxFinite, // Ensure the dialog has enough width
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content vertically
              children: [
                CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  onDateChanged: (DateTime newDate) {
                    selectedDate = newDate; // Update the selected date
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  date = "${selectedDate.toLocal()}".split(' ')[0]; // Save the date in YYYY-MM-DD format
                  daysSinceSober = DateTime.now().difference(selectedDate).inDays; // Update the big number

                  // Update the database with the new date
                  http.put(
                    Uri.parse('$baseUrl/users/${widget.userId}'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      "last_date_sober": date,
                    }),
                  ).then((response) {
                    if (response.statusCode == 200) {
                      print('Date updated successfully');
                    } else {
                      print('Failed to update date');
                    }
                  });
                });
                Navigator.of(context).pop(); // Close the date picker popup
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!isFirstTime) {
          showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kiedy wpadłeś?'),
          content: SizedBox(
            width: double.maxFinite, // Ensure the dialog has enough width
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content vertically
              children: [
                CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  onDateChanged: (DateTime newDate) {
                    selectedDate = newDate; // Update the selected date
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  date = "${selectedDate.toLocal()}".split(' ')[0]; // Save the date in YYYY-MM-DD format
                  daysSinceSober = DateTime.now().difference(selectedDate).inDays; // Update the big number

                  // Update the database with the new date
                  http.post(
                    Uri.parse('$baseUrl/users/slipup'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      "slipup_date": date,
                      "user_id": widget.userId,
                    }),
                  ).then((response) {
                    if (response.statusCode == 200) {
                      print('Date updated successfully');
                    } else {
                      print('Failed to update date');
                    }
                  });
                });
                Navigator.of(context).pop(); // Close the date picker popup
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'NOTODAY'),
      endDrawer: CustomDrawer(userName: widget.userName, userId: widget.userId), 
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space content between top and bottom
        children: [
          // Add padding from the top for the big number and buttons
          Padding(
            padding: const EdgeInsets.only(top: 32.0), // Add top padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display the big number
                Center(
                  child: Text(
                    'Gratulacje, ${widget.userName}!\n Dni trzeźwości:',
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
                         Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnalyzePage(userId: widget.userId, userName: widget.userName, daysSinceSober: daysSinceSober),
                        ),
                      );
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
                          '$daysSinceSober',
                          style: const TextStyle(
                            fontSize: 60.0,
                            fontWeight: FontWeight.w100,
                            color: Colors.white,
                          ),
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
                  // Button: Głody
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyPage(userId: widget.userId, userName: widget.userName),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Głody'),
                  ),
                  const SizedBox(height: 20.0), // Add vertical spacing between buttons

                  // Button: Emocje
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmoPage(userId: widget.userId, userName: widget.userName),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Emocje'),
                  ),
                  const SizedBox(height: 20.0), // Add vertical spacing between buttons

                  // Button: Historia
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnalyzePage(userId: widget.userId, userName: widget.userName),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Analiza'),
                  ),
                  const SizedBox(height: 20.0), // Add vertical spacing between buttons

                  // // Button: Przypomnij
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReminderPage(userName: widget.userName, userId: widget.userId,),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Przypomnij'),
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
          ],
        ),
      );
    }
  }