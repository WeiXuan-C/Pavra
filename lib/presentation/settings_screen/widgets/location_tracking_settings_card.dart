import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/location_tracking_service.dart';
import '../../../core/services/nearby_issue_monitor_service.dart';
import '../../../core/services/location_tracking_integration.dart';
import '../../../core/api/user/user_api.dart';
import '../../../core/api/report_issue/report_issue_api.dart';
import '../../../core/api/notification/notification_api.dart';
import '../../../core/services/notification_helper_service.dart';

/// Location Tracking Settings Card
/// Handles location tracking preferences and status display
class LocationTrackingSettingsCard extends StatefulWidget {
  const LocationTrackingSettingsCard({super.key});

  @override
  State<LocationTrackingSettingsCard> createState() =>
      _LocationTrackingSettingsCardState();
}

class _LocationTrackingSettingsCardState
    extends State<LocationTrackingSettingsCard> {
  final LocationTrackingService _locationService = LocationTrackingService();
  final NearbyIssueMonitorService _monitorService =
      NearbyIssueMonitorService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final isTracking = _locationService.isTracking;
    final lastUpdateTime = _locationService.lastUpdateTime;
    final notifiedIssueCount = _monitorService.notifiedIssueCount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settings_locationTracking,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Location Tracking Toggle
            SwitchListTile(
              title: Text(l10n.settings_locationTracking),
              subtitle: Text(l10n.settings_locationTrackingDesc),
              value: isTracking,
              onChanged: _isLoading
                  ? null
                  : (value) async {
                      if (value) {
                        await _enableLocationTracking(context, authProvider);
                      } else {
                        await _disableLocationTracking(context, authProvider);
                      }
                    },
              contentPadding: EdgeInsets.zero,
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              ),

            const Divider(height: 24),

            // Status Indicator
            _buildStatusRow(
              context,
              l10n.settings_locationTrackingStatus,
              isTracking
                  ? l10n.settings_locationTrackingEnabled
                  : l10n.settings_locationTrackingDisabled,
              isTracking ? Colors.green : Colors.grey,
            ),

            const SizedBox(height: 12),

            // Last Update Time
            _buildStatusRow(
              context,
              l10n.settings_locationTrackingLastUpdate,
              _formatLastUpdateTime(context, lastUpdateTime),
              theme.colorScheme.onSurface.withOpacity(0.6),
            ),

            const SizedBox(height: 12),

            // Nearby Issues Count
            _buildStatusRow(
              context,
              l10n.settings_locationTrackingNearbyIssues,
              notifiedIssueCount.toString(),
              theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  String _formatLastUpdateTime(BuildContext context, DateTime? lastUpdate) {
    final l10n = AppLocalizations.of(context);

    if (lastUpdate == null) {
      return l10n.settings_locationTrackingNever;
    }

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return l10n.settings_locationTrackingJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.settings_locationTrackingMinutesAgo(difference.inMinutes);
    } else {
      return l10n.settings_locationTrackingHoursAgo(difference.inHours);
    }
  }

  Future<void> _enableLocationTracking(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final userId = authProvider.user?.id;

    if (userId == null) {
      _showErrorSnackBar(context, 'User not authenticated');
      return;
    }

    // Show permission explanation dialog
    final shouldProceed = await _showPermissionDialog(context);
    if (!shouldProceed) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize dependencies
      final notificationHelper = NotificationHelperService(NotificationApi());
      final userApi = UserApi(
        notificationHelper: notificationHelper,
      );
      final reportApi = ReportIssueApi(
        authProvider.supabaseClient,
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

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessSnackBar(
          context,
          'Location tracking enabled successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(
          context,
          l10n.settings_locationTrackingEnableError(e.toString()),
        );
      }
    }
  }

  Future<void> _disableLocationTracking(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final userId = authProvider.user?.id;

    if (userId == null) {
      _showErrorSnackBar(context, 'User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize dependencies
      final notificationHelper = NotificationHelperService(NotificationApi());
      final userApi = UserApi(
        notificationHelper: notificationHelper,
      );

      // Disable location tracking
      await disableLocationTracking(
        userId: userId,
        userApi: userApi,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessSnackBar(
          context,
          'Location tracking disabled successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(
          context,
          l10n.settings_locationTrackingDisableError(e.toString()),
        );
      }
    }
  }

  Future<bool> _showPermissionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_locationTrackingPermissionTitle),
        content: Text(l10n.settings_locationTrackingPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.common_ok),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
