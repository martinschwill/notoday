import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../common_imports.dart';

class EmotionsTabContent extends StatefulWidget {
  final List<Map<String, dynamic>> selectedEmotions;
  final Function(Map<String, dynamic>) onEmotionToggle;

  const EmotionsTabContent({
    super.key,
    required this.selectedEmotions,
    required this.onEmotionToggle,
  });

  @override
  State<EmotionsTabContent> createState() => _EmotionsTabContentState();
}

class _EmotionsTabContentState extends State<EmotionsTabContent> {
  final List<String> _emotions = []; // List to store emotions (matching emo.dart)
  List<Map<String, dynamic>> _emotionsData = []; // List to store emotions data (matching emo.dart)
  final Set<int> _selectedRows = {}; // Set to keep track of selected rows (matching emo.dart)
  bool _isLoading = true; // Flag to track loading state

  @override
  void initState() {
    super.initState();
    _fetchItems(); // loads emotions or fetches them from the API (matching emo.dart)
    _syncWithParentState(); // Sync with parent's selected emotions
  }

  // Sync the local selected rows with parent's selected emotions
  void _syncWithParentState() {
    setState(() {
      _selectedRows.clear();
      for (var emotion in widget.selectedEmotions) {
        // Find the index of this emotion in _emotions
        final name = emotion['name'] ?? '';
        final index = _emotions.indexWhere((item) => item == name);
        if (index >= 0) {
          _selectedRows.add(index);
        }
      }
    });
  }

  Future<void> _fetchEmotions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/emo'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Explicitly cast the data to List<Map<String, dynamic>> (matching emo.dart)
        final List<Map<String, dynamic>> emotionsData = List<Map<String, dynamic>>.from(data);
        final List<String> emotions = emotionsData.map((item) => item['name'] as String).toList();
        final prefs = await SharedPreferences.getInstance();
        String emotionsJson = json.encode(emotions);
        String emotionsDataJson = json.encode(emotionsData);
        await prefs.setString('emotions', emotionsJson); 
        await prefs.setString('emotions_data', emotionsDataJson);
        // Store the fetched data in the state (matching emo.dart)
        setState(() {
          _emotionsData = emotionsData; // Store the fetched data
          _emotions.clear(); // Clear the list before adding new items
          _emotions.addAll(emotions);
          _isLoading = false; // Set loading to false after fetching data
        });
        _syncWithParentState(); // Sync after loading items
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
      _syncWithParentState(); // Sync after loading items
    } else {
      await _fetchEmotions(); // Fetch emotions if no saved items (matching emo.dart)
    }
  }

  void _onPlusButtonPressed(int index) {
    setState(() {
      // Toggle the selection state of the row (matching emo.dart logic)
      if (_selectedRows.contains(index)) {
        _selectedRows.remove(index); // Deselect if already selected
      } else {
        _selectedRows.add(index); // Select if not selected
      }
    });

    // Notify parent of the change (matching emo.dart structure)
    final emotionName = _emotions[index];
    // Find the corresponding emotion object from the fetched data
    final emotionData = _emotionsData.firstWhere(
      (item) => item['name'] == emotionName,
      orElse: () => {"sign": "unknown"}, // Default to "unknown" if not found
    );
    final emotion = {
      "id": index + 1,
      "name": emotionName,
      "sign": emotionData["sign"], // Add the "sign" field
    };
    widget.onEmotionToggle(emotion);
  }

  void _clearAllSelections() {
    setState(() {
      _selectedRows.clear(); // Clear all selected rows (matching emo.dart)
    });
    
    // Clear parent state as well
    for (var emotion in List.from(widget.selectedEmotions)) {
      widget.onEmotionToggle(emotion);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Main content area matching emo.dart layout
        Expanded(
          child: ListView.builder(
            itemCount: _emotions.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedRows.contains(index);
              return Padding(
                padding: const EdgeInsets.fromLTRB(60.0, 10.0, 40.0, 10.0), // Matching emo.dart padding
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0), // Matching emo.dart padding
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromARGB(255, 247, 239, 162) // Matching emo.dart selection color
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.0), // Matching emo.dart border radius
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          capitalizeFirst(_emotions[index]), // Using capitalizeFirst like emo.dart
                          style: Theme.of(context).textTheme.bodyLarge, // Matching emo.dart text style
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add), // Matching emo.dart icon
                        onPressed: () => _onPlusButtonPressed(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bottom button area matching emo.dart
        Padding(
          padding: const EdgeInsets.all(32.0), // Matching emo.dart padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align buttons on opposite sides
            children: [
              // Clear Button (matching emo.dart)
              CustomButton(
                onPressed: _clearAllSelections,
                text: 'Usuń', 
              ),
              
              // Info text showing selected count
              Text(
                'Wybrano: ${_selectedRows.length}',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}