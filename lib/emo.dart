import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class EmoPage extends StatefulWidget {
  final int userId; // Pass the user ID to this page

  const EmoPage({super.key, required this.userId});

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
        
        setState(() {
          _emotionsData = emotionsData; // Store the fetched data
          _emotions.clear(); // Clear the list before adding new items
          _emotions.addAll(_emotionsData.map((item) => item['name'] as String).toList());
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
        if (data['exists']) {
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
    _fetchEmotions(); // Fetch emotions when the widget is initialized
    _checkDateUserPair(); // Check if the user has already submitted data for today
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
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 226, 234, 236),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        'Data: $date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _emotions.length,
                    itemBuilder: (context, index) {
                      final emotion = _emotions[index];
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
                                  _emotions[index],
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
                // Display the emotions table
                // Expanded(
                //   child: ListView.builder(
                //     itemCount: _emotions.length,
                //     itemBuilder: (context, index) {
                //       final emotion = _emotions[index];
                //       final isSelected = _selectedRows.contains(index);

                //       return Center(
                //         child: ListTile(
                //           title: Center(
                //           child: Text(
                //             emotion,
                //             style: const TextStyle(
                //               fontSize: 16.0,
                //               color: Colors.black,)
                //           ),),
                //         tileColor: isSelected
                //             ? const Color.fromARGB(255, 231, 236, 143)
                //             : null,
                //         onTap: () {
                //           setState(() {
                //             if (isSelected) {
                //               _selectedRows.remove(index);
                //             } else {
                //               _selectedRows.add(index);
                //             }
                //           });
                //         },)
                        
                //       );
                //     },
                //   ),
                // ),
                // Submit button
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedRows.clear(); // Clear all selected rows
                          });
                          print('All selected rows cleared');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Adjust padding for a larger button
                          textStyle: const TextStyle(fontSize: 18.0), // Bigger font size
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0), // Match the roundness of the date background
                          ),
                        ),
                        child: const Text('Usuń'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_selectedRows.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Proszę wybierz przynajmniej jedną emocję'),
                              ),
                            );
                            return;
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
                            if(_wasFilled){
                              final response = await http.put(
                                Uri.parse('$baseUrl/days_emo'),
                                headers: {"Content-Type": "application/json"},
                                body: json.encode(payload),
                              );
                              if (response.statusCode == 200 || response.statusCode == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dane zostały zapisane pomyślnie!'),
                                ),
                              );
                            } else {
                              print('Failed to submit emotions: ${response.statusCode}');
                            }
                            }else{final response = await http.post(
                              Uri.parse('$baseUrl/days_emo'),
                              headers: {"Content-Type": "application/json"},
                              body: json.encode(payload),
                            );
                            if (response.statusCode == 200 || response.statusCode == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dane zostały zapisane pomyślnie!'),
                                ),
                              );
                            } else {
                              print('Failed to submit emotions: ${response.statusCode}');
                            }
                            }
                            
                              } catch (e) {
                            print('Error submitting emotions: $e');
                          }
                        },

                            
                      
                        
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                          textStyle: const TextStyle(fontSize: 18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        child: const Text('Zapisz'),
                  ),
                    ]
                  )
                  
                  
                  
                  
                ),
              ],
            ),
    );
  }
}