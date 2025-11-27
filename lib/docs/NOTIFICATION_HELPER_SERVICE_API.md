# NotificationHelperService API Documentation

## Overview

The `NotificationHelperService` is a centralized service that simplifies notification creation for all business events in the Pavra application. It provides pre-configured notification methods with automatic sound, category, and priority configuration, along with comprehensive error handling to ensure notification failures don't disrupt business logic.

## Features

- **Pre-configured Templates**: Each notification type has predefined sound, category, and priority settings
- **Error Handling**: All methods include try-catch blocks to prevent exceptions from disrupting business operations
- **Performance Monitoring**: Automatic logging of slow operations (>500ms)
- **Structured Logging**: Comprehensive error logging with full context for debugging
- **Type Safety**: Strongly typed parameters for all notification methods

## Initialization

```dart
import 'package:pavra/core/api/notification/notification_api.dart';
import 'package:pavra/core/services/notification_helper_service.dart';

// Initialize with NotificationApi dependency
final notificationApi = NotificationApi();
final notificationHelper = NotificationHelperService(notificationApi);
```

## Report Notifications

### notifyReportSubmitted

Sends a success notification to the user who submitted a report.

**Parameters:**
- `userId` (String, required): The ID of the user who submitted the report
- `reportId` (String, required): The ID of the submitted report
- `title` (String, required): The title/description of the report

**Returns:** `Future<void>`

**Configuration:**
- Type: `success`
- Sound: `success`
- Category: `status`
- Priority: `5`

**Example:**
```dart
await notificationHelper.notifyReportSubmitted(
  userId: 'user-123',
  reportId: 'report-456',
  title: 'Large pothole on Main Street',
);
```

---

### notifyNearbyUsers

Sends location alert notifications to users within a specified radius of a reported issue.

**Parameters:**
- `reportId` (String, required): The ID of the report
- `title` (String, required): The title/description of the report
- `latitude` (double, required): Latitude of the report location
- `longitude` (double, required): Longitude of the report location
- `severity` (String, required): Severity level of the issue (e.g., 'high', 'moderate', 'low')
- `nearbyUserIds` (List<String>, required): List of user IDs to notify

**Returns:** `Future<void>`

**Configuration:**
- Type: `location_alert`
- Sound: `alert`
- Category: `alert`
- Priority: `8`

**Example:**
```dart
final nearbyUsers = await userApi.getNearbyUsers(
  latitude: 40.7128,
  longitude: -74.0060,
  radiusKm: 5.0,
);

await notificationHelper.notifyNearbyUsers(
  reportId: 'report-456',
  title: 'Large pothole on Main Street',
  latitude: 40.7128,
  longitude: -74.0060,
  severity: 'high',
  nearbyUserIds: nearbyUsers,
);
```

---

### notifyReportVerified

Notifies the report creator that their report was verified by an authority.

**Parameters:**
- `userId` (String, required): The ID of the report creator
- `reportId` (String, required): The ID of the verified report
- `reviewerId` (String, required): The ID of the authority who verified the report

**Returns:** `Future<void>`

**Configuration:**
- Type: `success`
- Sound: `success`
- Category: `status`
- Priority: `6`

**Example:**
```dart
await notificationHelper.notifyReportVerified(
  userId: 'user-123',
  reportId: 'report-456',
  reviewerId: 'authority-789',
);
```

---

### notifyReportSpam

Notifies the report creator that their report was marked as spam.

**Parameters:**
- `userId` (String, required): The ID of the report creator
- `reportId` (String, required): The ID of the report
- `reviewerId` (String, required): The ID of the authority who marked it as spam
- `comment` (String?, optional): Reason for marking as spam

**Returns:** `Future<void>`

**Configuration:**
- Type: `warning`
- Sound: `warning`
- Category: `warning`
- Priority: `6`

**Example:**
```dart
await notificationHelper.notifyReportSpam(
  userId: 'user-123',
  reportId: 'report-456',
  reviewerId: 'authority-789',
  comment: 'Duplicate report',
);
```

---

### notifyVoteThreshold

Notifies the report creator when their report reaches community vote thresholds.

**Parameters:**
- `userId` (String, required): The ID of the report creator
- `reportId` (String, required): The ID of the report
- `voteType` (String, required): Type of vote ('verified' or 'spam')
- `voteCount` (int, required): Number of votes received

**Returns:** `Future<void>`

**Configuration:**
- Type: `info` (for verified) or `warning` (for spam)
- Sound: `success` (for verified) or `warning` (for spam)
- Category: `status` (for verified) or `warning` (for spam)
- Priority: `6`

**Example:**
```dart
await notificationHelper.notifyVoteThreshold(
  userId: 'user-123',
  reportId: 'report-456',
  voteType: 'verified',
  voteCount: 5,
);
```

## Authority Request Notifications

### notifyRequestSubmitted

Confirms to the user that their authority verification request was submitted.

**Parameters:**
- `userId` (String, required): The ID of the requester
- `requestId` (String, required): The ID of the request

**Returns:** `Future<void>`

**Configuration:**
- Type: `info`
- Sound: `default`
- Category: `status`
- Priority: `5`

**Example:**
```dart
await notificationHelper.notifyRequestSubmitted(
  userId: 'user-123',
  requestId: 'request-456',
);
```

---

### notifyRequestApproved

Notifies the user that their authority request was approved.

**Parameters:**
- `userId` (String, required): The ID of the requester
- `requestId` (String, required): The ID of the request
- `reviewerId` (String, required): The ID of the admin who approved it

**Returns:** `Future<void>`

**Configuration:**
- Type: `success`
- Sound: `success`
- Category: `status`
- Priority: `9` (high priority)

**Example:**
```dart
await notificationHelper.notifyRequestApproved(
  userId: 'user-123',
  requestId: 'request-456',
  reviewerId: 'admin-789',
);
```

---

### notifyRequestRejected

Notifies the user that their authority request was rejected.

**Parameters:**
- `userId` (String, required): The ID of the requester
- `requestId` (String, required): The ID of the request
- `reviewerId` (String, required): The ID of the admin who rejected it
- `comment` (String?, optional): Reason for rejection

**Returns:** `Future<void>`

**Configuration:**
- Type: `warning`
- Sound: `warning`
- Category: `warning`
- Priority: `7`

**Example:**
```dart
await notificationHelper.notifyRequestRejected(
  userId: 'user-123',
  requestId: 'request-456',
  reviewerId: 'admin-789',
  comment: 'Insufficient documentation provided',
);
```

---

### notifyAdminsNewRequest

Notifies all admins and developers about a new authority verification request.

**Parameters:**
- `requestId` (String, required): The ID of the request
- `userId` (String, required): The ID of the requester
- `username` (String, required): The username of the requester

**Returns:** `Future<void>`

**Configuration:**
- Type: `info`
- Sound: `default`
- Category: `status`
- Priority: `7`
- Target: All users with 'admin' or 'developer' roles

**Example:**
```dart
await notificationHelper.notifyAdminsNewRequest(
  requestId: 'request-456',
  userId: 'user-123',
  username: 'john_doe',
);
```

## Reputation Notifications

### notifyReputationChange

Notifies the user about reputation increases or decreases.

**Parameters:**
- `userId` (String, required): The ID of the user
- `changeAmount` (int, required): The amount of reputation change (positive or negative)
- `actionType` (String, required): The action that caused the change
- `scoreAfter` (int, required): The user's reputation score after the change

**Returns:** `Future<void>`

**Configuration:**
- Type: `success` (for positive) or `warning` (for negative)
- Sound: `success` (for positive) or `warning` (for negative)
- Category: `status`
- Priority: `5` (for positive) or `6` (for negative)

**Note:** Automatically skips notification if `changeAmount` is 0.

**Example:**
```dart
await notificationHelper.notifyReputationChange(
  userId: 'user-123',
  changeAmount: 10,
  actionType: 'report_verified',
  scoreAfter: 45,
);
```

---

### notifyReputationMilestone

Notifies the user when they reach reputation milestones (25, 50, 75, 100).

**Parameters:**
- `userId` (String, required): The ID of the user
- `milestone` (int, required): The milestone reached (25, 50, 75, or 100)

**Returns:** `Future<void>`

**Configuration:**
- Type: `success`
- Sound: `success`
- Category: `status`
- Priority: `7`

**Milestone Achievements:**
- 25 points: 🥉 Bronze Achievement
- 50 points: 🥈 Silver Achievement
- 75 points: 🥇 Gold Achievement
- 100 points: 👑 Crown Achievement

**Example:**
```dart
await notificationHelper.notifyReputationMilestone(
  userId: 'user-123',
  milestone: 50,
);
```

## AI Detection Notifications

### notifyCriticalDetection

Notifies the user about critical or high-severity AI detections.

**Parameters:**
- `userId` (String, required): The ID of the user
- `detectionId` (String, required): The ID of the detection
- `issueType` (String, required): The type of issue detected
- `severity` (String, required): Severity level ('critical' or 'high')
- `latitude` (double, required): Latitude of the detection
- `longitude` (double, required): Longitude of the detection
- `confidence` (double, required): AI confidence score (0.0 to 1.0)

**Returns:** `Future<void>`

**Configuration:**
- Type: `alert`
- Sound: `alert`
- Category: `alert`
- Priority: `10` (for critical) or `8` (for high)

**Example:**
```dart
await notificationHelper.notifyCriticalDetection(
  userId: 'user-123',
  detectionId: 'detection-456',
  issueType: 'pothole',
  severity: 'critical',
  latitude: 40.7128,
  longitude: -74.0060,
  confidence: 0.95,
);
```

---

### notifyOfflineQueueProcessed

Notifies the user when their offline detection queue has been processed.

**Parameters:**
- `userId` (String, required): The ID of the user
- `processedCount` (int, required): Number of detections processed

**Returns:** `Future<void>`

**Configuration:**
- Type: `info`
- Sound: `default`
- Category: `status`
- Priority: `5`

**Example:**
```dart
await notificationHelper.notifyOfflineQueueProcessed(
  userId: 'user-123',
  processedCount: 7,
);
```

## Route Notifications

### notifyMonitoredRouteIssue

Notifies users monitoring routes when an issue is reported on their route.

**Parameters:**
- `reportId` (String, required): The ID of the report
- `title` (String, required): The title/description of the report
- `latitude` (double, required): Latitude of the report location
- `longitude` (double, required): Longitude of the report location
- `monitoringUserIds` (List<String>, required): List of user IDs monitoring the affected route

**Returns:** `Future<void>`

**Configuration:**
- Type: `location_alert`
- Sound: `alert`
- Category: `alert`
- Priority: `8`

**Example:**
```dart
final monitoringUsers = await savedRouteApi.getUsersMonitoringRoute(
  latitude: 40.7128,
  longitude: -74.0060,
  bufferKm: 0.5,
);

await notificationHelper.notifyMonitoredRouteIssue(
  reportId: 'report-456',
  title: 'Road closure on Highway 101',
  latitude: 40.7128,
  longitude: -74.0060,
  monitoringUserIds: monitoringUsers,
);
```

---

### notifyRouteSaved

Confirms to the user that their route was saved successfully.

**Parameters:**
- `userId` (String, required): The ID of the user
- `routeId` (String, required): The ID of the saved route
- `routeName` (String, required): The name of the route

**Returns:** `Future<void>`

**Configuration:**
- Type: `success`
- Sound: `success`
- Category: `status`
- Priority: `5`

**Example:**
```dart
await notificationHelper.notifyRouteSaved(
  userId: 'user-123',
  routeId: 'route-456',
  routeName: 'Home to Work',
);
```

---

### notifyRouteMonitoringEnabled

Confirms to the user that route monitoring was enabled.

**Parameters:**
- `userId` (String, required): The ID of the user
- `routeId` (String, required): The ID of the route
- `routeName` (String, required): The name of the route

**Returns:** `Future<void>`

**Configuration:**
- Type: `info`
- Sound: `default`
- Category: `status`
- Priority: `5`

**Example:**
```dart
await notificationHelper.notifyRouteMonitoringEnabled(
  userId: 'user-123',
  routeId: 'route-456',
  routeName: 'Home to Work',
);
```

## User Onboarding Notifications

### notifyWelcomeNewUser

Sends a welcome notification to new users with onboarding guidance.

**Parameters:**
- `userId` (String, required): The ID of the new user

**Returns:** `Future<void>`

**Configuration:**
- Type: `info`
- Sound: `default`
- Category: `status`
- Priority: `6`

**Example:**
```dart
await notificationHelper.notifyWelcomeNewUser(
  userId: 'user-123',
);
```

---

### notifyRoleChanged

Notifies the user when their role is changed.

**Parameters:**
- `userId` (String, required): The ID of the user
- `newRole` (String, required): The new role assigned to the user

**Returns:** `Future<void>`

**Configuration:**
- Type: `info`
- Sound: `default`
- Category: `status`
- Priority: `6`

**Example:**
```dart
await notificationHelper.notifyRoleChanged(
  userId: 'user-123',
  newRole: 'authority',
);
```

## System Notifications

### notifySystemMaintenance

Notifies all users about scheduled system maintenance.

**Parameters:**
- `maintenanceStart` (DateTime, required): Start time of maintenance
- `maintenanceEnd` (DateTime, required): End time of maintenance

**Returns:** `Future<void>`

**Configuration:**
- Type: `system`
- Sound: `default`
- Category: `status`
- Priority: `7`
- Target: All users

**Example:**
```dart
await notificationHelper.notifySystemMaintenance(
  maintenanceStart: DateTime(2024, 1, 15, 2, 0),
  maintenanceEnd: DateTime(2024, 1, 15, 4, 0),
);
```

---

### notifyAppUpdate

Notifies all users about available app updates.

**Parameters:**
- `newVersion` (String, required): The new version number
- `updateUrl` (String, required): URL to download the update
- `releaseNotes` (String?, optional): Release notes for the update

**Returns:** `Future<void>`

**Configuration:**
- Type: `promotion`
- Sound: `default`
- Category: `status`
- Priority: `6`
- Target: All users

**Example:**
```dart
await notificationHelper.notifyAppUpdate(
  newVersion: '2.1.0',
  updateUrl: 'https://pavra.app/download',
  releaseNotes: 'New AI detection features and performance improvements',
);
```

---

### notifyImportantAnnouncement

Sends important announcements to all users.

**Parameters:**
- `adminId` (String, required): The ID of the admin making the announcement
- `title` (String, required): The announcement title
- `message` (String, required): The announcement message
- `announcementId` (String?, optional): Optional ID for the announcement

**Returns:** `Future<void>`

**Configuration:**
- Type: `promotion`
- Sound: `default`
- Category: `status`
- Priority: `7`
- Target: All users

**Example:**
```dart
await notificationHelper.notifyImportantAnnouncement(
  adminId: 'admin-123',
  title: 'New Safety Features',
  message: 'We\'ve added new safety features to help you report issues faster',
  announcementId: 'announcement-456',
);
```

## Error Handling

All notification methods include comprehensive error handling:

1. **Try-Catch Blocks**: Every method wraps notification creation in try-catch to prevent exceptions
2. **Structured Logging**: Errors are logged with full context including error, stack trace, and notification parameters
3. **Non-Blocking**: Notification failures never disrupt business logic
4. **Performance Monitoring**: Operations taking >500ms are logged as warnings

**Example Error Log:**
```
Failed to create notification in notifyReportSubmitted
Error: OneSignal API unavailable
Notification context: type=success, targetType=single, targetUserIds=1, priority=5
```

## Performance Considerations

- All notification operations are asynchronous
- Slow operations (>500ms) are automatically logged
- Empty user lists are handled gracefully (no notifications sent)
- Zero-value changes (e.g., reputation change of 0) skip notification creation

## Best Practices

1. **Always await notification calls** to ensure proper error handling
2. **Query users before notifying** (e.g., getNearbyUsers before notifyNearbyUsers)
3. **Provide meaningful titles** that clearly describe the notification purpose
4. **Include relevant data** in the data parameter for deep linking
5. **Use appropriate severity levels** to avoid notification fatigue
6. **Test notification flows** in development before deploying

## Integration Example

Complete example of integrating notifications into a report submission flow:

```dart
class ReportIssueApi {
  final NotificationHelperService _notificationHelper;
  final UserApi _userApi;
  final SavedRouteApi _savedRouteApi;
  
  ReportIssueApi(
    this._notificationHelper,
    this._userApi,
    this._savedRouteApi,
  );
  
  Future<ReportIssueModel> submitReport(String id) async {
    // 1. Submit the report
    final report = await _repository.submitReportIssue(id);
    
    // 2. Notify the report creator
    await _notificationHelper.notifyReportSubmitted(
      userId: report.createdBy!,
      reportId: report.id,
      title: report.title ?? 'Road Issue',
    );
    
    // 3. Notify nearby users
    if (report.latitude != null && report.longitude != null) {
      final nearbyUsers = await _userApi.getNearbyUsers(
        latitude: report.latitude!,
        longitude: report.longitude!,
        radiusKm: 5.0,
      );
      
      if (nearbyUsers.isNotEmpty) {
        await _notificationHelper.notifyNearbyUsers(
          reportId: report.id,
          title: report.title ?? 'Road Issue',
          latitude: report.latitude!,
          longitude: report.longitude!,
          severity: report.severity ?? 'moderate',
          nearbyUserIds: nearbyUsers,
        );
      }
      
      // 4. Notify users monitoring routes
      final monitoringUsers = await _savedRouteApi.getUsersMonitoringRoute(
        latitude: report.latitude!,
        longitude: report.longitude!,
        bufferKm: 0.5,
      );
      
      if (monitoringUsers.isNotEmpty) {
        await _notificationHelper.notifyMonitoredRouteIssue(
          reportId: report.id,
          title: report.title ?? 'Road Issue',
          latitude: report.latitude!,
          longitude: report.longitude!,
          monitoringUserIds: monitoringUsers,
        );
      }
    }
    
    return report;
  }
}
```

## See Also

- [Notification API Documentation](./API_DOCUMENTATION.md)
- [Notification Usage Guide](./NOTIFICATION_USAGE.md)
- [Business Event Notifications Spec](./.kiro/specs/business-event-notifications/)
