import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../common_imports.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();

  Future<void> _login() async {
    final userName = _userNameController.text.trim();
    final userPassword = _userPasswordController.text.trim();

    if (userName.isNotEmpty && userPassword.isNotEmpty) {
      try {
        // Send login credentials to the backend
        final response = await http.post(
          Uri.parse('$baseUrl/login'), // Replace with your backend URL
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "user_name": userName,
            "user_password": userPassword,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final userId = (data['user_id'] as num).toInt(); // Extract user_id from the response

          if (userId != null) {
            // Navigate to the HomePage and pass the user_id
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userId: userId, userName: userName),
              ),
            );
          } else {
            _showError('Niepoprawne dane logowania');
          }
        } else {
          _showError('Nieudane logowanie: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Error: $e');
      }
    } else {
      _showError('Proszę wpisz oba username i hasło');
    }
  }

  void _showError(String message) {
    if(!mounted) return; // Check if the widget is still mounted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'NOTODAY'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Logowanie',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20.0),
            // Username TextField
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 20.0),
            // Password TextField
            TextField(
              controller: _userPasswordController,
              obscureText: true, // Hide the password input
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Hasło',
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                textStyle: const TextStyle(fontSize: 18.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text('Zaloguj'),
            ),
          ],
        ),
      ),
    );
  }
}