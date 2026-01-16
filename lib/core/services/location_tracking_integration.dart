import 'dart:developer' as developer;
import '../api/user/user_api.dart';
import '../api/report_issue/report_issue_api.dart';
import 'location_tracking_service.dart';
import 'nearby_issue_monitor_service.dart';
import 'notification_helper_service.dart';

/// Application integration functions for location tracking and proximity monitoring
/// 
/// These functions provide a high-level API for enabling/disabling location tracking
/// and coordinate the interaction between LocationTrackingService, NearbyIssueMonitorService,
/// and the database.

/// Enable location tracking and proximity monitoring
/// 
/// This function:
/// 1. Updates location_tracking_enabled to TRUE in the database
/// 2. Starts LocationTrackingService with callbacks for position updates
/// 3. Starts NearbyIssueMonitorService for proximity alerts
/// 
/// [userId] - The ID of the user enabling location tracking
/// [userApi] - UserApi instance for database operations
/// [reportApi] - ReportIssueApi instance for searching nearby issues
/// [notificationHelper] - NotificationHelperService for sending notifications
/// [locationService] - LocationTrackingService instance (defaults to singleton)
/// [nearbyIssueMonitor] - NearbyIssueMonitorService instance (defaults to singleton)
/// 
/// Throws [Exception] if location permission is denied or services fail to start
Future<void> enableLocationTracking({
  required String userId,
  required UserApi userApi,
  required ReportIssueApi reportApi,
  required NotificationHelperService notificationHelper,
  LocationTrackingService? locationService,
  NearbyIssueMonitorService? nearbyIssueMonitor,
}) async {
  try {
    developer.log(
      'Enabling location tracking for user $userId',
      name: 'LocationTrackingIntegration',
    );

    // Use provided services or default to singletons
    final locService = locationService ?? LocationTrackingService();
    final monitorService = nearbyIssueMonitor ?? NearbyIssueMonitorService();

    // Step 1: Update location_tracking_enabled to TRUE in database
    await userApi.setLocationTrackingEnabled(
      userId: userId,
      enabled: true,
    );

    developer.log(
      'Database updated: location_tracking_enabled = TRUE',
      name: 'LocationTrackingIntegration',
    );

    // Step 2: Start LocationTrackingService with callbacks
    await locService.startTracking(
      onLocationUpdate: (position) {
        // Local callback - can be used for UI updates
        developer.log(
          'Position update: (${position.latitude}, ${position.longitude})',
          name: 'LocationTrackingIntegration',
        );
      },
      onServerUpdate: (lat, lng) async {
        // Server update callback - update database with new location
        await userApi.updateCurrentLocation(
          userId: userId,
          latitude: lat,
          longitude: lng,
        );
      },
    );

    developer.log(
      'LocationTrackingService started',
      name: 'LocationTrackingIntegration',
    );

    // Step 3: Initialize and start NearbyIssueMonitorService
    monitorService.initialize(
      reportApi: reportApi,
      notificationHelper: notificationHelper,
    );

    await monitorService.startMonitoring();

    developer.log(
      'NearbyIssueMonitorService started',
      name: 'LocationTrackingIntegration',
    );

    developer.log(
      '✅ Location tracking enabled successfully',
      name: 'LocationTrackingIntegration',
    );
  } catch (e, stackTrace) {
    developer.log(
      'Failed to enable location tracking',
      name: 'LocationTrackingIntegration',
      error: e,
      stackTrace: stackTrace,
      level: 1000, // ERROR level
    );
    rethrow; // Re-throw to allow caller to handle the error
  }
}

/// Disable location tracking and proximity monitoring
/// 
/// This function:
/// 1. Updates location_tracking_enabled to FALSE in the database
/// 2. Stops LocationTrackingService
/// 3. Stops NearbyIssueMonitorService
/// 
/// [userId] - The ID of the user disabling location tracking
/// [userApi] - UserApi instance for database operations
/// [locationService] - LocationTrackingService instance (defaults to singleton)
/// [nearbyIssueMonitor] - NearbyIssueMonitorService instance (defaults to singleton)
/// 
/// Does not throw on error - logs errors instead to ensure cleanup completes
Future<void> disableLocationTracking({
  required String userId,
  required UserApi userApi,
  LocationTrackingService? locationService,
  NearbyIssueMonitorService? nearbyIssueMonitor,
}) async {
  try {
    developer.log(
      'Disabling location tracking for user $userId',
      name: 'LocationTrackingIntegration',
    );

    // Use provided services or default to singletons
    final locService = locationService ?? LocationTrackingService();
    final monitorService = nearbyIssueMonitor ?? NearbyIssueMonitorService();

    // Step 1: Update location_tracking_enabled to FALSE in database
    try {
      await userApi.setLocationTrackingEnabled(
        userId: userId,
        enabled: false,
      );

      developer.log(
        'Database updated: location_tracking_enabled = FALSE',
        name: 'LocationTrackingIntegration',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update database, continuing with service shutdown',
        name: 'LocationTrackingIntegration',
        error: e,
        stackTrace: stackTrace,
        level: 900, // WARNING level
      );
      // Continue with service shutdown even if database update fails
    }

    // Step 2: Stop LocationTrackingService
    try {
      await locService.stopTracking();

      developer.log(
        'LocationTrackingService stopped',
        name: 'LocationTrackingIntegration',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to stop LocationTrackingService',
        name: 'LocationTrackingIntegration',
        error: e,
        stackTrace: stackTrace,
        level: 900, // WARNING level
      );
      // Continue with monitor service shutdown
    }

    // Step 3: Stop NearbyIssueMonitorService
    try {
      monitorService.stopMonitoring();

      developer.log(
        'NearbyIssueMonitorService stopped',
        name: 'LocationTrackingIntegration',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to stop NearbyIssueMonitorService',
        name: 'LocationTrackingIntegration',
        error: e,
        stackTrace: stackTrace,
        level: 900, // WARNING level
      );
    }

    developer.log(
      '✅ Location tracking disabled successfully',
      name: 'LocationTrackingIntegration',
    );
  } catch (e, stackTrace) {
    // Log error but don't throw - we want to ensure cleanup completes
    developer.log(
      'Error during location tracking disable',
      name: 'LocationTrackingIntegration',
      error: e,
      stackTrace: stackTrace,
      level: 1000, // ERROR level
    );
  }
}
