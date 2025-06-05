import 'package:flutter/material.dart';
import '../common_imports.dart';

class SettingsPage extends StatefulWidget {
  final String userName;
  final int userId;
  
  const SettingsPage({
    Key? key,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AlertService _alertService = AlertService();
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // Load notification settings from AlertService
    final enabled = await _alertService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _createTestAlert() async {
    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generowanie testowego powiadomienia...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Create the test alert with notification
    await _alertService.createTestAlert(delay: const Duration(seconds: 10));
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Powiadomienie testowe zostanie wyświetlone za 10 sekund'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context: context,
        title: 'Ustawienia',
      ),
      endDrawer: CustomDrawer(userName: widget.userName, userId: widget.userId),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Notifications section
          _buildSectionHeader('Powiadomienia'),
          SwitchListTile(
            title: const Text('Włącz powiadomienia'),
            subtitle: const Text('Otrzymuj powiadomienia o niepokojących trendach'),
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              await _alertService.setNotificationsEnabled(value);
            },
          ),
          const Divider(),
          
          // Test notifications
          ListTile(
            title: const Text('Testowe powiadomienie'),
            subtitle: const Text('Wygeneruj powiadomienie testowe'),
            trailing: const Icon(Icons.notification_add),
            onTap: _createTestAlert,
          ),
          
          const Divider(),
          
          // Alert settings section
          _buildSectionHeader('Ustawienia alertów'),
          ListTile(
            title: const Text('Zarządzaj alertami'),
            subtitle: const Text('Zobacz i edytuj aktualne alerty'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsPage()),
              );
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
