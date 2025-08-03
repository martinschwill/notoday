import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';


import '../common_imports.dart';

class ToolkitPage extends StatefulWidget {
  final int userId; 
  final String userName;
  
  const ToolkitPage({super.key, required this.userId, required this.userName});
  
  @override
  State<ToolkitPage> createState() => _ToolkitPageState();
}

class ToolkitItem {
  final String type;
  final String title;
  final String description;
  
  ToolkitItem({
    required this.type,
    required this.title,
    required this.description,
  });
}


class _ToolkitPageState extends State<ToolkitPage> {
  final List<ToolkitItem> _toolkitItems = [];
  final List<String> _types = ["phone", "action", "place"];
  final Map<String, String> type_dict = {
    "phone": "Telefon",
    "action": "Działanie",
    "place": "Miejsce",
  };
  
  void _showAddItemDialog() {
    String selectedType = _types.first;
    String title = '';
    String description = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Dodaj nowy element'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Typ',
                      border: OutlineInputBorder(),
                    ),
                    items: _types.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type_dict[type] ?? type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tytuł',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      title = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Opis',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      description = value;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty && description.isNotEmpty) {
                      setState(() {
                        _toolkitItems.add(ToolkitItem(
                          type: selectedType,
                          title: title,
                          description: description,
                        ));
                      });
                      _updateTools();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Dodaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _fetchTools() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/toolkit?user_id=${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _toolkitItems.clear();
          for (var item in data) {
            _toolkitItems.add(ToolkitItem(
              type: item['type'],
              title: item['title'],
              description: item['description'],
            ));
          }
        });
      } else {
        // Handle the error response
        print('Failed to load tools: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
      print('Error fetching tools: $e');
    }
  }

  Future<void> _updateTools() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/toolkit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId, 
          "item": _toolkitItems.map((item) => {
          'type': item.type,
          'title': item.title,
          'description': item.description,
        }).toList(),
        }),
      );
      if (response.statusCode == 201) {
        // Successfully updated
        print('Tools updated successfully');
      } else {
        // Handle the error response
        print('Failed to update tools: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occur during the update
      print('Error updating tools: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Extract number from the description
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''); 
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
    
    if(await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie można wykonać połączenia')),
        );
      }
    }
  }

  Future<void> _openMaps(String location) async {
    final Uri mapsUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {
        'api': '1',
        'query': location,
      },
    );
    
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie można otworzyć map')),
        );
      }
    }
  }

  void _showActionDialog(ToolkitItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(item.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleItemTap(ToolkitItem item) async {
    switch(item.type) {
      case 'phone': 
        await _makePhoneCall(item.description); 
        break; 
      
      case 'action': 
        _showActionDialog(item);
        break; 

      case 'place': 
        await _openMaps(item.description); 
        break; 
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone;
      case 'action':
        return Icons.directions_run;
      case 'place':
        return Icons.location_on;
      default:
        return Icons.help;
    }
  }
  
  Color _getColorForType(String type) {
    switch (type) {
      case 'phone':
        return Colors.blue;
      case 'action':
        return Colors.green;
      case 'place':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTools();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'NARZĘDZIA',
      ),
      endDrawer: CustomDrawer(userName: widget.userName, userId: widget.userId), 
      body: _toolkitItems.isEmpty
          ? const Center(
              child: Text(
                'Brak elementów w zestawie narzędzi.\nDodaj pierwszy element!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _toolkitItems.length,
              itemBuilder: (context, index) {
                final item = _toolkitItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    onTap: () => _handleItemTap(item), // Handle tap
                    leading: CircleAvatar(
                      backgroundColor: _getColorForType(item.type),
                      child: Icon(
                        _getIconForType(item.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type_dict[item.type] ?? item.type,
                          style: TextStyle(
                            color: _getColorForType(item.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(item.description),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _toolkitItems.removeAt(index);
                        });
                        _updateTools(); // Update the server after deletion
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}