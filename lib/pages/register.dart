import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../common_imports.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    final userName = _userNameController.text.trim();
    final userPassword = _userPasswordController.text.trim();
    final userEmail = _userEmailController.text.trim();

    if (userName.isEmpty || userPassword.isEmpty || userEmail.isEmpty) {
      _showError('Proszę wpisać wszystkie pola');
      setState(() => _isLoading = false);
      return;
    }
    if (!isValidEmail(userEmail)) {
      _showError('Proszę wpisać poprawny adres email');
      setState(() => _isLoading = false);
      return;
    }
    if (userPassword.length < 8) {
      _showError('Hasło musi mieć co najmniej 8 znaków');
      setState(() => _isLoading = false);
      return;
    }
    if (userName.length < 3) {
      _showError('Nazwa użytkownika musi mieć co najmniej 3 znaki');
      setState(() => _isLoading = false);
      return;
    }

    try {

      final Map<String, dynamic> payload = {
        'user_name': userName,
        'user_password': userPassword,
        'user_email': userEmail,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload)
      );
      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Potwierdzenie rejestracji"),
              content: Text("Wysłaliśmy email potwierdzający rejestrację na adres: $userEmail"),
              actions: [
                TextButton(
                  onPressed: () =>
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        
        
      } else if (response.statusCode == 401) {
        // String res = "Uzytkownik o podanym adresie email lub nazwa użytkownika już istnieje";
        _showError('Użytkownik o podanym adresie email lub nazwa użytkownika już istnieje');
      }
    } catch (e) {
      _showError('Błąd: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'NOTODAY'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Rejestracja',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _userPasswordController,
              obscureText: true, // Hide the password input
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Hasło',
              ),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _userEmailController,
                decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Zarejestruj'),
            ),
          ],
        ),
      ),
    );
  }
}