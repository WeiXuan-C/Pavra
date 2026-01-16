# Design Document

## Overview

This design document outlines the implementation of real-time location tracking and proximity-based notifications for the Pavra road safety application. The system will continuously monitor user GPS positions, intelligently update server-side location data, and automatically alert users when they approach critical road hazards.

The solution implements a three-layer architecture:

1. **Location Tracking Layer**: Continuous GPS monitoring with intelligent throttling to balance accuracy and battery life
2. **Server Synchronization Layer**: Periodic location updates to the database with distance (100m) and time (60s) thresholds
3. **Proximity Monitoring Layer**: Background service that checks for nearby critical issues every 2 minutes and triggers notifications

This feature builds on the existing notification infrastructure (NotificationHelperService, NotificationAPI, OneSignal integration) and extends the UserAPI with location management capabilities.

### Key Design Decisions

- **Singleton Pattern**: LocationTrackingService uses singleton to ensure only one GPS stream is active
- **Throttled Updates**: Server updates are throttled by both distance (100m) and time (60s) to reduce database load
- **Graceful Degradation**: All location and notification failures are logged but don't disrupt the app
- **Privacy First**: Location tracking is opt-in and can be disabled at any time
- **Staleness Filtering**: Users with location data older than 30 minutes are excluded from proximity queries

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Interface Layer                          │
├─────────────────────────────────────────────────────────────────┤
│  Settings Screen  │  Map Screen  │  Profile Screen              │
│  - Enable/Disable Location Tracking                              │
│  - View Location Status                                          │
└────────────┬────────────────────────────────────────────────────┘
             │ Calls
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Application Integration Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  enableLocationTracking()                                        │
│  disableLocationTracking()                                       │
└────────────┬────────────────────────────────────────────────────┘
             │ Manages
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Location Tracking Service (NEW)                     │
├─────────────────────────────────────────────────────────────────┤
│  - Singleton instance                                            │
│  - GPS position stream management                                │
│  - Update threshold evaluation                                   │
│  - Callbacks: onLocationUpdate, onServerUpdate                   │
└────────────┬────────────────────────────────────────────────────┘
             │ Updates
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              User API (EXTENDED)                                 │
├─────────────────────────────────────────────────────────────────┤
│  - updateCurrentLocation()                                       │
│  - setLocationTrackingEnabled()                                  │
│  - getNearbyUsers() [existing]                                   │
└────────────┬────────────────────────────────────────────────────┘
             │ Writes to
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Database (Supabase)                                 │
├─────────────────────────────────────────────────────────────────┤
│  profiles table:                                                 │
│    - current_latitude                                            │
│    - current_longitude                                           │
│    - location_updated_at                                         │
│    - location_tracking_enabled                                   │
│  get_nearby_users() function                                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              Nearby Issue Monitor Service (NEW)                  │
├─────────────────────────────────────────────────────────────────┤
│  - Periodic timer (2-minute intervals)                           │
│  - Notified issues cache                                         │
│  - Integration with ReportIssueApi                               │
│  - Integration with NotificationHelperService                    │
└────────────┬────────────────────────────────────────────────────┘
             │ Queries
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Report Issue API (Existing)                         │
├─────────────────────────────────────────────────────────────────┤
│  - searchNearby()                                                │
└────────────┬────────────────────────────────────────────────────┘
             │ Triggers
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Notification Helper Service (Existing)              │
├─────────────────────────────────────────────────────────────────┤
│  - notifyNearbyUsers()                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow: Location Tracking and Proximity Alerts

```
1. User enables location tracking
   ↓
2. enableLocationTracking() called
   ↓
3. UserApi.setLocationTrackingEnabled(true)
   ↓
4. LocationTrackingService.startTracking()
   ↓
5. GPS position stream starts (50m distance filter)
   ↓
6. Position received → onLocationUpdate callback
   ↓
7. Check thresholds (100m distance OR 60s time)
   ↓
8. If thresholds met → onServerUpdate callback
   ↓
9. UserApi.updateCurrentLocation(lat, lng)
   ↓
10. Database updated with new location
   ↓
11. NearbyIssueMonitorService.startMonitoring()
   ↓
12. Periodic timer triggers every 2 minutes
   ↓
13. Get last position from LocationTrackingService
   ↓
14. ReportIssueApi.searchNearby(lat, lng, 5km)
   ↓
15. Filter for high/critical severity
   ↓
16. Exclude issues in notified cache
   ↓
17. For each new critical issue:
    ↓
18. NotificationHelperService.notifyNearbyUsers()
    ↓
19. Add issue ID to notified cache
    ↓
20. OneSignal delivers push notification
```


## Components and Interfaces

### LocationTrackingService (NEW)

A singleton service that manages continuous GPS position monitoring with intelligent throttling.

```dart
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;

class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;
  
  // Minimum distance (meters) before updating server
  static const double _minDistanceThreshold = 100.0;
  
  // Minimum time (seconds) between server updates
  static const int _minUpdateInterval = 60;

  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastPosition;

  /// Start location tracking
  /// 
  /// Throws Exception if location permission is denied
  Future<void> startTracking({
    required Function(Position) onLocationUpdate,
    required Function(double lat, double lng) onServerUpdate,
  }) async;

  /// Check if we should update server based on distance and time thresholds
  bool _shouldUpdateServer(Position newPosition);

  /// Stop location tracking
  Future<void> stopTracking() async;

  /// Get current position once
  Future<Position> getCurrentPosition() async;
}
```

### UserApi Extensions (NEW)

```dart
class UserApi {
  /// Update user's current location
  /// 
  /// Does not throw on failure - logs error instead to prevent
  /// disrupting location tracking
  Future<void> updateCurrentLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async;

  /// Enable/disable location tracking for user
  Future<void> setLocationTrackingEnabled({
    required String userId,
    required bool enabled,
  }) async;

  /// Get users within radius of a location who have location alerts enabled
  /// [Existing method - already implemented]
  Future<List<String>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async;
}
```

### NearbyIssueMonitorService (NEW)

A background service that periodically checks for critical road issues near the user's location.

```dart
import 'dart:async';
import 'dart:developer' as developer;
import '../api/report_issue/report_issue_api.dart';
import '../services/notification_helper_service.dart';
import 'location_tracking_service.dart';

class NearbyIssueMonitorService {
  static final NearbyIssueMonitorService _instance = NearbyIssueMonitorService._internal();
  factory NearbyIssueMonitorService() => _instance;
  NearbyIssueMonitorService._internal();

  final LocationTrackingService _locationService = LocationTrackingService();
  ReportIssueApi? _reportApi;
  NotificationHelperService? _notificationHelper;
  
  Timer? _monitorTimer;
  bool _isMonitoring = false;
  
  // Check for nearby issues every 2 minutes
  static const Duration _checkInterval = Duration(minutes: 2);
  
  // Alert radius in km
  static const double _alertRadiusKm = 5.0;
  
  // Track notified issues to avoid duplicate notifications
  final Set<String> _notifiedIssueIds = {};

  /// Initialize with required dependencies
  /// 
  /// Must be called before startMonitoring()
  void initialize({
    required ReportIssueApi reportApi,
    required NotificationHelperService notificationHelper,
  });

  /// Start monitoring for nearby issues
  /// 
  /// Throws Exception if not initialized
  Future<void> startMonitoring() async;

  /// Stop monitoring
  void stopMonitoring();

  /// Check for nearby issues and send notifications
  Future<void> _checkNearbyIssues() async;

  /// Clear notified issues cache (call when user moves significantly)
  void clearNotifiedCache();
}
```

### Application Integration Functions (NEW)

```dart
// In main.dart or app initialization

/// Enable location tracking and proximity monitoring
Future<void> enableLocationTracking({
  required String userId,
  required UserApi userApi,
  required LocationTrackingService locationService,
  required NearbyIssueMonitorService nearbyIssueMonitor,
}) async;

/// Disable location tracking and proximity monitoring
Future<void> disableLocationTracking({
  required String userId,
  required UserApi userApi,
  required LocationTrackingService locationService,
  required NearbyIssueMonitorService nearbyIssueMonitor,
}) async;
```


## Data Models

### Database Schema Changes

#### profiles Table Extensions

```sql
-- Add location tracking columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN current_latitude DOUBLE PRECISION,
ADD COLUMN current_longitude DOUBLE PRECISION,
ADD COLUMN location_updated_at TIMESTAMPTZ,
ADD COLUMN location_tracking_enabled BOOLEAN DEFAULT FALSE;

-- Create spatial index for efficient proximity queries
CREATE INDEX idx_profiles_location ON public.profiles 
USING BTREE (current_latitude, current_longitude)
WHERE current_latitude IS NOT NULL 
  AND current_longitude IS NOT NULL
  AND location_tracking_enabled = TRUE;

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.current_latitude IS 'User''s current latitude for proximity notifications';
COMMENT ON COLUMN public.profiles.current_longitude IS 'User''s current longitude for proximity notifications';
COMMENT ON COLUMN public.profiles.location_updated_at IS 'Timestamp of last location update';
COMMENT ON COLUMN public.profiles.location_tracking_enabled IS 'Whether user has enabled location tracking';
```

### Database Functions

#### get_nearby_users Function (UPDATED)

```sql
CREATE OR REPLACE FUNCTION public.get_nearby_users(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (id UUID, distance_km DOUBLE PRECISION)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    -- Haversine formula for distance calculation
    (
      6371 * acos(
        LEAST(1.0, GREATEST(-1.0,
          cos(radians(lat)) * 
          cos(radians(p.current_latitude)) * 
          cos(radians(p.current_longitude) - radians(lng)) + 
          sin(radians(lat)) * 
          sin(radians(p.current_latitude))
        ))
      )
    ) AS distance_km
  FROM public.profiles p
  LEFT JOIN public.user_alert_preferences uap ON p.id = uap.user_id
  WHERE 
    -- User has location tracking enabled
    p.location_tracking_enabled = true
    -- User has current location data
    AND p.current_latitude IS NOT NULL
    AND p.current_longitude IS NOT NULL
    -- Location data is recent (within last 30 minutes)
    AND p.location_updated_at > NOW() - INTERVAL '30 minutes'
    -- User has notifications enabled
    AND p.notifications_enabled = true
    -- User has location alerts enabled (any type)
    AND (
      uap.id IS NULL
      OR uap.road_damage_enabled = true
      OR uap.construction_zones_enabled = true
      OR uap.weather_hazards_enabled = true
      OR uap.traffic_incidents_enabled = true
    )
    -- Don't notify the current user
    AND p.id != COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID)
  HAVING
    -- Filter by distance
    (
      6371 * acos(
        LEAST(1.0, GREATEST(-1.0,
          cos(radians(lat)) * 
          cos(radians(p.current_latitude)) * 
          cos(radians(p.current_longitude) - radians(lng)) + 
          sin(radians(lat)) * 
          sin(radians(p.current_latitude))
        ))
      )
    ) <= radius_km
  ORDER BY distance_km;
END;
$$;

-- Add comment
COMMENT ON FUNCTION public.get_nearby_users IS 'Find users within radius who have location tracking and alerts enabled';
```

### Configuration Constants

```dart
class LocationTrackingConfig {
  // Location tracking thresholds
  static const double minDistanceThresholdMeters = 100.0;
  static const int minUpdateIntervalSeconds = 60;
  static const double positionStreamDistanceFilter = 50.0;
  
  // Proximity monitoring
  static const Duration proximityCheckInterval = Duration(minutes: 2);
  static const double alertRadiusKm = 5.0;
  
  // Location staleness
  static const Duration locationStalenessThreshold = Duration(minutes: 30);
  
  // GPS accuracy
  static const LocationAccuracy gpsAccuracy = LocationAccuracy.high;
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Database and Query Properties

**Property 1: Nearby users distance accuracy**
*For any* call to get_nearby_users with radius R and location L, all returned users should be within R kilometers of L using Haversine distance calculation
**Validates: Requirements 2.1, 2.7**

**Property 2: Nearby users filtering completeness**
*For any* call to get_nearby_users, all returned users should have location_tracking_enabled=TRUE, current_latitude IS NOT NULL, current_longitude IS NOT NULL, notifications_enabled=TRUE, and location_updated_at within last 30 minutes
**Validates: Requirements 2.2, 2.3, 2.4, 2.5**

**Property 3: Nearby users exclude current user**
*For any* call to get_nearby_users, the current authenticated user should never appear in the results
**Validates: Requirements 2.6**

**Property 4: Nearby users distance ordering**
*For any* call to get_nearby_users returning multiple users, the results should be ordered by distance in ascending order
**Validates: Requirements 2.8**

### Location Tracking Service Properties

**Property 5: Position callback invocation**
*For any* position received by the location stream, the onLocationUpdate callback should be invoked
**Validates: Requirements 3.5**

**Property 6: Threshold checking occurs**
*For any* position received by the location stream, the system should evaluate whether server update thresholds are met
**Validates: Requirements 3.6**

**Property 7: Server update on threshold met**
*For any* position where both time threshold (60s) and distance threshold (100m) are exceeded, the onServerUpdate callback should be invoked
**Validates: Requirements 3.7, 4.4**

**Property 8: Time threshold enforcement**
*For any* position received less than 60 seconds after the last server update, the server update should be skipped
**Validates: Requirements 4.2, 11.2**

**Property 9: Distance threshold enforcement**
*For any* position less than 100 meters from the last updated position, the server update should be skipped
**Validates: Requirements 4.3, 11.3**

**Property 10: Update timestamp recording**
*For any* server update performed, the current timestamp should be recorded as the last update time
**Validates: Requirements 4.5**

### User API Properties

**Property 11: Location update persistence**
*For any* call to updateCurrentLocation with valid coordinates, the current_latitude, current_longitude, and location_updated_at should be updated in the profiles table
**Validates: Requirements 5.1, 5.2, 5.3**

**Property 12: Location update error resilience**
*For any* failure in updateCurrentLocation, an error should be logged and no exception should be thrown
**Validates: Requirements 5.4, 10.3**

**Property 13: Tracking enabled flag persistence**
*For any* call to setLocationTrackingEnabled, the location_tracking_enabled flag should be updated in the profiles table
**Validates: Requirements 5.5**

### Proximity Monitoring Properties

**Property 14: Periodic check execution**
*For any* timer trigger while monitoring is active, a proximity check should be executed
**Validates: Requirements 6.3**

**Property 15: Last position usage**
*For any* proximity check, the system should use the last known position from LocationTrackingService
**Validates: Requirements 7.1**

**Property 16: Search radius consistency**
*For any* proximity check with available position, the search should use a 5km radius
**Validates: Requirements 7.3**

**Property 17: Severity filtering**
*For any* set of issues returned from proximity search, only issues with severity 'high' or 'critical' should be processed for notifications
**Validates: Requirements 7.4**

**Property 18: Cache-based deduplication**
*For any* set of issues being processed, issues already in the notified issues cache should be excluded
**Validates: Requirements 7.5, 13.2**

**Property 19: Notification for critical issues**
*For any* new critical issue (not in cache), a notification should be sent
**Validates: Requirements 7.7**

**Property 20: Cache update on notification**
*For any* successfully sent notification, the issue ID should be added to the notified issues cache
**Validates: Requirements 7.8, 13.1**

### Notification Integration Properties

**Property 21: Notification data completeness**
*For any* call to notifyNearbyUsers for a critical issue, the notification should include report ID, title, latitude, longitude, and severity
**Validates: Requirements 8.2**

**Property 22: User inclusion in notification**
*For any* notification sent for a nearby critical issue, the current user ID should be included in nearbyUserIds
**Validates: Requirements 8.3**

**Property 23: Notification error resilience**
*For any* notification creation failure, an error should be logged and processing of other issues should continue
**Validates: Requirements 8.4, 10.5**

**Property 24: Notification logging**
*For any* notification sent, the issue ID should be logged
**Validates: Requirements 8.5**

### Application Integration Properties

**Property 25: Enable tracking database update**
*For any* call to enableLocationTracking, location_tracking_enabled should be set to TRUE in the database
**Validates: Requirements 9.1**

**Property 26: Enable tracking service start**
*For any* call to enableLocationTracking, both LocationTrackingService and NearbyIssueMonitorService should be started
**Validates: Requirements 9.2, 9.3**

**Property 27: Disable tracking database update**
*For any* call to disableLocationTracking, location_tracking_enabled should be set to FALSE in the database
**Validates: Requirements 9.4**

**Property 28: Disable tracking service stop**
*For any* call to disableLocationTracking, both LocationTrackingService and NearbyIssueMonitorService should be stopped
**Validates: Requirements 9.5, 9.6**

### Error Handling Properties

**Property 29: Position stream error resilience**
*For any* error in the position stream, the error should be logged and the app should not crash
**Validates: Requirements 10.2**

**Property 30: Search failure resilience**
*For any* failure in nearby issue search, the error should be logged and monitoring should continue
**Validates: Requirements 10.4**

### Privacy and Control Properties

**Property 31: Disabled tracking prevents updates**
*For any* user with location_tracking_enabled=FALSE, no location updates should be sent to the server
**Validates: Requirements 12.1**

**Property 32: Disabled tracking prevents monitoring**
*For any* user with location_tracking_enabled=FALSE, no proximity monitoring should occur
**Validates: Requirements 12.2**

**Property 33: Disable stops services**
*For any* disable action, all location-related background services should be stopped
**Validates: Requirements 12.3**

**Property 34: Disabled users excluded from queries**
*For any* user with location_tracking_enabled=FALSE, they should not appear in nearby user query results
**Validates: Requirements 12.4**

**Property 35: Stale location exclusion**
*For any* user with location_updated_at older than 30 minutes, they should not appear in nearby user query results
**Validates: Requirements 12.5**

### Cache Management Properties

**Property 36: Cache clearing on stop**
*For any* call to stopMonitoring, the notified issues cache should be cleared
**Validates: Requirements 13.4**

**Property 37: Cache clearing on clear call**
*For any* call to clearNotifiedCache, all issue IDs should be removed from the cache
**Validates: Requirements 13.3**

### Logging Properties

**Property 38: Tracking start logging**
*For any* successful start of location tracking, a log message should be created indicating tracking is active
**Validates: Requirements 15.1**

**Property 39: Tracking stop logging**
*For any* successful stop of location tracking, a log message should be created indicating tracking is stopped
**Validates: Requirements 15.2**

**Property 40: Location update logging**
*For any* server location update, the latitude and longitude should be logged
**Validates: Requirements 15.3**

**Property 41: Issue count logging**
*For any* proximity check that finds critical issues, the count should be logged
**Validates: Requirements 15.4**

**Property 42: Error logging with stack traces**
*For any* error that occurs, an error message with stack trace should be logged
**Validates: Requirements 15.6**


### Example-Based Tests

**Example 1: Database schema validation**
Given a fresh database migration, the profiles table should have columns current_latitude, current_longitude, location_updated_at, and location_tracking_enabled with correct types
**Validates: Requirements 1.1, 1.2, 1.3, 1.4**

**Example 2: Spatial index exists**
Given a fresh database migration, a spatial index should exist on the profiles table for location columns
**Validates: Requirements 1.5**

**Example 3: Permission denied exception**
Given location permissions are denied, calling startTracking should throw an exception with a clear error message
**Validates: Requirements 3.2, 10.1**

**Example 4: High accuracy configuration**
Given startTracking is called, the position stream should be configured with LocationAccuracy.high
**Validates: Requirements 3.3**

**Example 5: Distance filter configuration**
Given startTracking is called, the position stream should be configured with a 50-meter distance filter
**Validates: Requirements 3.4, 11.1**

**Example 6: Stop tracking cleanup**
Given tracking is active, calling stopTracking should cancel the position stream and set isTracking to FALSE
**Validates: Requirements 3.8, 3.9**

**Example 7: First position always updates**
Given no previous location update, the first position received should trigger a server update regardless of distance or time
**Validates: Requirements 4.1**

**Example 8: Monitoring interval configuration**
Given startMonitoring is called, the periodic timer should be configured with a 2-minute interval
**Validates: Requirements 6.1, 11.4**

**Example 9: Immediate check on start**
Given startMonitoring is called, an immediate proximity check should be performed before the first timer trigger
**Validates: Requirements 6.2**

**Example 10: Stop monitoring cleanup**
Given monitoring is active, calling stopMonitoring should cancel the timer and clear the notified issues cache
**Validates: Requirements 6.4, 6.5**

**Example 11: No position handling**
Given no position is available from LocationTrackingService, a proximity check should log a message and skip the check without error
**Validates: Requirements 7.2**

**Example 12: No issues found handling**
Given a proximity check finds no new critical issues, a log message should be created and no notifications should be sent
**Validates: Requirements 7.6, 15.5 (edge case)**

**Example 13: Initialization requirement**
Given NearbyIssueMonitorService is not initialized, calling startMonitoring should throw an exception
**Validates: Requirements 14.1, 14.2, 14.3**

**Example 14: Service references stored**
Given NearbyIssueMonitorService is initialized with dependencies, the references should be accessible during monitoring
**Validates: Requirements 14.4**

**Example 15: Singleton pattern**
Given multiple instantiations of LocationTrackingService, all should return the same instance
**Validates: Requirements 14.5**


## Error Handling

### Error Handling Strategy

All location tracking and proximity monitoring operations should be wrapped in try-catch blocks to prevent disrupting the application:

```dart
// In LocationTrackingService
Future<void> startTracking({
  required Function(Position) onLocationUpdate,
  required Function(double lat, double lng) onServerUpdate,
}) async {
  // Check permissions
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    final requested = await Geolocator.requestPermission();
    if (requested == LocationPermission.denied || 
        requested == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
  }

  // Start listening to position stream
  _positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    ),
  ).listen(
    (Position position) async {
      _lastPosition = position;
      
      // Notify local listeners
      onLocationUpdate(position);
      
      // Check if we should update server
      if (_shouldUpdateServer(position)) {
        try {
          await onServerUpdate(position.latitude, position.longitude);
          _lastUpdateTime = DateTime.now();
          developer.log('Location updated on server: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          // Log error but don't throw - server update failures shouldn't disrupt tracking
          developer.log('Failed to update location on server: $e');
        }
      }
    },
    onError: (error) {
      // Log error but don't throw - stream errors shouldn't crash the app
      developer.log('Location tracking error: $error');
    },
  );

  _isTracking = true;
  developer.log('Location tracking started');
}
```

```dart
// In UserApi
Future<void> updateCurrentLocation({
  required String userId,
  required double latitude,
  required double longitude,
}) async {
  try {
    await _db.update(
      table: _tableName,
      data: {
        'current_latitude': latitude,
        'current_longitude': longitude,
        'location_updated_at': DateTime.now().toIso8601String(),
      },
      matchColumn: 'id',
      matchValue: userId,
    );
    
    developer.log(
      'Location updated: ($latitude, $longitude)',
      name: 'UserApi',
    );
  } catch (e, stackTrace) {
    developer.log(
      'Failed to update location',
      name: 'UserApi',
      error: e,
      stackTrace: stackTrace,
    );
    // Don't throw - location update failures shouldn't disrupt app
  }
}
```

```dart
// In NearbyIssueMonitorService
Future<void> _checkNearbyIssues() async {
  try {
    final position = _locationService.lastPosition;
    if (position == null) {
      developer.log('No location available for nearby issue check');
      return;
    }

    developer.log('Checking for nearby issues at (${position.latitude}, ${position.longitude})');

    // Search for nearby issues
    final nearbyIssues = await _reportApi!.searchNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: _alertRadiusKm,
      limit: 20,
    );

    // Filter for high severity issues that haven't been notified
    final criticalIssues = nearbyIssues.where((issue) {
      return (issue.severity == 'high' || issue.severity == 'critical') &&
             !_notifiedIssueIds.contains(issue.id);
    }).toList();

    if (criticalIssues.isEmpty) {
      developer.log('No new critical issues nearby');
      return;
    }

    developer.log('Found ${criticalIssues.length} new critical issues nearby');

    // Send notifications for each critical issue
    for (final issue in criticalIssues) {
      try {
        await _notificationHelper!.notifyNearbyUsers(
          reportId: issue.id,
          title: issue.title ?? 'Road Issue',
          latitude: issue.latitude!,
          longitude: issue.longitude!,
          severity: issue.severity,
          nearbyUserIds: [_reportApi!.getCurrentUserId()!],
        );
        
        // Mark as notified
        _notifiedIssueIds.add(issue.id);
        
        developer.log('Sent notification for issue: ${issue.id}');
      } catch (e) {
        // Log error but continue processing other issues
        developer.log('Failed to send notification for issue ${issue.id}: $e');
      }
    }
  } catch (e, stackTrace) {
    // Log error but don't throw - monitoring failures shouldn't crash the app
    developer.log(
      'Error checking nearby issues',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
```

### Error Types

1. **Permission Errors**: Location permission denied
   - Throw clear exception with message
   - User should be prompted to grant permission

2. **GPS Errors**: GPS unavailable or position stream errors
   - Log error and continue
   - Don't crash the app

3. **Network Errors**: Server update failures
   - Log error and continue tracking
   - Location will be updated on next successful attempt

4. **Database Errors**: Query failures
   - Log error and return empty results
   - Don't disrupt business logic

5. **Notification Errors**: Notification creation failures
   - Log error and continue processing other issues
   - Don't disrupt monitoring

### Logging Strategy

```dart
// Structured logging with context
developer.log(
  'Location tracking started',
  name: 'LocationTrackingService',
  time: DateTime.now(),
);

developer.log(
  'Location updated on server: ($latitude, $longitude)',
  name: 'UserApi',
  time: DateTime.now(),
);

developer.log(
  'Found ${criticalIssues.length} new critical issues nearby',
  name: 'NearbyIssueMonitorService',
  time: DateTime.now(),
);

// Error logging with stack traces
developer.log(
  'Failed to update location',
  name: 'UserApi',
  error: e,
  stackTrace: stackTrace,
  level: 1000, // ERROR level
  time: DateTime.now(),
);
```


## Testing Strategy

### Dual Testing Approach

This feature will use both unit tests and property-based tests to ensure comprehensive coverage:

- **Unit tests** verify specific examples, edge cases, and error conditions
- **Property tests** verify universal properties that should hold across all inputs
- Together they provide comprehensive coverage: unit tests catch concrete bugs, property tests verify general correctness

### Property-Based Testing

We will use the Dart `test` package with custom generators for property-based testing. Each property-based test should run a minimum of 100 iterations.

**Property-based testing library**: Dart `test` package with custom generators

**Test configuration**: Minimum 100 iterations per property test

**Property test tagging**: Each property-based test must be tagged with a comment explicitly referencing the correctness property in the design document using this format:
```dart
// **Feature: location-tracking-notifications, Property 1: Nearby users distance accuracy**
```

### Unit Tests

Unit tests will cover:

**Database Schema Tests**:
- Verify columns exist with correct types after migration
- Verify spatial index exists
- Verify default values are correct

**LocationTrackingService Tests**:
- Permission handling (denied, granted)
- Stream configuration (accuracy, distance filter)
- Callback invocation
- Threshold evaluation logic
- Singleton pattern
- Start/stop lifecycle

**UserApi Tests**:
- Location update persistence
- Error handling (no exceptions thrown)
- Tracking enabled flag updates

**NearbyIssueMonitorService Tests**:
- Initialization requirements
- Timer configuration
- Immediate check on start
- Cache management
- Error handling

**Integration Tests**:
- Enable/disable tracking flow
- End-to-end location update flow
- End-to-end proximity notification flow

### Property-Based Tests

Property-based tests will verify:

**Database Query Properties**:
```dart
// **Feature: location-tracking-notifications, Property 1: Nearby users distance accuracy**
test('Property 1: Nearby users distance accuracy', () {
  check(
    any.tuple3(
      any.doubleInRange(-90, 90), // latitude
      any.doubleInRange(-180, 180), // longitude
      any.doubleInRange(1, 10), // radius
    ),
  ).times(100).satisfies((tuple) async {
    final (lat, lng, radius) = tuple;
    
    final users = await userApi.getNearbyUsers(
      latitude: lat,
      longitude: lng,
      radiusKm: radius,
    );
    
    // Verify all returned users are within radius
    for (final userId in users) {
      final user = await userApi.getProfileById(userId);
      final distance = calculateHaversineDistance(
        lat, lng,
        user['current_latitude'], user['current_longitude'],
      );
      expect(distance, lessThanOrEqualTo(radius));
    }
  });
});

// **Feature: location-tracking-notifications, Property 2: Nearby users filtering completeness**
test('Property 2: Nearby users filtering completeness', () {
  check(
    any.tuple3(
      any.doubleInRange(-90, 90),
      any.doubleInRange(-180, 180),
      any.doubleInRange(1, 10),
    ),
  ).times(100).satisfies((tuple) async {
    final (lat, lng, radius) = tuple;
    
    final users = await userApi.getNearbyUsers(
      latitude: lat,
      longitude: lng,
      radiusKm: radius,
    );
    
    // Verify all returned users meet filtering criteria
    for (final userId in users) {
      final user = await userApi.getProfileById(userId);
      expect(user['location_tracking_enabled'], isTrue);
      expect(user['current_latitude'], isNotNull);
      expect(user['current_longitude'], isNotNull);
      expect(user['notifications_enabled'], isTrue);
      
      final updateTime = DateTime.parse(user['location_updated_at']);
      final age = DateTime.now().difference(updateTime);
      expect(age.inMinutes, lessThanOrEqualTo(30));
    }
  });
});
```

**Threshold Properties**:
```dart
// **Feature: location-tracking-notifications, Property 8: Time threshold enforcement**
test('Property 8: Time threshold enforcement', () {
  check(
    any.tuple2(
      any.position, // first position
      any.position, // second position
    ),
  ).times(100).satisfies((tuple) async {
    final (pos1, pos2) = tuple;
    
    // Simulate first update
    service.updatePosition(pos1);
    await Future.delayed(Duration(seconds: 30)); // Less than 60s
    
    // Second update should be skipped
    final shouldUpdate = service.shouldUpdateServer(pos2);
    expect(shouldUpdate, isFalse);
  });
});

// **Feature: location-tracking-notifications, Property 9: Distance threshold enforcement**
test('Property 9: Distance threshold enforcement', () {
  check(
    any.tuple2(
      any.position,
      any.positionNearby(maxDistanceMeters: 50), // Less than 100m
    ),
  ).times(100).satisfies((tuple) async {
    final (pos1, pos2) = tuple;
    
    // Simulate first update
    service.updatePosition(pos1);
    await Future.delayed(Duration(seconds: 120)); // More than 60s
    
    // Second update should be skipped due to distance
    final shouldUpdate = service.shouldUpdateServer(pos2);
    expect(shouldUpdate, isFalse);
  });
});
```

**Monitoring Properties**:
```dart
// **Feature: location-tracking-notifications, Property 17: Severity filtering**
test('Property 17: Severity filtering', () {
  check(
    any.listOf(any.reportIssue),
  ).times(100).satisfies((issues) async {
    // Mock search to return these issues
    when(reportApi.searchNearby(any, any, any)).thenReturn(issues);
    
    // Trigger check
    await monitorService.checkNearbyIssues();
    
    // Verify only high/critical issues triggered notifications
    final notifiedIssues = getNotifiedIssues();
    for (final issue in notifiedIssues) {
      expect(
        issue.severity,
        anyOf(equals('high'), equals('critical')),
      );
    }
  });
});

// **Feature: location-tracking-notifications, Property 18: Cache-based deduplication**
test('Property 18: Cache-based deduplication', () {
  check(
    any.listOf(any.reportIssue),
  ).times(100).satisfies((issues) async {
    // First check - all issues should be notified
    when(reportApi.searchNearby(any, any, any)).thenReturn(issues);
    await monitorService.checkNearbyIssues();
    final firstCount = getNotificationCount();
    
    // Second check - no issues should be notified (all cached)
    await monitorService.checkNearbyIssues();
    final secondCount = getNotificationCount();
    
    expect(secondCount, equals(firstCount)); // No new notifications
  });
});
```

### Test Utilities

```dart
// Custom generators for property-based testing
class PositionGenerator {
  static Position generate() {
    return Position(
      latitude: Random().nextDouble() * 180 - 90,
      longitude: Random().nextDouble() * 360 - 180,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }
  
  static Position generateNearby(Position base, {double maxDistanceMeters = 100}) {
    // Generate position within maxDistanceMeters of base
    final bearing = Random().nextDouble() * 2 * pi;
    final distance = Random().nextDouble() * maxDistanceMeters;
    
    final lat = base.latitude + (distance / 111320) * cos(bearing);
    final lng = base.longitude + (distance / (111320 * cos(base.latitude * pi / 180))) * sin(bearing);
    
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }
}

// Haversine distance calculation for tests
double calculateHaversineDistance(
  double lat1, double lon1,
  double lat2, double lon2,
) {
  const R = 6371; // Earth's radius in km
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
      sin(dLon / 2) * sin(dLon / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}
```

### Test Organization

```
test/
├── unit/
│   ├── location_tracking_service_test.dart
│   ├── user_api_location_test.dart
│   ├── nearby_issue_monitor_service_test.dart
│   └── database_schema_test.dart
├── property/
│   ├── nearby_users_properties_test.dart
│   ├── threshold_properties_test.dart
│   ├── monitoring_properties_test.dart
│   └── integration_properties_test.dart
└── integration/
    ├── location_tracking_flow_test.dart
    └── proximity_notification_flow_test.dart
```

### Testing Best Practices

1. **Test Isolation**: Each test should be independent and not rely on state from other tests
2. **Mock External Dependencies**: Use mocks for GPS, database, and notification services
3. **Test Edge Cases**: Empty results, null values, permission denied, etc.
4. **Performance Testing**: Verify operations complete within acceptable time limits
5. **Error Injection**: Test error handling by injecting failures
6. **Cleanup**: Always clean up resources (stop services, clear caches) after tests

