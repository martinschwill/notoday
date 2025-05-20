import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common_imports.dart'; 

class EmoPage extends StatefulWidget {
  final int userId; // Pass the user ID to this page
  final String userName; 

  const EmoPage({super.key, required this.userId, required this.userName});

  @override
  State<EmoPage> createState() => _EmoPageState();
}

class _EmoPageState extends State<EmoPage> {
  final List<String> _emotions = []; // List to store emotions
  List<Map<String, dynamic>> _emotionsData = []; // List to store emotions data
  final Set<int> _selectedRows = {}; // Set to keep track of selected rows
  final String date = DateTime.now().toLocal().toString().split(' ')[0]; // Format: YYYY-MM-DD
  // final String date = '2025-05-03';
  bool _isLoading = true; // Flag to track loading state
  bool _wasFilled = false; // Flag to check if data was already submitted

  Future<void> _fetchEmotions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/emo'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Explicitly cast the data to List<Map<String, dynamic>>
        final List<Map<String, dynamic>> emotionsData = List<Map<String, dynamic>>.from(data);
        final List<String> emotions = emotionsData.map((item) => item['name'] as String).toList();
        final prefs = await SharedPreferences.getInstance();
        String emotionsJson = json.encode(emotions);
        String emotionsDataJson = json.encode(emotionsData);
        await prefs.setString('emotions', emotionsJson); 
        await prefs.setString('emotions_data', emotionsDataJson);
        // Store the fetched data in the state        
        setState(() {
          _emotionsData = emotionsData; // Store the fetched data
          _emotions.clear(); // Clear the list before adding new items
          _emotions.addAll(emotions);
          _isLoading = false; // Set loading to false after fetching data
        });
      } else {
        print('Failed to load emotions');
        _isLoading = false; // Set loading to false if there's an error
      }
    } catch (e) {
      print('Error fetching emotions: $e');
      _isLoading = false; // Set loading to false if there's an error
    }
  }

  Future<void> _fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedEmotions = prefs.getString('emotions'); 
    String? savedEmotionsData = prefs.getString('emotions_data');
    
    if (savedEmotions != null && savedEmotions.isNotEmpty && savedEmotionsData != null && savedEmotionsData.isNotEmpty) {
        List<dynamic> decoded = json.decode(savedEmotions);
      setState(() {
        _emotionsData = List<Map<String, dynamic>>.from(json.decode(savedEmotionsData));        
        _emotions.clear();
        _emotions.addAll(decoded.cast<String>());
        _isLoading = false; 
      });
    }else{
      await _fetchEmotions(); // Fetch emotions if no saved items
    }
  }

  Future<void> _checkDateUserPair() async {
    final Map<String, dynamic> payload = {
      "user_id": widget.userId,
      "date": date,
    };
    try {
        // Send the POST request
        final response = await http.post(
          Uri.parse('$baseUrl/days_emo/check'),
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

  @override
  void initState() {
    super.initState();
    _fetchItems(); // Fetch emotions when the widget is initialized
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
                    itemCount: _emotions.length,
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
                                  capitalizeFirst(_emotions[index]),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedRows.remove(index);
                                    } else {
                                      _selectedRows.add(index);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
               
                // Submit button
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      
                      CustomButton(
                        onPressed: () {
                          setState(() {
                            _selectedRows.clear(); // Clear all selected rows
                          });
                        },
                        text: 'Usuń',
                      ),
                      
                      CustomButton(
                        onPressed: () async {
                          if (_selectedRows.isEmpty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Na pewno odczuwasz jakąś emocję!'),
                                  content: const Text('Proszę, wybierz przynajmniej jedną.'),
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

                          final List<Map<String, dynamic>> selectedEmotions = _selectedRows.map((index) {
                            final emotionName = _emotions[index];
                            // Find the corresponding emotion object from the fetched data
                            final emotionData = _emotionsData.firstWhere(
                              (item) => item['name'] == emotionName,
                              orElse: () => {"sign": "unknown"}, // Default to "unknown" if not found
                            );
                            return {
                              "id": index + 1,
                              "name": emotionName,
                              "sign": emotionData["sign"], // Add the "sign" field
                            };
                          }).toList();

                                                

                          final payload = {
                            "user_id": widget.userId,
                            "date": date,
                            "emotions": selectedEmotions,
                          };
                          
                          try {
                           
                              final response = await http.put(
                                Uri.parse('$baseUrl/days_emo'),
                                headers: {"Content-Type": "application/json"},
                                body: json.encode(payload),
                              );
                              if (response.statusCode == 200 || response.statusCode == 201 )
                              {
                                showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Dzień zapisany'),
                                    content: const Text('Emocje zapisane! Iść do symptomów?'),
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
                                              builder: (context) => DailyPage(userId: widget.userId, userName: widget.userName),
                                            ),
                                          );
                                        },
                                        child: const Text('Idź'),
                                      )
                                    ],
                                  );
                                },
                              );
                              }else{
                                print("Error saving emotions: ${response.statusCode}");
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Błąd'),
                                      content: const Text('Nie udało się zapisać emocji. Spróbuj ponownie później.'),
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
                          } catch (e) {
                            print('Error saving emotions: $e');
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Błąd'),
                                  content: const Text('Nie udało się zapisać emocji. Spróbuj ponownie później.'),
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
                        },                        
                        text: 'Zapisz',
                    ),
                    ]
                  )
                  
                  
                  
                  
                ),
              ],
            ),
    );
  }
}