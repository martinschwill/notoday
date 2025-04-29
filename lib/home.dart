import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'daily.dart';
import 'login.dart'; // Import the file where LoginPage is defined
import 'config.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String userName;

  const HomePage({super.key, required this.userId, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int daysSinceSober = 0; // Variable to store the number of days

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
        backgroundColor: const Color.fromARGB(255, 185, 250, 110),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the big number
          Center(child: Text('Witaj ${widget.userName}, tyle dni jesteś już trzeźwy:')),
          Text(
            '$daysSinceSober',
            style: const TextStyle(
              fontSize: 80.0,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 40.0),
          // Display the buttons
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Button
                ElevatedButton(
                  onPressed: () {
                    print('Left button pressed');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                    textStyle: const TextStyle(fontSize: 18.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text('Left Button'),
                ),
                // Right Button
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
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                    textStyle: const TextStyle(fontSize: 18.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text('Dzienniczek'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          // Logout Button
          ElevatedButton(
            onPressed: () {
              // Navigate back to the LoginPage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              textStyle: const TextStyle(fontSize: 18.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}