# Location Tracking - Quick Reference Card

Quick reference for developers working with the location tracking feature.

## Quick Start

```dart
import 'package:pavra/core/services/location_tracking_integration.dart';

// Enable location tracking
await enableLocationTracking(
  userId: currentUserId,
  userApi: userApi,
  reportApi: reportIssueApi,
  notificationHelper: notificationHelperService,
);

// Disable location tracking
await disableLocationTracking(
  userId: currentUserId,
  userApi: userApi,
);
```

## Key Services

### LocationTrackingService (Singleton)

```dart
final service = LocationTrackingService();

// Start tracking
await service.startTracking(
  onLocationUpdate: (position) {
    // Called for every GPS update
  },
  onServerUpdate: (lat, lng) async {
    // Called when thresholds met
  },
);

// Stop tracking
await service.stopTracking();

// Check status
if (service.isTracking) { /* ... */ }

// Get last position
final position = service.lastPosition;
```

### NearbyIssueMonitorService (Singleton)

```dart
final monitor = NearbyIssueMonitorService();

// Initialize
monitor.initialize(
  reportApi: reportApi,
  notificationHelper: notificationHelper,
);

// Start monitoring
await monitor.startMonitoring();

// Stop monitoring
monitor.stopMonitoring();

// Clear cache
monitor.clearNotifiedCache();
```

### UserApi Location Methods

```dart
// Update location
await userApi.updateCurrentLocation(
  userId: userId,
  latitude: 37.7749,
  longitude: -122.4194,
);

// Enable/disable tracking
await userApi.setLocationTrackingEnabled(
  userId: userId,
  enabled: true,
);

// Get nearby users
final userIds = await userApi.getNearbyUsers(
  latitude: 37.7749,
  longitude: -122.4194,
  radiusKm: 5.0,
);
```

## Configuration Constants

```dart
// LocationTrackingService
minDistanceThreshold: 100.0 meters
minUpdateInterval: 60 seconds
positionStreamDistanceFilter: 50 meters

// NearbyIssueMonitorService
proximityCheckInterval: 2 minutes
alertRadiusKm: 5.0 kilometers

// Database
locationStalenessThreshold: 30 minutes
```

## Common Patterns

### Enable Tracking with Error Handling

```dart
try {
  await enableLocationTracking(
    userId: userId,
    userApi: userApi,
    reportApi: reportApi,
    notificationHelper: notificationHelper,
  );
  showSuccess('Location tracking enabled');
} catch (e) {
  if (e.toString().contains('permission denied')) {
    showPermissionDialog();
  } else {
    showError('Failed to enable tracking: $e');
  }
}
```

### Check Tracking Status

```dart
final locationService = LocationTrackingService();
final monitorService = NearbyIssueMonitorService();

final isActive = locationService.isTracking && 
                 monitorService.isMonitoring;
```

### Get Last Known Position

```dart
final locationService = LocationTrackingService();
final position = locationService.lastPosition;

if (position != null) {
  print('Last position: ${position.latitude}, ${position.longitude}');
  print('Updated: ${locationService.lastUpdateTime}');
} else {
  print('No position available yet');
}
```

## Error Handling

### Permission Errors

```dart
try {
  await service.startTracking(...);
} catch (e) {
  if (e.toString().contains('permission denied')) {
    // Show permission request dialog
  } else if (e.toString().contains('services are disabled')) {
    // Prompt to enable location services
  }
}
```

### Graceful Degradation

All location operations use graceful degradation:
- Server update failures are logged but don't stop tracking
- Notification failures are logged but don't stop monitoring
- Database errors return empty results instead of throwing

## Database Queries

### Get Nearby Users (SQL)

```sql
SELECT * FROM get_nearby_users(37.7749, -122.4194, 5.0);
```

### Check User Location Status (SQL)

```sql
SELECT 
  id,
  username,
  current_latitude,
  current_longitude,
  location_updated_at,
  location_tracking_enabled
FROM profiles
WHERE location_tracking_enabled = true
  AND current_latitude IS NOT NULL
  AND location_updated_at > NOW() - INTERVAL '30 minutes';
```

## Testing

### Manual Test Flow

1. Enable location tracking in settings
2. Move around (>50m) to trigger GPS updates
3. Check logs for "Location updated on server"
4. Wait 2 minutes for proximity check
5. Create a critical issue nearby (<5km)
6. Verify notification received
7. Disable location tracking
8. Verify tracking stopped

### Test Locations

```dart
// San Francisco
lat: 37.7749, lng: -122.4194

// New York
lat: 40.7128, lng: -74.0060

// London
lat: 51.5074, lng: -0.1278
```

## Logging

All services log to `dart:developer`:

```dart
import 'dart:developer' as developer;

// View logs in console
// Filter by name: LocationTrackingService, NearbyIssueMonitorService, UserApi
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Tracking won't start | Check location permissions |
| No server updates | Check internet connection |
| No notifications | Check notification permissions |
| High battery drain | Reduce tracking time or disable when not needed |
| Stale location | Move >50m to trigger update |

## Performance Tips

1. **Battery**: Disable tracking when not driving
2. **Network**: Updates require internet connection
3. **Accuracy**: Works best outdoors with clear sky view
4. **Monitoring**: Check logs for errors regularly

## Key Files

```
lib/core/services/
  ├── location_tracking_service.dart
  ├── nearby_issue_monitor_service.dart
  └── location_tracking_integration.dart

lib/core/api/user/
  └── user_api.dart (location methods)

lib/docs/
  ├── LOCATION_TRACKING_API.md (full API docs)
  ├── LOCATION_TRACKING_USER_GUIDE.md (user guide)
  └── LOCATION_TRACKING_DEPLOYMENT_SUMMARY.md (deployment)

supabase/migrations/
  ├── 20241203_location_tracking.sql (migration)
  ├── MIGRATION_GUIDE.md (migration instructions)
  └── verify_location_tracking_migration.sql (verification)
```

## Requirements Reference

- **Req 1-2**: Database schema and functions
- **Req 3-4**: Location tracking with thresholds
- **Req 5**: User location API
- **Req 6-8**: Proximity monitoring and notifications
- **Req 9**: Enable/disable integration
- **Req 10**: Error handling
- **Req 11**: Performance optimization
- **Req 12**: Privacy controls
- **Req 13**: Cache management
- **Req 14**: Service initialization
- **Req 15**: Logging

## Support

- **Full API Docs**: `lib/docs/LOCATION_TRACKING_API.md`
- **User Guide**: `lib/docs/LOCATION_TRACKING_USER_GUIDE.md`
- **Migration Guide**: `supabase/migrations/MIGRATION_GUIDE.md`
- **Deployment Summary**: `lib/docs/LOCATION_TRACKING_DEPLOYMENT_SUMMARY.md`

---

**Version**: 1.0  
**Last Updated**: December 2024
