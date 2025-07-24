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
    if (mounted) {
      // Defer setState to avoid calling it during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _alertCount = _alertService.alerts.length;
            debugPrint('Alert count updated to: $_alertCount');
          });
        }
      });
    }
  }
  
  void _navigateToAlertsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlertsPage()),
    );
    
    // Update alert count after returning from alerts page
    if (mounted) {
      debugPrint('Returning from alerts page, refreshing count...');
      _updateAlertCount();
    }
  }
  
  /// Debug method to force immediate notification testing
  void _debugForceImmediateNotifications() async {
    debugPrint('=== FORCING IMMEDIATE NOTIFICATIONS ===');
    
    // First, check current alert count
    debugPrint('Current alerts before: ${_alertService.alerts.length}');
    
    // Force creation of alerts with immediate notifications
    await _alertService.createAndShowImmediateAlert();
    
    // Check alert count after
    debugPrint('Current alerts after: ${_alertService.alerts.length}');
    
    // Force UI update
    _updateAlertCount();
    
    debugPrint('=== END FORCE IMMEDIATE ===');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _debugForceImmediateNotifications, // Add debug trigger
      child: InkWell(
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
      ),
    );
  }
}
