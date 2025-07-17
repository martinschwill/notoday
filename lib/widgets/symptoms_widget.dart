import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../common_imports.dart';

class DiaryTabContent extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSymptoms;
  final Function(Map<String, dynamic>) onSymptomToggle;

  const DiaryTabContent({
    super.key,
    required this.selectedSymptoms,
    required this.onSymptomToggle,
  });

  @override
  State<DiaryTabContent> createState() => _DiaryTabContentState();
}

class _DiaryTabContentState extends State<DiaryTabContent> {
  final List<String> _items = []; // List to store symptoms (matching daily.dart)
  final Set<int> _selectedRows = {}; // Set to keep track of selected rows (matching daily.dart)
  bool _isLoading = true; // Flag to track loading state

  @override
  void initState() {
    super.initState();
    _fetchItems(); // loads symptoms or fetches them from the API (matching daily.dart)
    _syncWithParentState(); // Sync with parent's selected symptoms
  }

  // Sync the local selected rows with parent's selected symptoms
  void _syncWithParentState() {
    setState(() {
      _selectedRows.clear();
      for (var symptom in widget.selectedSymptoms) {
        // Find the index of this symptom in _items
        final name = symptom['name'] ?? '';
        final index = _items.indexWhere((item) => item == name);
        if (index >= 0) {
          _selectedRows.add(index);
        }
      }
    });
  }

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
        _syncWithParentState(); // Sync after loading items
      } else {
        print('Failed to load symptoms');
        _isLoading = false; // Set loading to false if there's an error
      }
    } catch (e) {
      print('Error fetching symptoms: $e');
      _isLoading = false; // Set loading to false if there's an error
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
      _syncWithParentState(); // Sync after loading items
    } else {
      await _fetchSymptoms(); // Only fetch if not found in prefs
    }
  }

  void _onPlusButtonPressed(int index) {
    setState(() {
      // Toggle the selection state of the row (matching daily.dart logic)
      if (_selectedRows.contains(index)) {
        _selectedRows.remove(index); // Deselect if already selected
      } else {
        _selectedRows.add(index); // Select if not selected
      }
    });

    // Notify parent of the change
    final symptom = {
      "id": index + 1, 
      "name": _items[index]
    };
    widget.onSymptomToggle(symptom);
  }

  void _clearAllSelections() {
    setState(() {
      _selectedRows.clear(); // Clear all selected rows (matching daily.dart)
    });
    
    // Clear parent state as well
    for (var symptom in List.from(widget.selectedSymptoms)) {
      widget.onSymptomToggle(symptom);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Main content area matching daily.dart layout
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedRows.contains(index);
              return Padding(
                padding: const EdgeInsets.fromLTRB(60.0, 10.0, 40.0, 10.0), // Matching daily.dart padding
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0), // Matching daily.dart padding
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromARGB(255, 247, 239, 162) // Matching daily.dart selection color
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.0), // Matching daily.dart border radius
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _items[index],
                          style: Theme.of(context).textTheme.bodyLarge, // Matching daily.dart text style
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add), // Matching daily.dart icon
                        onPressed: () => _onPlusButtonPressed(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bottom button area matching daily.dart
        Padding(
          padding: const EdgeInsets.all(32.0), // Matching daily.dart padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align buttons on opposite sides
            children: [
              // Clear Button (matching daily.dart)
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