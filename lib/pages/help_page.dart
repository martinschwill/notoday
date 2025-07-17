import 'package:flutter/material.dart'; 
import '../common_imports.dart'; 

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'POMOC'), 
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Jak korzystać z aplikacji Notoday',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '1. Rejestracja i logowanie\n'
              '   - Aby rozpocząć, zarejestruj się lub zaloguj do swojego konta.\n'
              '2. Dodawanie notatek\n'
              '   - Użyj przycisku „Dodaj notatkę”, aby utworzyć nową notatkę.\n'
              '3. Przeglądanie notatek\n'
              '   - Wszystkie Twoje notatki są dostępne na stronie głównej.\n',
            ),
          ],
        ),
      ),
    );
  }
}