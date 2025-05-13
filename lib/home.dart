import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notoday/reminder.dart';
import 'daily.dart';
import 'login.dart'; // Import the file where LoginPage is defined
import 'config.dart';
import 'emo.dart'; 
import 'history.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String userName;

  const HomePage({super.key, required this.userId, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int daysSinceSober = 0; // Variable to store the number of days
  String date = ""; // Variable to store the date

  Future<void> _fetchDaysSinceSober() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/${widget.userId}/days_since_sober'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          daysSinceSober = data['days_since_sober']; // Parse the integer from the response
        });
      } else {
        print('Failed to fetch days since sober');
      }
    } catch (e) {
      print('Error fetching days since sober: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDaysSinceSober(); // Fetch the number of days when the widget is initialized

    // Defer the popup until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSobrietyPopup(); // Show the sobriety popup
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
            color: Colors.grey,
          ),
        ),
       backgroundColor: Color.fromARGB(255, 71, 0, 119),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space content between top and bottom
        children: [
          // Add padding from the top for the big number and buttons
          Padding(
            padding: const EdgeInsets.only(top: 22.0), // Add top padding
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
                          builder: (context) => HistoryPage(userId: widget.userId),
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
                            fontWeight: FontWeight.w200,
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
                          builder: (context) => DailyPage(userId: widget.userId),
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
                          builder: (context) => EmoPage(userId: widget.userId),
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
                          builder: (context) => HistoryPage(userId: widget.userId),
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
                    child: const Text('Historia'),
                  ),
                  const SizedBox(height: 20.0), // Add vertical spacing between buttons

                  // // Button: Przypomnij
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReminderPage(),
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
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Wyloguj'),
                  ),
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