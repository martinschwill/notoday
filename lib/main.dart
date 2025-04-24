import 'package:flutter/material.dart';
import 'list_of_symptoms.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notoday',
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
      home: const MyHomePage(title: 'Notoday'),
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
  final List<String> _items = symptoms; // List of symptoms
  final Set<int> _selectedRows = {}; // Set to keep track of selected rows

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.lightGreenAccent, // Set a custom color for the AppBar
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedRows.contains(index); // Check if the row is selected
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Container(
              color: isSelected ? Colors.yellow : Colors.transparent, // Change background color if selected
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
    );
  }
}
