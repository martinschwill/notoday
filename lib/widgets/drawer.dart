import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../common_imports.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onAccount;
  final String userName;
  final int userId; 

  const CustomDrawer({super.key, this.onLogout, this.onAccount, required this.userName, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          SafeArea(
            minimum: const EdgeInsets.only(left:20, top: 20, right: 20),
            maintainBottomViewPadding: true,
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text('$userName'),
              onTap: onAccount ?? () {
                showDialog(
                  context: context, 
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Konto'),
                      content: Text('User: $userName'),
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
            ),
          ),
          const Divider(),
          SafeArea(
            minimum: const EdgeInsets.only(left: 20, right: 20),
            top: false,
            bottom: false,
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      userId: userId,
                      userName: userName,
                      wasOpened: true, 
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.only(left: 20, right: 20),
            top: false,
            bottom: false,
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Powiadomienia'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlertsPage()),
                );
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.only(left: 20, right: 20),
            top: false,
            bottom: false,
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ustawienia'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage(
                    userName: userName,
                    userId: userId,
                  )),
                );
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.only(left: 20, right: 20),
            top: false,
            bottom: false,
            child: ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Pomoc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
            ),
          ),
          const Spacer(),
          SafeArea(
            minimum: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Wyloguj'),
              onTap: onLogout ?? () {
                final storage = const FlutterSecureStorage();
                storage.delete(key: 'user_id');
                storage.delete(key: 'user_name');
                storage.delete(key: 'user_password');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}