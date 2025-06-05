import 'package:flutter/material.dart';
import '../common_imports.dart';

/// Extension methods for HomePage to integrate with the alerting system
extension HomePageAlerts on StatefulWidget {
  /// Run alert checks based on current data
  Future<void> runAlertChecks(BuildContext context) async {
    try {
      final metricsService = UserMetricsService();
      await metricsService.runAlertChecks();
    } catch (e) {
      debugPrint('Error running alert checks: $e');
    }
  }
  
  /// Show a bottom sheet with the latest alerts
  void showAlertsSummary(BuildContext context) {
    final alertService = AlertService();
    final alerts = alertService.alerts;
    
    if (alerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak powiadomień'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Show the most critical alerts in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text(
                        'Powiadomienia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AlertsPage()),
                          );
                        },
                        child: const Text('Zobacz wszystkie'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: alerts.length < 3 ? alerts.length : 3,
                    itemBuilder: (context, index) {
                      return AlertWidget(
                        alert: alerts[index],
                        onDismiss: () {
                          alertService.dismissAlert(alerts[index]);
                          if (alerts.isEmpty) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
