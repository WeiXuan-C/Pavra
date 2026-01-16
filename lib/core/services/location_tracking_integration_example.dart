/// Example usage of location tracking integration functions
/// 
/// This file demonstrates how to use enableLocationTracking and disableLocationTracking
/// in your Flutter application.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/user/user_api.dart';
import '../api/report_issue/report_issue_api.dart';
import '../api/notification/notification_api.dart';
import 'location_tracking_integration.dart';
import 'notification_helper_service.dart';

/// Example: Enable location tracking when user toggles a switch
/// 
/// This would typically be called from a settings screen or profile screen
Future<void> exampleEnableLocationTracking(BuildContext context, String userId) async {
  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Initialize required services
    final supabase = Supabase.instance.client;
    final userApi = UserApi();
    final notificationApi = NotificationApi();
    final notificationHelper = NotificationHelperService(notificationApi);
    final reportApi = ReportIssueApi(
      supabase,
      notificationHelper: notificationHelper,
      userApi: userApi,
    );

    // Enable location tracking
    await enableLocationTracking(
      userId: userId,
      userApi: userApi,
      reportApi: reportApi,
      notificationHelper: notificationHelper,
    );

    // Hide loading indicator
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location tracking enabled'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    // Hide loading indicator
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enable location tracking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Example: Disable location tracking when user toggles a switch
/// 
/// This would typically be called from a settings screen or profile screen
Future<void> exampleDisableLocationTracking(BuildContext context, String userId) async {
  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Initialize required services
    final userApi = UserApi();

    // Disable location tracking
    await disableLocationTracking(
      userId: userId,
      userApi: userApi,
    );

    // Hide loading indicator
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location tracking disabled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    // Hide loading indicator
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disable location tracking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Example: Location tracking toggle widget
/// 
/// This demonstrates a complete UI component for toggling location tracking
class LocationTrackingToggle extends StatefulWidget {
  final String userId;
  final bool initialValue;

  const LocationTrackingToggle({
    super.key,
    required this.userId,
    required this.initialValue,
  });

  @override
  State<LocationTrackingToggle> createState() => _LocationTrackingToggleState();
}

class _LocationTrackingToggleState extends State<LocationTrackingToggle> {
  late bool _isEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialValue;
  }

  Future<void> _toggleLocationTracking(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (value) {
        await exampleEnableLocationTracking(context, widget.userId);
      } else {
        await exampleDisableLocationTracking(context, widget.userId);
      }

      setState(() {
        _isEnabled = value;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: const Text('Location Tracking'),
      subtitle: const Text('Enable proximity alerts for nearby road issues'),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _isEnabled,
              onChanged: _toggleLocationTracking,
            ),
    );
  }
}
