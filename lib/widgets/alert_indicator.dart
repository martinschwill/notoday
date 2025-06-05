import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../pages/alerts_page.dart';

/// A widget that displays an alert icon with a badge if there are alerts
class AlertIndicator extends StatefulWidget {
  final Color? color;
  final double size;
  
  const AlertIndicator({
    Key? key,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  State<AlertIndicator> createState() => _AlertIndicatorState();
}

class _AlertIndicatorState extends State<AlertIndicator> {
  final AlertService _alertService = AlertService();
  int _alertCount = 0;
  
  @override
  void initState() {
    super.initState();
    _updateAlertCount();
    
    // Listen for changes in alerts
    _alertService.alertsNotifier.addListener(_updateAlertCount);
  }
  
  @override
  void dispose() {
    _alertService.alertsNotifier.removeListener(_updateAlertCount);
    super.dispose();
  }
  
  void _updateAlertCount() {
    setState(() {
      _alertCount = _alertService.alerts.length;
    });
  }
  
  void _navigateToAlertsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlertsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: _navigateToAlertsPage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications,
            color: widget.color ?? Theme.of(context).iconTheme.color,
            size: widget.size,
          ),
          if (_alertCount > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _alertCount > 9 ? '9+' : _alertCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
