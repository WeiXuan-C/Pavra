# Business Event Notifications Documentation

## Overview

This directory contains comprehensive documentation for the Business Event Notifications feature in the Pavra application. This feature implements automated push notification triggers for 25+ business events across 8 major modules.

## Documentation Files

### 1. [NotificationHelperService API Documentation](./NOTIFICATION_HELPER_SERVICE_API.md)

**Purpose:** Complete API reference for the NotificationHelperService

**Contents:**
- All 25+ notification methods with detailed parameters
- Configuration details (sound, category, priority)
- Code examples for each method
- Error handling documentation
- Integration examples

**Use this when:**
- You need to call a specific notification method
- You want to understand notification parameters
- You need code examples for implementation

---

### 2. [Business Event Notifications API Documentation](./BUSINESS_EVENT_NOTIFICATIONS_API.md)

**Purpose:** Documentation for API extensions and database functions

**Contents:**
- UserApi.getNearbyUsers() method documentation
- SavedRouteApi.getUsersMonitoringRoute() method documentation
- Database function specifications (get_nearby_users, get_users_monitoring_route)
- Integration examples
- Performance optimization tips
- Troubleshooting guide

**Use this when:**
- You need to query nearby users or route monitors
- You're working with spatial queries
- You need to understand database function implementation
- You're optimizing query performance

---

### 3. [Notification Trigger Guide](./NOTIFICATION_TRIGGER_GUIDE.md)

**Purpose:** Complete guide to all notification trigger points in the application

**Contents:**
- All 16 notification trigger points documented
- Code examples for each integration
- Error handling best practices
- Testing strategies
- Quick reference tables
- Troubleshooting guide

**Use this when:**
- You're integrating notifications into a new feature
- You need to understand when notifications are triggered
- You want to see complete implementation examples
- You're debugging notification issues

---

## Quick Start

### For Developers Adding New Notifications

1. **Read the Trigger Guide** to understand the pattern
2. **Reference the API Documentation** for the specific method you need
3. **Follow the error handling best practices** in the Trigger Guide
4. **Test your implementation** using the testing strategies provided

### For Developers Using Existing Notifications

1. **Check the Trigger Guide** to see if your use case is already covered
2. **Reference the API Documentation** for method signatures
3. **Copy the integration examples** and adapt to your needs

### For Developers Working with Spatial Queries

1. **Read the API Documentation** for getNearbyUsers and getUsersMonitoringRoute
2. **Review the database function specifications**
3. **Check the performance optimization section**
4. **Ensure proper indexes are in place**

---

## Architecture Overview

```
Business Event → API Method → NotificationHelperService → NotificationAPI → OneSignal
                                        ↓
                                User Resolution
                                (getNearbyUsers,
                             getUsersMonitoringRoute)
```

---

## Key Features

### 1. Pre-configured Templates
Every notification type has predefined sound, category, and priority settings.

### 2. Error Resilience
All notification methods include comprehensive error handling to prevent disrupting business logic.

### 3. Location-Based Targeting
Query nearby users and route monitors using spatial database functions.

### 4. Performance Optimized
Parallel execution, spatial indexes, and efficient queries ensure fast performance.

### 5. Comprehensive Logging
Structured logging with full context for debugging and monitoring.

---

## Notification Types Covered

### Report System (6 triggers)
- Report submission
- Nearby user alerts
- Route monitoring alerts
- Report verification
- Report spam
- Vote thresholds

### Authority Requests (3 triggers)
- Request submission
- Request approval
- Request rejection
- Admin notifications

### Reputation System (2 triggers)
- Reputation changes
- Milestone achievements

### AI Detection (2 triggers)
- Critical detections
- Offline queue processing

### Route System (2 triggers)
- Route save
- Monitoring enablement

### User System (2 triggers)
- New user welcome
- Role changes

### System Notifications (3 triggers)
- Maintenance announcements
- App updates
- Important announcements

---

## Common Tasks

### Task: Send a notification when a business event occurs

1. Inject NotificationHelperService into your API class
2. Call the appropriate notification method after the business logic succeeds
3. Wrap the call in try-catch to handle errors gracefully
4. Log any errors with full context

**Example:**
```dart
class YourApi {
  final NotificationHelperService _notificationHelper;
  
  Future<void> yourMethod() async {
    // Business logic
    final result = await _repository.doSomething();
    
    // Notification
    try {
      await _notificationHelper.notifyYourEvent(...);
    } catch (e, stackTrace) {
      developer.log('Notification failed', error: e, stackTrace: stackTrace);
    }
    
    return result;
  }
}
```

### Task: Query nearby users for location-based notifications

1. Inject UserApi into your API class
2. Call getNearbyUsers with the location and radius
3. Check if the result is not empty
4. Pass the user IDs to the notification method

**Example:**
```dart
final nearbyUsers = await _userApi.getNearbyUsers(
  latitude: 40.7128,
  longitude: -74.0060,
  radiusKm: 5.0,
);

if (nearbyUsers.isNotEmpty) {
  await _notificationHelper.notifyNearbyUsers(...);
}
```

### Task: Query users monitoring routes

1. Inject SavedRouteApi into your API class
2. Call getUsersMonitoringRoute with the location and buffer
3. Check if the result is not empty
4. Pass the user IDs to the notification method

**Example:**
```dart
final monitoringUsers = await _savedRouteApi.getUsersMonitoringRoute(
  latitude: 40.7128,
  longitude: -74.0060,
  bufferKm: 0.5,
);

if (monitoringUsers.isNotEmpty) {
  await _notificationHelper.notifyMonitoredRouteIssue(...);
}
```

---

## Best Practices

1. **Always wrap notification calls in try-catch**
2. **Never let notification failures block business logic**
3. **Log errors with full context for debugging**
4. **Check for empty results before sending notifications**
5. **Use parallel execution (Future.wait) when possible**
6. **Test notification flows in development**
7. **Monitor notification performance in production**

---

## Testing

### Unit Tests
Test that notification methods are called with correct parameters.

### Integration Tests
Test end-to-end notification flows from business event to delivery.

### Manual Testing
Use the checklist in the Trigger Guide to verify all notification types.

---

## Troubleshooting

### Notifications not sending?
1. Check NotificationHelperService injection
2. Review error logs
3. Verify OneSignal configuration

### Users not receiving notifications?
1. Check user preferences (notifications_enabled, location_alerts_enabled)
2. Verify OneSignal subscription
3. Check notification filters

### Slow performance?
1. Verify spatial indexes exist
2. Use parallel execution
3. Monitor query execution time

See the Trigger Guide for detailed troubleshooting steps.

---

## Related Documentation

- [Notification Usage Guide](./NOTIFICATION_USAGE.md) - General notification system usage
- [API Documentation](./API_DOCUMENTATION.md) - Complete API reference
- [Architecture](./ARCHITECTURE.md) - System architecture overview

---

## Specification

For the complete specification including requirements, design, and implementation plan, see:
- [Requirements](./.kiro/specs/business-event-notifications/requirements.md)
- [Design](./.kiro/specs/business-event-notifications/design.md)
- [Tasks](./.kiro/specs/business-event-notifications/tasks.md)

---

## Support

For questions or issues:
1. Check the troubleshooting sections in each document
2. Review the code examples
3. Consult the specification documents
4. Check error logs for detailed context

---

**Last Updated:** November 2024  
**Version:** 1.0.0  
**Status:** Complete
