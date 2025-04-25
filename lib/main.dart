import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTODAY',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
      ),
      home: const MyHomePage(title: 'NOTODAY'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> _items = []; // List to store symptoms
  final Set<int> _selectedRows = {}; // Set to keep track of selected rows
  bool _isLoading = true; // Flag to track loading state

  Future<void> _fetchSymptoms() async {
  try {    
      final response = await http.get(Uri.parse('http://192.168.33.12:5001/symptoms'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
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
    _fetchSymptoms(); // Fetch symptoms when the widget is initialized
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 22.0, // Set the font size for the title
            fontWeight: FontWeight.bold, // Set the font weight for the title
            fontFamily: 'Courier New',
            color: Colors.blueGrey,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 185, 250, 110), // Set a custom color for the AppBar
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(),)
      
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
                    'Data: ${DateTime.now().toLocal().toString().split(' ')[0]}', // Format: YYYY-MM-DD
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              ),
              ), 
            ),
          Expanded(child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedRows.contains(index); // Check if the row is selected
            return Padding(
              padding: const EdgeInsets.fromLTRB(60.0, 10.0, 40.0, 10.0),
              child: Container(
                  padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                  decoration: BoxDecoration(
                      color: isSelected ? const Color.fromARGB(255, 247, 239, 162) : Colors.transparent, // Change background color if selected
                      borderRadius: BorderRadius.circular(10.0), // Rounded edges
                  ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _items[index],
                        style: Theme.of(context).textTheme.bodyLarge,
                        softWrap: true, // Allow text to wrap,
                        overflow: TextOverflow.visible, // Show overflow text
                      ),
                    ),
                    
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _onPlusButtonPressed(index),
                  ),
                ],
              ),
            ));
          },
        ),
        ),
      Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align buttons on opposite sides
          children: [
            // Clear Button
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
            // Dodaj Button
            ElevatedButton(
              onPressed: () {
                if (_selectedRows.isEmpty) {
                  // Show a popup if no rows are selected
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Pusto...'),
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
                            onPressed: () {
                              int rowsCount = _selectedRows.length;
                              print('$rowsCount selected rows added'); // Execute the "else" clause
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('Ok'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Proceed with the action if rows are selected
                  int rowsCount = _selectedRows.length;
                  print('$rowsCount selected rows added');
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Adjust padding for a larger button
                textStyle: const TextStyle(fontSize: 18.0), // Bigger font size
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0), // Match the roundness of the date background
                ),
              ),
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),]
    
    ));
  }
}
