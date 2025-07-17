import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common_imports.dart';

class DiaryEmotionsPage extends StatefulWidget {
  final int userId;
  final String userName;

  const DiaryEmotionsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DiaryEmotionsPage> createState() => _DiaryEmotionsPageState();
}

class _DiaryEmotionsPageState extends State<DiaryEmotionsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Shared state for both pages
  List<Map<String, dynamic>> _selectedSymptoms = [];
  List<Map<String, dynamic>> _selectedEmotions = [];
  bool _isLoading = false;
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchExistingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch existing symptoms and emotions for the selected date
      final response = await http.get(
        Uri.parse('$baseUrl/entries?user_id=${widget.userId}&date=$_selectedDate'),
      );
      print(response.body); // Debugging line to check response body
      print(Uri.parse('$baseUrl/entries?user_id=${widget.userId}&date=$_selectedDate')); 
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedSymptoms = List<Map<String, dynamic>>.from(
            data['symptoms'] ?? []
          );
          _selectedEmotions = List<Map<String, dynamic>>.from(
            data['emotions'] ?? []
          );
        });
      }
      print(response.body); 
      print(response.statusCode); // Debugging line to check response status
    } catch (e) {
      print('Error fetching existing data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveData() async {
    setState(() {
      _isLoading = true;
    });
    
    if (_selectedSymptoms.isEmpty && _selectedEmotions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proszę wybrać co najmniej jeden objaw lub emocję.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }else{
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/entries'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': widget.userId,
            'date': _selectedDate,
            'symptoms': _selectedSymptoms,
            'emotions': _selectedEmotions,
          }),
        );
        print(response.body); 
        print(response.statusCode); // Debugging line to check response status
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dane zostały zapisane pomyślnie!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Record user activity for alert system
          await UserMetricsService().recordActivity();
        } else {
          throw Exception('Failed to save data');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
    }

    

  void _onSymptomToggle(Map<String, dynamic> symptom) {
    setState(() {
      final index = _selectedSymptoms.indexWhere(
        (s) => s['id'] == symptom['id']
      );
      
      if (index >= 0) {
        _selectedSymptoms.removeAt(index);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  void _onEmotionToggle(Map<String, dynamic> emotion) {
    setState(() {
      final index = _selectedEmotions.indexWhere(
        (e) => e['id'] == emotion['id']
      );
      
      if (index >= 0) {
        _selectedEmotions.removeAt(index);
      } else {
        _selectedEmotions.add(emotion);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
         title: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('NOTODAY'),
                    content: const Text('ver 0.9.0'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(
            textAlign: TextAlign.center,
            "DZIENNIK",
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w600,
              fontFamily: 'Courier New',
              color: Color.fromARGB(255, 117, 151, 167),
            ),
          ),
          ),
          
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.local_hospital),
              text: 'Ojawy',
            ),
            Tab(
              icon: Icon(Icons.mood),
              text: 'Emocje',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Diary/Symptoms Tab
                      _buildSymptomsTab(),
                      // Emotions Tab
                      _buildEmotionsTab(),
                    ],
                  ),
                ),
                // Save button at the bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 18.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Zapisz'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSymptomsTab() {
    return DiaryTabContent(
      selectedSymptoms: _selectedSymptoms,
      onSymptomToggle: _onSymptomToggle,
    );
  }

  Widget _buildEmotionsTab() {
    return EmotionsTabContent(
      selectedEmotions: _selectedEmotions,
      onEmotionToggle: _onEmotionToggle,
    );
  }
}