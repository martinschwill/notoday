import 'package:flutter/material.dart';
import 'alert_indicator.dart';

/// Helper function to build a consistent app bar throughout the app
AppBar buildAppBar({
  required BuildContext context, 
  required String title,
  List<Widget>? actions,
  bool showAlertIndicator = true,
}) {
  final List<Widget> allActions = [...?actions];
  
  // Add alert indicator if required
  if (showAlertIndicator) {
    allActions.insert(
      0, 
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: AlertIndicator(
          color: Colors.white,
        ),
      )
    );
  }
  
  return AppBar(
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
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.w600,
          fontFamily: 'Courier New',
          color: Color.fromARGB(255, 117, 151, 167),
        ),
      ),
    ),
    backgroundColor: const Color.fromARGB(255, 71, 0, 119),
    actions: allActions,
  );
}
