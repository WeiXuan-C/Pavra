# Location Tracking Integration

This document describes the application integration functions for location tracking and proximity-based notifications.

## Overview

The location tracking integration provides two high-level functions that coordinate the interaction between:
- **LocationTrackingService**: Manages GPS position monitoring
- **NearbyIssueMonitorService**: Monitors for nearby critical road issues
- **UserApi**: Handles database operations for location data
- **ReportIssueApi**: Searches for nearby issues
- **NotificationHelperService**: Sends proximity notifications

## Functions

### `enableLocationTracking()`

Enables location tracking and proximity monitoring for a user.

**What it does:**
1. Updates `location_tracking_enabled` to `TRUE` in the database
2. Starts `LocationTrackingService` with callbacks for position updates
3. Initializes and starts `NearbyIssueMonitorService` for proximity alerts

**Parameters:**
- `userId` (required): The ID of the user enabling location tracking
- `userApi` (required): UserApi instance for database operations
- `reportApi` (required): ReportIssueApi instance for searching nearby issues
- `notificationHelper` (required): NotificationHelperService for sending notifications
- `locationService` (optional): LocationTrackingService instance (defaults to singleton)
- `nearbyIssueMonitor` (optional): NearbyIssueMonitorService instance (defaults to singleton)

**Throws:**
- `Exception` if location permission is denied
- `Exception` if services fail to start

**Example:**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pavra/core/services/location_tracking_integration.dart';
import 'package:pavra/core/api/user/user_api.dart';
import 'package:pavra/core/api/report_issue/report_issue_api.dart';
import 'package:pavra/core/api/notification/notification_api.dart';
import 'package:pavra/core/services/notification_helper_service.dart';

Future<void> enableTracking(String userId) async {
  final supabase = Supabase.instance.client;
  final userApi = UserApi();
  final notificationApi = NotificationApi();
  final notificationHelper = NotificationHelperService(notificationApi);
  final reportApi = ReportIssueApi(
    supabase,
    notificationHelper: notificationHelper,
    userApi: userApi,
  );

  await enableLocationTracking(
    userId: userId,
    userApi: userApi,
    reportApi: reportApi,
    notificationHelper: notificationHelper,
  );
}
```

### `disableLocationTracking()`

Disables location tracking and proximity monitoring for a user.

**What it does:**
1. Updates `location_tracking_enabled` to `FALSE` in the database
2. Stops `LocationTrackingService`
3. Stops `NearbyIssueMonitorService`

**Parameters:**
- `userId` (required): The ID of the user disabling location tracking
- `userApi` (required): UserApi instance for database operations
- `locationService` (optional): LocationTrackingService instance (defaults to singleton)
- `nearbyIssueMonitor` (optional): NearbyIssueMonitorService instance (defaults to singleton)

**Error Handling:**
Does not throw on error - logs errors instead to ensure cleanup completes. This is intentional to ensure all services are stopped even if one step fails.

**Example:**
```dart
import 'package:pavra/core/services/location_tracking_integration.dart';
import 'package:pavra/core/api/user/user_api.dart';

Future<void> disableTracking(String userId) async {
  final userApi = UserApi();

  await disableLocationTracking(
    userId: userId,
    userApi: userApi,
  );
}
```

## How It Works

### Enable Flow

```
User enables location tracking
         ↓
enableLocationTracking() called
         ↓
1. Update database: location_tracking_enabled = TRUE
         ↓
2. Start LocationTrackingService
   - Request location permissions
   - Start GPS position stream (50m distance filter)
   - Set up callbacks:
     * onLocationUpdate: Called for every position
     * onServerUpdate: Updates database when thresholds met (100m distance OR 60s time)
         ↓
3. Initialize NearbyIssueMonitorService
   - Store ReportIssueApi reference
   - Store NotificationHelperService reference
         ↓
4. Start NearbyIssueMonitorService
   - Create periodic timer (2-minute intervals)
   - Perform immediate proximity check
   - Check for critical issues within 5km
   - Send notifications for new issues
```

### Disable Flow

```
User disables location tracking
         ↓
disableLocationTracking() called
         ↓
1. Update database: location_tracking_enabled = FALSE
   (continues even if this fails)
         ↓
2. Stop LocationTrackingService
   - Cancel GPS position stream
   - Set isTracking = false
   (continues even if this fails)
         ↓
3. Stop NearbyIssueMonitorService
   - Cancel periodic timer
   - Clear notified issues cache
   - Set isMonitoring = false
```

## Configuration

The integration functions use the following configuration from the underlying services:

**LocationTrackingService:**
- Distance filter: 50 meters (minimum movement to trigger position update)
- Distance threshold: 100 meters (minimum distance to update server)
- Time threshold: 60 seconds (minimum time between server updates)
- GPS accuracy: High

**NearbyIssueMonitorService:**
- Check interval: 2 minutes
- Alert radius: 5 kilometers
- Severity filter: High and Critical issues only

## Error Handling

### enableLocationTracking()

**Throws exceptions for:**
- Location permission denied
- Location services disabled
- Service initialization failures

**Logs but doesn't throw for:**
- Callback errors (onLocationUpdate, onServerUpdate)
- Position stream errors

### disableLocationTracking()

**Never throws exceptions** - all errors are logged but don't prevent cleanup from completing. This ensures:
- Database is updated even if services fail to stop
- Services are stopped even if database update fails
- All cleanup steps are attempted

## Privacy and Battery Optimization

**Privacy:**
- Location tracking is opt-in only
- Users can disable tracking at any time
- Location data is only shared when tracking is enabled
- Users with tracking disabled are excluded from proximity queries

**Battery Optimization:**
- 50m distance filter reduces GPS updates
- 100m distance threshold reduces database writes
- 60s time threshold prevents excessive updates
- 2-minute check interval balances responsiveness with battery life

## Requirements Validation

This implementation satisfies the following requirements:

**Requirement 9.1-9.3 (Enable Tracking):**
- ✅ Updates location_tracking_enabled to TRUE in database
- ✅ Starts LocationTrackingService
- ✅ Starts NearbyIssueMonitorService

**Requirement 9.4-9.6 (Disable Tracking):**
- ✅ Updates location_tracking_enabled to FALSE in database
- ✅ Stops LocationTrackingService
- ✅ Stops NearbyIssueMonitorService

## Testing

See `location_tracking_integration_example.dart` for complete UI integration examples including:
- Error handling with user feedback
- Loading indicators
- Success/error messages
- Toggle widget implementation

## Next Steps

To integrate location tracking into your UI:

1. **Settings Screen**: Add a toggle switch that calls these functions
2. **Profile Screen**: Show location tracking status
3. **Map Screen**: Display user's current location when tracking is enabled
4. **Notifications**: Users will automatically receive proximity alerts for nearby critical issues

See `location_tracking_integration_example.dart` for complete implementation examples.
