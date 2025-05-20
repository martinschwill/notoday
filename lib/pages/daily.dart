import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common_imports.dart'; 


class DailyPage extends StatefulWidget {
  final int userId; // Pass the user ID to this page
  final String userName; // Pass the user name to this page

  const DailyPage({super.key, required this.userId, required this.userName});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  final List<String> _items = []; // List to store symptoms
  final Set<int> _selectedRows = {}; // Set to keep track of selected rows
  final String date = DateTime.now().toLocal().toString().split(' ')[0]; // Format: YYYY-MM-DD
  // final String date = '2025-05-03';
  bool _isLoading = true; // Flag to track loading state
  bool _wasFilled = false; 

  Future<void> _fetchSymptoms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/symptoms'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('symptoms_items', data.map((item) => item['name'] as String).toList());
        setState(() {
          _items.clear(); // Clear the list before adding new items
          _items.addAll(data.map((item) => item['name'] as String).toList());
          _isLoading = false; // Set loading to false after fetching data
        });
      } else {
        print('Failed to load symptoms');
        _isLoading = false; // Set loading to false if there's an error
      }
    } catch (e) {
      print('Error fetching symptoms: $e');
      _isLoading = false; // Set loading to false if there's an error
    }
  }

  Future<void> _checkDateUserPair() async {
    final Map<String, dynamic> payload = {
          "user_id": widget.userId,
          "date": date, // Format: YYYY-MM-DD
    };
    try {
        // Send the POST request
        final response = await http.post(
          Uri.parse('$baseUrl/days_symptoms/check'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(payload)
          );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _wasFilled = data['exists']; // Check if the user has already submitted data for today
        if (_wasFilled) {
          // If the user has already submitted data for today, show a message
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Dzisiaj już wypełniałeś dzienniczek!'),
                // content: const Text('Dzisiaj już wypełniałeś dzienniczek!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        print('Failed to check date-user pair');
      }
    } catch (e) {
      print('Error checking date-user pair: $e');
    }
  }

  Future<void> _fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getStringList('symptoms_items');
    if (savedItems != null && savedItems.isNotEmpty) {
      setState(() {
        _items.clear();
        _items.addAll(savedItems);
        _isLoading = false;
      });
    } else {
      await _fetchSymptoms(); // Only fetch if not found in prefs
    }
  }

  void _onPlusButtonPressed(int index) {
    setState(() {
      // Toggle the selection state of the row
      if (_selectedRows.contains(index)) {
        _selectedRows.remove(index); // Deselect if already selected
      } else {
        _selectedRows.add(index); // Select if not selected
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchItems(); // loads symtpoms or fetches them from the API
    _checkDateUserPair(); // Check if the user has already submitted data for today
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'NOTODAY'),
      endDrawer: CustomDrawer(userName: widget.userName), 
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Display the current date above the table
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Material(
                      color: Colors.transparent, // Make the background transparent
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.0), // Match the container's border radius
                        onTap: () {
                          // Define the action to perform on tap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalyzePage(userId: widget.userId, userName: widget.userName),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 226, 234, 236),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 20.0, // Adjust the font size as needed
                              fontWeight: FontWeight.w300, // Optional: Make the text bold
                              color: Colors.blueGrey, // Optional: Keep the color consistent
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedRows.contains(index);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(60.0, 10.0, 40.0, 10.0),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(255, 247, 239, 162)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _items[index],
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _onPlusButtonPressed(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align buttons on opposite sides
          children: [

            // Clear Button
            CustomButton(
              onPressed: () {
                setState(() {
                  _selectedRows.clear(); // Clear all selected rows
                });
                print('All selected rows cleared');
              },
              text: 'Usuń', 
            ),

            // Dodaj Button
            CustomButton(
              onPressed: () async {
                if (_selectedRows.isEmpty) {
                  
                  // Show a popup if no rows are selected
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Wysyłam...'),
                        content: const Text('Na pewno nie chcesz nic zaznaczyć?'),
                        actions: [
                          // Cancel Button
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('Wróć'),
                          ),
                          // Accept Button
                          TextButton(             
                            onPressed: () async {
                                
                                // Prepare the payload with an empty list of symptoms
                                final int userId = widget.userId; 
                                final Map<String, dynamic> payload = {

                                  "user_id": userId,
                                  "symptoms": [], // Empty list of symptoms
                                  "date": date, // Format: YYYY-MM-DD
                                };
                                try {
                                  final response = await http.put(
                                    Uri.parse('$baseUrl/days'),
                                    headers: {"Content-Type": "application/json"},
                                    body: json.encode(payload),
                                    );
                                    if (response.statusCode == 200) {
                                      print('Empty data successfully sent: ${response.body}');
                                    
                                    } else {
                                      print('Failed to send empty data: ${response.statusCode}');
                                    }
                             
                                } catch (e) {
                                  print('Error sending empty data: $e');
                                }

                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: const Text('Ok'),
                          ),
                        ],
                      );
                      
                    },
                  );
                } else {
                 // Prepare the payload
                  final List<Map<String, dynamic>> selectedSymptoms = _selectedRows.map((index) {
                    return {"id": index + 1, "name": _items[index]}; // Map selected rows to symptoms
                  }).toList();
                  final int userId = widget.userId; 
                  final Map<String, dynamic> payload = {
                    "user_id": userId,
                    "symptoms": selectedSymptoms,
                    "date": date, // Format: YYYY-MM-DD
                  };
                  try {
                    final response = await http.put(
                        Uri.parse('$baseUrl/days'), 
                        headers: {"Content-Type": "application/json"},
                        body: json.encode(payload),
                      );

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        print('Data successfully sent: ${response.body}');
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Dzień zapisany'),
                                content: const Text('Symptomy zapisane! Iść do emocji?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close the dialog
                                    },
                                    child: const Text('Zamknij'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EmoPage(userId: widget.userId, userName: widget.userName),
                                        ),
                                      );
                                    },
                                    child: const Text('Idź'),
                                  )
                                ],
                              );
                            },
                        );
                      } else {
                        print('Failed to send data: ${response.statusCode}');
                        print(response.body);
                      }
                  } catch (e) {
                    print('Error sending data: $e');
                  }
                }
              },
              text: 'Dodaj', 
              ),
          ],
        ),
            
    )])
    );
  }
}