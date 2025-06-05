import 'package:flutter/material.dart';
import '../common_imports.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final AlertService _alertService = AlertService();
  late List<Alert> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = _alertService.alerts;
    
    // Listen for changes in alerts
    _alertService.alertsNotifier.addListener(_onAlertsChanged);
  }
  
  @override
  void dispose() {
    _alertService.alertsNotifier.removeListener(_onAlertsChanged);
    super.dispose();
  }
  
  void _onAlertsChanged() {
    setState(() {
      _alerts = _alertService.alerts;
    });
  }
  
  void _dismissAlert(Alert alert) {
    _alertService.dismissAlert(alert);
  }

  void _clearAllAlerts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń wszystkie powiadomienia'),
        content: const Text('Czy na pewno chcesz usunąć wszystkie powiadomienia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              _alertService.clearAllAlerts();
              Navigator.pop(context);
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context: context,
        title: 'Powiadomienia',
        actions: [
          if (_alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Usuń wszystkie',
              onPressed: _clearAllAlerts,
            ),
        ],
      ),
      body: AlertListWidget(
        alerts: _alerts,
        onDismiss: _dismissAlert,
        emptyMessage: "Brak powiadomień",
      ),
    );
  }
}
