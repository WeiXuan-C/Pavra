import 'dart:async';
import 'dart:developer' as developer;
import '../api/report_issue/report_issue_api.dart';
import 'notification_helper_service.dart';
import 'location_tracking_service.dart';

/// Service for monitoring nearby critical road issues and sending proximity alerts
/// 
/// This service periodically checks for high/critical severity issues near the user's
/// current location and sends notifications. It maintains a cache of notified issues
/// to prevent duplicate alerts.
/// 
/// Uses singleton pattern to ensure only one monitoring instance is active.
class NearbyIssueMonitorService {
  // Singleton instance
  static final NearbyIssueMonitorService _instance = NearbyIssueMonitorService._internal();
  
  /// Factory constructor returns singleton instance
  factory NearbyIssueMonitorService() => _instance;
  
  /// Private constructor for singleton pattern
  NearbyIssueMonitorService._internal();

  // Dependencies
  final LocationTrackingService _locationService = LocationTrackingService();
  ReportIssueApi? _reportApi;
  NotificationHelperService? _notificationHelper;
  
  // State management
  Timer? _monitorTimer;
  bool _isMonitoring = false;
  
  // Configuration constants - Check interval (2 minutes)
  static const Duration _checkInterval = Duration(minutes: 2);
  
  // Configuration constants - Alert radius (5 km)
  static const double _alertRadiusKm = 5.0;
  
  // Track notified issues to avoid duplicate notifications
  final Set<String> _notifiedIssueIds = {};

  /// Whether monitoring is currently active
  bool get isMonitoring => _isMonitoring;
  
  /// Number of issues in the notified cache
  int get notifiedIssueCount => _notifiedIssueIds.length;

  /// Initialize with required dependencies
  /// 
  /// Must be called before startMonitoring()
  /// 
  /// [reportApi] - API for searching nearby issues
  /// [notificationHelper] - Service for sending notifications
  void initialize({
    required ReportIssueApi reportApi,
    required NotificationHelperService notificationHelper,
  }) {
    _reportApi = reportApi;
    _notificationHelper = notificationHelper;
    
    developer.log(
      'NearbyIssueMonitorService initialized',
      name: 'NearbyIssueMonitorService',
    );
  }

  /// Start monitoring for nearby issues
  /// 
  /// Creates a periodic timer that checks for critical issues every 2 minutes.
  /// Performs an immediate check when started.
  /// 
  /// Throws [Exception] if not initialized
  Future<void> startMonitoring() async {
    // Check initialization
    if (_reportApi == null || _notificationHelper == null) {
      throw Exception(
        'NearbyIssueMonitorService not initialized. Call initialize() before startMonitoring().'
      );
    }

    // Don't start if already monitoring
    if (_isMonitoring) {
      developer.log(
        'Monitoring already active, skipping start',
        name: 'NearbyIssueMonitorService',
      );
      return;
    }

    // Create periodic timer with 2-minute interval
    _monitorTimer = Timer.periodic(_checkInterval, (timer) {
      _checkNearbyIssues();
    });

    // Set monitoring flag
    _isMonitoring = true;

    developer.log(
      'Nearby issue monitoring started (check interval: ${_checkInterval.inMinutes} minutes)',
      name: 'NearbyIssueMonitorService',
    );

    // Perform immediate proximity check
    await _checkNearbyIssues();
  }

  /// Check for nearby issues and send notifications
  /// 
  /// This method:
  /// 1. Gets last position from LocationTrackingService
  /// 2. Searches for issues within 5km radius
  /// 3. Filters for high/critical severity
  /// 4. Excludes issues already in notified cache
  /// 5. Sends notifications for each new critical issue
  /// 6. Adds issue IDs to notified cache
  Future<void> _checkNearbyIssues() async {
    try {
      // Get last position from LocationTrackingService
      final position = _locationService.lastPosition;
      
      // Handle no position case
      if (position == null) {
        developer.log(
          'No location available for nearby issue check',
          name: 'NearbyIssueMonitorService',
        );
        return;
      }

      developer.log(
        'Checking for nearby issues at (${position.latitude}, ${position.longitude})',
        name: 'NearbyIssueMonitorService',
      );

      // Search for nearby issues within 5km radius
      final nearbyIssues = await _reportApi!.searchNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _alertRadiusKm,
        limit: 20,
      );

      // Filter for high/critical severity issues that haven't been notified
      final criticalIssues = nearbyIssues.where((issue) {
        final isHighSeverity = issue.severity == 'high' || issue.severity == 'critical';
        final notYetNotified = !_notifiedIssueIds.contains(issue.id);
        return isHighSeverity && notYetNotified;
      }).toList();

      // Handle no new critical issues
      if (criticalIssues.isEmpty) {
        developer.log(
          'No new critical issues nearby',
          name: 'NearbyIssueMonitorService',
        );
        return;
      }

      developer.log(
        'Found ${criticalIssues.length} new critical issues nearby',
        name: 'NearbyIssueMonitorService',
      );

      // Send notifications for each critical issue
      for (final issue in criticalIssues) {
        try {
          // Get current user ID for notification
          final userId = _reportApi!.getCurrentUserId();
          if (userId == null) {
            developer.log(
              'No current user ID, skipping notification for issue ${issue.id}',
              name: 'NearbyIssueMonitorService',
            );
            continue;
          }

          // Send notification
          await _notificationHelper!.notifyNearbyUsers(
            reportId: issue.id,
            title: issue.title ?? 'Road Issue',
            latitude: issue.latitude!,
            longitude: issue.longitude!,
            severity: issue.severity,
            nearbyUserIds: [userId],
          );
          
          // Add issue ID to notified cache
          _notifiedIssueIds.add(issue.id);
          
          developer.log(
            'Sent notification for issue: ${issue.id}',
            name: 'NearbyIssueMonitorService',
          );
        } catch (e, stackTrace) {
          // Log error but continue processing other issues
          developer.log(
            'Failed to send notification for issue ${issue.id}',
            name: 'NearbyIssueMonitorService',
            error: e,
            stackTrace: stackTrace,
            level: 1000, // ERROR level
          );
        }
      }
    } catch (e, stackTrace) {
      // Log error but don't throw - monitoring failures shouldn't crash the app
      developer.log(
        'Error checking nearby issues',
        name: 'NearbyIssueMonitorService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR level
      );
    }
  }

  /// Stop monitoring
  /// 
  /// Cancels the periodic timer and clears the notified issues cache
  void stopMonitoring() {
    // Cancel periodic timer
    _monitorTimer?.cancel();
    _monitorTimer = null;
    
    // Clear notified issues cache
    _notifiedIssueIds.clear();
    
    // Set monitoring flag to false
    _isMonitoring = false;
    
    developer.log(
      'Nearby issue monitoring stopped',
      name: 'NearbyIssueMonitorService',
    );
  }

  /// Clear notified issues cache
  /// 
  /// Call this when user moves significantly to allow re-notification
  /// of issues they may encounter again
  void clearNotifiedCache() {
    _notifiedIssueIds.clear();
    
    developer.log(
      'Notified issues cache cleared',
      name: 'NearbyIssueMonitorService',
    );
  }
}
