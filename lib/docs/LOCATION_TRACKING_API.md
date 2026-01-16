# Location Tracking API Documentation

This document provides comprehensive API documentation for the location tracking and proximity notification feature.

## Table of Contents

- [Overview](#overview)
- [LocationTrackingService](#locationtrackingservice)
- [UserApi Location Methods](#userapi-location-methods)
- [NearbyIssueMonitorService](#nearbyissuemonitorservice)
- [Integration Functions](#integration-functions)
- [Database Functions](#database-functions)
- [Configuration Constants](#configuration-constants)
- [Error Handling](#error-handling)

---

## Overview

The location tracking system consists of three main layers:

1. **Location Tracking Layer**: Continuous GPS monitoring with intelligent throttling
2. **Server Synchronization Layer**: Periodic location updates to database with distance/time thresholds
3. **Proximity Monitoring Layer**: Background service that checks for nearby critical issues

All services use the singleton pattern to ensure only one instance is active at a time.

---

## LocationTrackingService

**File**: `lib/core/services/location_tracking_service.dart`

Service for continuous location tracking with intelligent throttling. Manages GPS position monitoring and implements threshold-based server updates to balance accuracy with battery life and server load.

### Singleton Access

```dart
final locationService = LocationTrackingService();
```

### Properties

#### `isTracking` (bool, read-only)

Whether location tracking is currently active.

```dart
if (locationService.isTracking) {
  print('Tracking is active');
}
```

#### `lastPosition` (Position?, read-only)

Last known position from GPS. Returns `null` if no position has been received yet.

```dart
final position = locationService.lastPosition;
if (position != null) {
  print('Last position: ${position.latitude}, ${position.longitude}');
}
```

#### `lastUpdateTime` (DateTime?, read-only)

Last time the server was updated with location. Returns `null` if no update has occurred yet.

```dart
final lastUpdate = locationService.lastUpdateTime;
if (lastUpdate != null) {
  print('Last updated: ${lastUpdate.toIso8601String()}');
}
```

### Methods

#### `startTracking`

Start location tracking with callbacks for position updates.

**Signature**:
```dart
Future<void> startTracking({
  required Function(Position) onLocationUpdate,
  required Function(double lat, double lng) onServerUpdate,
})
```

**Parameters**:
- `onLocationUpdate`: Called for every position received from GPS
- `onServerUpdate`: Called when thresholds are met and server should be updated

**Throws**:
- `Exception` if location permission is denied
- `Exception` if location services are disabled

**Behavior**:
- Requests location permissions if not granted
- Initializes position stream with high accuracy and 50m distance filter
- Invokes `onLocationUpdate` for every position received
- Evaluates thresholds (100m distance AND 60s time) for each position
- Invokes `onServerUpdate` when both thresholds are exceeded
- Logs errors but doesn't crash on stream errors or server update failures

**Example**:
```dart
await locationService.startTracking(
  onLocationUpdate: (position) {
    // Update UI with new position
    print('New position: ${position.latitude}, ${position.longitude}');
  },
  onServerUpdate: (lat, lng) async {
    // Update server with new location
    await userApi.updateCurrentLocation(
      userId: currentUserId,
      latitude: lat,
      longitude: lng,
    );
  },
);
```

#### `stopTracking`

Stop location tracking and clean up resources.

**Signature**:
```dart
Future<void> stopTracking()
```

**Behavior**:
- Cancels the position stream subscription
- Sets `isTracking` to false
- Logs tracking stop event

**Example**:
```dart
await locationService.stopTracking();
```

#### `getCurrentPosition`

Get current position once with high accuracy. This is a one-time position request, not continuous tracking.

**Signature**:
```dart
Future<Position> getCurrentPosition()
```

**Returns**: Current GPS position

**Throws**:
- `Exception` if location permission is denied
- `Exception` if location services are disabled

**Example**:
```dart
try {
  final position = await locationService.getCurrentPosition();
  print('Current position: ${position.latitude}, ${position.longitude}');
} catch (e) {
  print('Failed to get position: $e');
}
```

### Threshold Logic

The service uses intelligent throttling to reduce battery drain and server load:

- **Distance Threshold**: 100 meters - Server update only occurs if user has moved at least 100m
- **Time Threshold**: 60 seconds - Server update only occurs if at least 60s have elapsed since last update
- **First Position**: Always triggers server update regardless of thresholds
- **Both Required**: Both distance AND time thresholds must be exceeded for update

---

## UserApi Location Methods

**File**: `lib/core/api/user/user_api.dart`

Extensions to UserApi for managing user location data in the database.

### Methods

#### `updateCurrentLocation`

Update user's current location in the profiles table.

**Signature**:
```dart
Future<void> updateCurrentLocation({
  required String userId,
  required double latitude,
  required double longitude,
})
```

**Parameters**:
- `userId`: ID of the user whose location to update
- `latitude`: Current latitude (-90 to 90)
- `longitude`: Current longitude (-180 to 180)

**Behavior**:
- Updates `current_latitude`, `current_longitude`, and `location_updated_at` in profiles table
- Logs successful updates
- Logs errors but does NOT throw exceptions (to prevent disrupting location tracking)

**Example**:
```dart
await userApi.updateCurrentLocation(
  userId: 'user-123',
  latitude: 37.7749,
  longitude: -122.4194,
);
```

#### `setLocationTrackingEnabled`

Enable or disable location tracking for a user.

**Signature**:
```dart
Future<void> setLocationTrackingEnabled({
  required String userId,
  required bool enabled,
})
```

**Parameters**:
- `userId`: ID of the user
- `enabled`: `true` to enable tracking, `false` to disable

**Behavior**:
- Updates `location_tracking_enabled` flag in profiles table
- Logs the change

**Example**:
```dart
// Enable tracking
await userApi.setLocationTrackingEnabled(
  userId: 'user-123',
  enabled: true,
);

// Disable tracking
await userApi.setLocationTrackingEnabled(
  userId: 'user-123',
  enabled: false,
);
```

#### `getNearbyUsers`

Get users within radius of a location who have location alerts enabled.

**Signature**:
```dart
Future<List<String>> getNearbyUsers({
  required double latitude,
  required double longitude,
  double radiusKm = 5.0,
})
```

**Parameters**:
- `latitude`: Center point latitude
- `longitude`: Center point longitude
- `radiusKm`: Search radius in kilometers (default: 5.0)

**Returns**: List of user IDs within the specified radius

**Filtering Criteria**:
- `location_tracking_enabled` = TRUE
- `current_latitude` and `current_longitude` are NOT NULL
- `location_updated_at` is within last 30 minutes
- `notifications_enabled` = TRUE
- User has at least one alert type enabled
- Excludes the current authenticated user

**Behavior**:
- Calls `get_nearby_users` database function
- Uses Haversine formula for distance calculation
- Returns results ordered by distance (ascending)
- Returns empty list on error (logs error but doesn't throw)

**Example**:
```dart
final nearbyUserIds = await userApi.getNearbyUsers(
  latitude: 37.7749,
  longitude: -122.4194,
  radiusKm: 5.0,
);

print('Found ${nearbyUserIds.length} nearby users');
```

---

## NearbyIssueMonitorService

**File**: `lib/core/services/nearby_issue_monitor_service.dart`

Service for monitoring nearby critical road issues and sending proximity alerts. Periodically checks for high/critical severity issues near the user's current location and sends notifications. Maintains a cache of notified issues to prevent duplicate alerts.

### Singleton Access

```dart
final monitorService = NearbyIssueMonitorService();
```

### Properties

#### `isMonitoring` (bool, read-only)

Whether monitoring is currently active.

```dart
if (monitorService.isMonitoring) {
  print('Monitoring is active');
}
```

#### `notifiedIssueCount` (int, read-only)

Number of issues in the notified cache.

```dart
print('Notified ${monitorService.notifiedIssueCount} issues');
```

### Methods

#### `initialize`

Initialize with required dependencies. Must be called before `startMonitoring()`.

**Signature**:
```dart
void initialize({
  required ReportIssueApi reportApi,
  required NotificationHelperService notificationHelper,
})
```

**Parameters**:
- `reportApi`: API for searching nearby issues
- `notificationHelper`: Service for sending notifications

**Example**:
```dart
monitorService.initialize(
  reportApi: reportIssueApi,
  notificationHelper: notificationHelperService,
);
```

#### `startMonitoring`

Start monitoring for nearby issues.

**Signature**:
```dart
Future<void> startMonitoring()
```

**Throws**:
- `Exception` if not initialized (call `initialize()` first)

**Behavior**:
- Creates a periodic timer that checks for critical issues every 2 minutes
- Performs an immediate check when started
- Sets `isMonitoring` to true
- Logs monitoring start event

**Example**:
```dart
try {
  await monitorService.startMonitoring();
  print('Monitoring started');
} catch (e) {
  print('Failed to start monitoring: $e');
}
```

#### `stopMonitoring`

Stop monitoring for nearby issues.

**Signature**:
```dart
void stopMonitoring()
```

**Behavior**:
- Cancels the periodic timer
- Clears the notified issues cache
- Sets `isMonitoring` to false
- Logs monitoring stop event

**Example**:
```dart
monitorService.stopMonitoring();
```

#### `clearNotifiedCache`

Clear the notified issues cache.

**Signature**:
```dart
void clearNotifiedCache()
```

**Behavior**:
- Removes all issue IDs from the cache
- Allows re-notification of previously notified issues
- Logs cache clear event

**Use Case**: Call this when user moves significantly to allow re-notification of issues they may encounter again.

**Example**:
```dart
// User has moved to a new area
monitorService.clearNotifiedCache();
```

### Monitoring Behavior

The service performs the following steps during each check:

1. Gets last position from `LocationTrackingService`
2. If no position available, logs message and skips check
3. Searches for issues within 5km radius using `ReportIssueApi.searchNearby()`
4. Filters for severity 'high' or 'critical'
5. Excludes issues already in notified cache
6. For each new critical issue:
   - Sends notification via `NotificationHelperService.notifyNearbyUsers()`
   - Adds issue ID to notified cache
   - Logs notification sent
7. Logs errors but continues processing other issues

---

## Integration Functions

**File**: `lib/core/services/location_tracking_integration.dart`

High-level functions for enabling/disabling location tracking that coordinate all services.

### `enableLocationTracking`

Enable location tracking and proximity monitoring for a user.

**Signature**:
```dart
Future<void> enableLocationTracking({
  required String userId,
  required UserApi userApi,
  required ReportIssueApi reportApi,
  required NotificationHelperService notificationHelper,
  LocationTrackingService? locationService,
  NearbyIssueMonitorService? nearbyIssueMonitor,
})
```

**Parameters**:
- `userId`: ID of the user enabling location tracking
- `userApi`: UserApi instance for database operations
- `reportApi`: ReportIssueApi instance for searching nearby issues
- `notificationHelper`: NotificationHelperService for sending notifications
- `locationService`: Optional LocationTrackingService instance (defaults to singleton)
- `nearbyIssueMonitor`: Optional NearbyIssueMonitorService instance (defaults to singleton)

**Throws**:
- `Exception` if location permission is denied
- `Exception` if services fail to start

**Behavior**:
1. Updates `location_tracking_enabled` to TRUE in database
2. Starts LocationTrackingService with callbacks for position updates
3. Initializes and starts NearbyIssueMonitorService
4. Logs all steps and errors

**Example**:
```dart
try {
  await enableLocationTracking(
    userId: currentUserId,
    userApi: userApi,
    reportApi: reportIssueApi,
    notificationHelper: notificationHelperService,
  );
  print('Location tracking enabled');
} catch (e) {
  print('Failed to enable tracking: $e');
  // Show error to user
}
```

### `disableLocationTracking`

Disable location tracking and proximity monitoring for a user.

**Signature**:
```dart
Future<void> disableLocationTracking({
  required String userId,
  required UserApi userApi,
  LocationTrackingService? locationService,
  NearbyIssueMonitorService? nearbyIssueMonitor,
})
```

**Parameters**:
- `userId`: ID of the user disabling location tracking
- `userApi`: UserApi instance for database operations
- `locationService`: Optional LocationTrackingService instance (defaults to singleton)
- `nearbyIssueMonitor`: Optional NearbyIssueMonitorService instance (defaults to singleton)

**Behavior**:
1. Updates `location_tracking_enabled` to FALSE in database
2. Stops LocationTrackingService
3. Stops NearbyIssueMonitorService
4. Logs all steps and errors
5. Does NOT throw on error - logs errors instead to ensure cleanup completes

**Example**:
```dart
await disableLocationTracking(
  userId: currentUserId,
  userApi: userApi,
);
print('Location tracking disabled');
```

---

## Database Functions

### `get_nearby_users`

**File**: `lib/database/functions/get_nearby_users.sql`

Database function to find users within a radius who have location tracking and alerts enabled.

**Signature**:
```sql
get_nearby_users(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (id UUID, distance_km DOUBLE PRECISION)
```

**Parameters**:
- `lat`: Center point latitude
- `lng`: Center point longitude
- `radius_km`: Search radius in kilometers (default: 5.0)

**Returns**: Table with columns:
- `id`: User UUID
- `distance_km`: Distance from center point in kilometers

**Filtering Logic**:
- `location_tracking_enabled` = TRUE
- `current_latitude` and `current_longitude` are NOT NULL
- `location_updated_at` > NOW() - 30 minutes
- `notifications_enabled` = TRUE
- User has at least one alert type enabled (road damage, construction, weather, traffic)
- Excludes current authenticated user

**Distance Calculation**: Uses Haversine formula for accurate distance on Earth's surface

**Ordering**: Results ordered by distance ascending

**Example Usage**:
```sql
-- Find users within 5km of a location
SELECT * FROM get_nearby_users(37.7749, -122.4194, 5.0);

-- Find users within 10km
SELECT * FROM get_nearby_users(37.7749, -122.4194, 10.0);
```

---

## Configuration Constants

### LocationTrackingService

```dart
// Distance threshold for server updates (meters)
static const double _minDistanceThreshold = 100.0;

// Time threshold for server updates (seconds)
static const int _minUpdateInterval = 60;

// Distance filter for position stream (meters)
static const int _positionStreamDistanceFilter = 50;
```

### NearbyIssueMonitorService

```dart
// Check interval for proximity monitoring
static const Duration _checkInterval = Duration(minutes: 2);

// Alert radius for nearby issues (kilometers)
static const double _alertRadiusKm = 5.0;
```

### Database

```sql
-- Location staleness threshold
INTERVAL '30 minutes'
```

---

## Error Handling

### Error Handling Philosophy

All location tracking operations use graceful degradation:

1. **Permission Errors**: Throw clear exceptions with user-friendly messages
2. **GPS Errors**: Log errors and continue (don't crash the app)
3. **Network Errors**: Log errors and retry on next update
4. **Database Errors**: Log errors and return empty results
5. **Notification Errors**: Log errors and continue processing other issues

### Common Error Scenarios

#### Location Permission Denied

```dart
try {
  await locationService.startTracking(...);
} catch (e) {
  if (e.toString().contains('permission denied')) {
    // Show permission request dialog to user
    showPermissionDialog();
  }
}
```

#### Location Services Disabled

```dart
try {
  await locationService.startTracking(...);
} catch (e) {
  if (e.toString().contains('services are disabled')) {
    // Prompt user to enable location services
    showEnableLocationDialog();
  }
}
```

#### Server Update Failure

Server update failures are logged but don't disrupt tracking:

```dart
// In LocationTrackingService
try {
  await onServerUpdate(lat, lng);
} catch (e) {
  // Logged but not thrown - tracking continues
  developer.log('Failed to update location on server: $e');
}
```

#### Monitoring Initialization Error

```dart
try {
  await monitorService.startMonitoring();
} catch (e) {
  if (e.toString().contains('not initialized')) {
    // Initialize first
    monitorService.initialize(
      reportApi: reportApi,
      notificationHelper: notificationHelper,
    );
    await monitorService.startMonitoring();
  }
}
```

### Logging

All services use structured logging with the `dart:developer` package:

```dart
import 'dart:developer' as developer;

// Info logging
developer.log(
  'Location tracking started',
  name: 'LocationTrackingService',
  time: DateTime.now(),
);

// Error logging with stack trace
developer.log(
  'Failed to update location',
  name: 'UserApi',
  error: e,
  stackTrace: stackTrace,
  level: 1000, // ERROR level
  time: DateTime.now(),
);
```

**Log Levels**:
- `800`: INFO (default)
- `900`: WARNING
- `1000`: ERROR

---

## Complete Usage Example

```dart
import 'package:pavra/core/services/location_tracking_integration.dart';
import 'package:pavra/core/api/user/user_api.dart';
import 'package:pavra/core/api/report_issue/report_issue_api.dart';
import 'package:pavra/core/services/notification_helper_service.dart';

class LocationTrackingManager {
  final UserApi userApi;
  final ReportIssueApi reportApi;
  final NotificationHelperService notificationHelper;
  
  LocationTrackingManager({
    required this.userApi,
    required this.reportApi,
    required this.notificationHelper,
  });
  
  /// Enable location tracking for current user
  Future<bool> enableTracking(String userId) async {
    try {
      await enableLocationTracking(
        userId: userId,
        userApi: userApi,
        reportApi: reportApi,
        notificationHelper: notificationHelper,
      );
      
      print('✅ Location tracking enabled');
      return true;
    } catch (e) {
      print('❌ Failed to enable tracking: $e');
      
      // Handle specific errors
      if (e.toString().contains('permission denied')) {
        // Show permission dialog
        showPermissionDialog();
      } else if (e.toString().contains('services are disabled')) {
        // Show enable location services dialog
        showEnableLocationDialog();
      }
      
      return false;
    }
  }
  
  /// Disable location tracking for current user
  Future<void> disableTracking(String userId) async {
    await disableLocationTracking(
      userId: userId,
      userApi: userApi,
    );
    
    print('✅ Location tracking disabled');
  }
  
  /// Check if tracking is currently active
  bool isTrackingActive() {
    final locationService = LocationTrackingService();
    return locationService.isTracking;
  }
  
  /// Get last known position
  Position? getLastPosition() {
    final locationService = LocationTrackingService();
    return locationService.lastPosition;
  }
}
```

---

## See Also

- [Location Tracking Integration README](../core/services/LOCATION_TRACKING_INTEGRATION_README.md)
- [Location Tracking Integration Example](../core/services/location_tracking_integration_example.dart)
- [Requirements Document](../../.kiro/specs/location-tracking-notifications/requirements.md)
- [Design Document](../../.kiro/specs/location-tracking-notifications/design.md)
