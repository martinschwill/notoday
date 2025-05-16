import 'package:flutter/material.dart';

import '../common_imports.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onAccount;
  final String? userName;

  const CustomDrawer({super.key, this.onLogout, this.onAccount, this.userName});

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
          const Spacer(),
          SafeArea(
            minimum: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Wyloguj'),
              onTap: onLogout ?? () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}