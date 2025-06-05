import 'package:flutter/material.dart';
import '../modules/alerting.dart';

/// Widget to display an alert in the UI
class AlertWidget extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onDismiss;
  
  const AlertWidget({
    Key? key,
    required this.alert,
    this.onDismiss,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        color: Colors.red,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(0.0, 0.0, 20.0, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      onDismissed: (direction) {
        if (onDismiss != null) {
          onDismiss!();
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: _getAlertColor().withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _getAlertColor(),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: alert.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  _getAlertIcon(),
                  color: _getAlertColor(),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(alert.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getAlertColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }
  
  IconData _getAlertIcon() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Icons.warning_amber_rounded;
      case AlertSeverity.warning:
        return Icons.warning_outlined;
      case AlertSeverity.info:
        return Icons.info_outline;
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

/// Widget to display a list of alerts
class AlertListWidget extends StatelessWidget {
  final List<Alert> alerts;
  final Function(Alert) onDismiss;
  final String emptyMessage;
  
  const AlertListWidget({
    Key? key,
    required this.alerts,
    required this.onDismiss,
    this.emptyMessage = "No alerts at the moment",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        return AlertWidget(
          alert: alerts[index],
          onDismiss: () => onDismiss(alerts[index]),
        );
      },
    );
  }
}
