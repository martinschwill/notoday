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
  final Set<int> _selectedRows = {}; // Set to keep track of selected rows
  final String date = DateTime.now().toLocal().toString().split(' ')[0]; // Format: YYYY-MM-DD
  bool _isLoading = true; // Flag to track loading state
  bool _wasFilled = false; // Flag to check if data was already submitted

  Future<void> _fetchEmotions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/emo'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(data) ; // Print the fetched data for debugging
        setState(() {
          _emotions.clear(); // Clear the list before adding new items
          _emotions.addAll(data.map((item) => item['name'] as String).toList());
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
      final response = await http.post(Uri.parse('$baseUrl/days_emo/check'), 
          headers: {"Content-Type": "application/json"},
          body: json.encode(payload));
      if (response.statusCode == 200) {
        setState(() {
          _wasFilled = true; // Mark as already filled
        });
      } else {
        _wasFilled = false; // Not filled yet
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
                // Display the emotions table
                Expanded(
                  child: ListView.builder(
                    itemCount: _emotions.length,
                    itemBuilder: (context, index) {
                      final emotion = _emotions[index];
                      final isSelected = _selectedRows.contains(index);

                      return Center(
                        child: ListTile(
                          title: Center(
                          child: Text(
                            emotion,
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,)
                          ),),
                        tileColor: isSelected
                            ? const Color.fromARGB(255, 231, 236, 143)
                            : null,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedRows.remove(index);
                            } else {
                              _selectedRows.add(index);
                            }
                          });
                        },)
                        
                      );
                    },
                  ),
                ),
                // Submit button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_selectedRows.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Proszę wybierz przynajmniej jedną emocję'),
                          ),
                        );
                        return;
                      }

                      final selectedEmotions =
                          _selectedRows.map((index) => _emotions[index]).toList();

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
                ),
              ],
            ),
    );
  }
}