# Notification System API Documentation

Complete API reference for the Pavra notification system with OneSignal integration.

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Flutter Client API](#flutter-client-api)
4. [Serverpod Server API](#serverpod-server-api)
5. [Data Models](#data-models)
6. [Error Handling](#error-handling)
7. [Rate Limiting](#rate-limiting)
8. [Examples](#examples)

---

## Overview

The notification system provides a comprehensive solution for managing and delivering push notifications through OneSignal. It supports:

- **Immediate notifications** - Send instantly to users
- **Scheduled notifications** - Schedule for future delivery via QStash
- **Draft notifications** - Save without sending
- **Multiple targeting modes** - Single user, multiple users, role-based, or broadcast
- **Rich notifications** - Custom sounds, categories, priorities, and data payloads
- **Data notifications** - Silent background notifications
- **Delivery tracking** - Monitor delivery status and statistics

### Architecture

```
Flutter Client (NotificationAPI)
    ↓
Supabase Database (notifications, user_notifications tables)
    ↓
Serverpod Server (NotificationEndpoint)
    ↓
OneSignal Service (Push delivery)
```

---

## Authentication

All API calls require authentication through Supabase Auth. The current user's ID is automatically included in requests.

### Required Permissions

| Operation | Required Role |
|-----------|---------------|
| Create notification | `developer`, `authority` |
| Update notification | Creator only |
| Delete notification | Creator only |
| Hard delete notification | `admin`, `developer` |
| Broadcast to all users | `admin`, `developer` |
| View own notifications | Any authenticated user |
| Mark as read/unread | Any authenticated user |

---

## Flutter Client API

### NotificationAPI Class

Located at: `lib/core/api/notification/notification_api.dart`

#### Create Notification

Creates a new notification and optionally sends it immediately or schedules it.

```dart
Future<Map<String, dynamic>> createNotification({
  required String createdBy,
  required String title,
  required String message,
  required String type,
  String status = 'sent',
  DateTime? scheduledAt,
  String? relatedAction,
  Map<String, dynamic>? data,
  String targetType = 'single',
  List<String>? targetRoles,
  List<String>? targetUserIds,
  String? sound,
  String? category,
  int priority = 5,
  String? oneSignalNotificationId,
})
```

**Parameters:**

- `createdBy` (required) - User ID of the creator
- `title` (required) - Notification title (max 100 characters)
- `message` (required) - Notification message (max 500 characters)
- `type` (required) - Notification type: `success`, `warning`, `alert`, `info`, `system`, `user`, `report`, `location_alert`, `submission_status`, `promotion`, `reminder`
- `status` - Notification status: `draft`, `scheduled`, `sent` (default: `sent`)
- `scheduledAt` - When to send (required if status is `scheduled`)
- `relatedAction` - UUID of related action_log entry
- `data` - Custom data payload (max 1KB)
- `targetType` - Target type: `single`, `custom`, `role`, `all` (default: `single`)
- `targetRoles` - List of roles to target (required if targetType is `role`)
- `targetUserIds` - List of user IDs to target (required if targetType is `single` or `custom`)
- `sound` - Custom sound file name: `alert`, `warning`, `success`, `default`
- `category` - Android notification channel ID
- `priority` - Priority level 1-10 (default: 5)
- `oneSignalNotificationId` - OneSignal notification ID (set by system)

**Returns:**

```dart
{
  'id': 'uuid',
  'title': 'Notification Title',
  'message': 'Notification message',
  'status': 'sent',
  'created_at': '2024-11-25T10:00:00Z',
  // ... other fields
}
```

**Example:**

```dart
final api = NotificationApi();

// Send immediate notification
final result = await api.createNotification(
  createdBy: currentUserId,
  title: 'New Report Nearby',
  message: 'A road hazard was reported 500m from your location',
  type: 'location_alert',
  targetType: 'custom',
  targetUserIds: nearbyUserIds,
  sound: 'alert',
  category: 'alert',
  priority: 8,
  data: {
    'report_id': reportId,
    'latitude': 37.7749,
    'longitude': -122.4194,
  },
);

// Schedule notification for later
final scheduled = await api.createNotification(
  createdBy: currentUserId,
  title: 'Maintenance Reminder',
  message: 'System maintenance in 1 hour',
  type: 'system',
  status: 'scheduled',
  scheduledAt: DateTime.now().add(Duration(hours: 1)),
  targetType: 'all',
  sound: 'default',
  priority: 5,
);

// Save as draft
final draft = await api.createNotification(
  createdBy: currentUserId,
  title: 'Draft Notification',
  message: 'This will be sent later',
  type: 'info',
  status: 'draft',
  targetType: 'single',
  targetUserIds: [userId],
);
```

---

#### Update Notification

Updates an existing notification. Only draft and scheduled notifications can be updated.

```dart
Future<Map<String, dynamic>> updateNotification({
  required String notificationId,
  required String title,
  required String message,
  required String type,
  String? relatedAction,
  Map<String, dynamic>? data,
  String? status,
  DateTime? scheduledAt,
  String? targetType,
  List<String>? targetRoles,
  List<String>? targetUserIds,
  String? sound,
  String? category,
  int? priority,
})
```

**Constraints:**

- Only the creator can update their notification
- Cannot update notifications with status `sent`
- Updating a scheduled notification cancels the previous schedule and creates a new one
- Changing status from `draft` to `sent` triggers immediate delivery
- Changing status from `draft` to `scheduled` schedules the notification

**Example:**

```dart
// Update draft and send immediately
await api.updateNotification(
  notificationId: draftId,
  title: 'Updated Title',
  message: 'Updated message',
  type: 'info',
  status: 'sent', // Triggers immediate send
);

// Reschedule a scheduled notification
await api.updateNotification(
  notificationId: scheduledId,
  title: 'Rescheduled Notification',
  message: 'New time',
  type: 'system',
  status: 'scheduled',
  scheduledAt: DateTime.now().add(Duration(hours: 2)),
);
```

---

#### Delete Notification

Soft deletes a notification. Only draft and scheduled notifications can be deleted.

```dart
Future<void> deleteNotification({
  required String notificationId,
})
```

**Constraints:**

- Only the creator can delete their notification
- Cannot delete notifications with status `sent`
- Deleting a scheduled notification cancels the OneSignal scheduled notification
- Performs soft delete (sets `is_deleted = true`)

**Example:**

```dart
await api.deleteNotification(notificationId: draftId);
```

---

#### Hard Delete Notification

Permanently deletes a notification and all associated user_notification records.

```dart
Future<void> hardDeleteNotification({
  required String notificationId,
  required String userId,
})
```

**Constraints:**

- Requires `admin` or `developer` role
- Permanently removes all data (cannot be undone)
- Use with extreme caution

**Example:**

```dart
await api.hardDeleteNotification(
  notificationId: notificationId,
  userId: currentUserId,
);
```

---

#### Get User Notifications

Retrieves notifications for a specific user with optional filtering.

```dart
Future<List<Map<String, dynamic>>> getUserNotifications({
  required String userId,
  String? type,
  bool? isRead,
  DateTime? startDate,
  DateTime? endDate,
})
```

**Parameters:**

- `userId` (required) - User ID to get notifications for
- `type` - Filter by notification type
- `isRead` - Filter by read status (true/false)
- `startDate` - Filter notifications created after this date
- `endDate` - Filter notifications created before this date

**Returns:**

List of notifications with user-specific fields (`is_read`, `read_at`).

**Example:**

```dart
// Get all unread notifications
final unread = await api.getUserNotifications(
  userId: currentUserId,
  isRead: false,
);

// Get alerts from last 7 days
final recentAlerts = await api.getUserNotifications(
  userId: currentUserId,
  type: 'alert',
  startDate: DateTime.now().subtract(Duration(days: 7)),
);
```

---

#### Get All Notifications

Retrieves all notifications (admin/developer only).

```dart
Future<List<Map<String, dynamic>>> getAllNotifications({
  bool includeDeleted = false,
})
```

**Example:**

```dart
final allNotifications = await api.getAllNotifications();
```

---

#### Mark as Read

Marks a notification as read for a specific user.

```dart
Future<void> markAsRead({
  required String notificationId,
  required String userId,
})
```

**Example:**

```dart
await api.markAsRead(
  notificationId: notificationId,
  userId: currentUserId,
);
```

---

#### Mark All as Read

Marks all notifications as read for a user.

```dart
Future<void> markAllAsRead(String userId)
```

**Example:**

```dart
await api.markAllAsRead(currentUserId);
```

---

#### Delete Notification for User

Soft deletes a notification for a specific user (doesn't affect other users).

```dart
Future<void> deleteNotificationForUser({
  required String notificationId,
  required String userId,
})
```

**Example:**

```dart
await api.deleteNotificationForUser(
  notificationId: notificationId,
  userId: currentUserId,
);
```

---

#### Get Unread Count

Gets the count of unread notifications for a user.

```dart
Future<int> getUnreadCount(String userId)
```

**Example:**

```dart
final count = await api.getUnreadCount(currentUserId);
print('You have $count unread notifications');
```

---

## Serverpod Server API

### NotificationEndpoint Class

Located at: `pavra_server/pavra_server_server/lib/src/endpoints/notification_endpoint.dart`

#### Send to User

Sends a notification to a single user.

```dart
Future<Map<String, dynamic>> sendToUser(
  Session session, {
  required String userId,
  required String title,
  required String message,
  String type = 'info',
  String? relatedAction,
  Map<String, dynamic>? data,
  String? createdBy,
})
```

**Example:**

```dart
final result = await endpoints.notification.sendToUser(
  session,
  userId: 'user-123',
  title: 'Welcome!',
  message: 'Thanks for joining Pavra',
  type: 'success',
  createdBy: 'system',
);
```

---

#### Send to Users

Sends a notification to multiple users.

```dart
Future<Map<String, dynamic>> sendToUsers(
  Session session, {
  required List<String> userIds,
  required String title,
  required String message,
  String type = 'info',
  String? relatedAction,
  Map<String, dynamic>? data,
  String? createdBy,
})
```

---

#### Send to All

Broadcasts a notification to all users.

```dart
Future<Map<String, dynamic>> sendToAll(
  Session session, {
  required String title,
  required String message,
  String type = 'system',
  Map<String, dynamic>? data,
  String? createdBy,
})
```

**Requires:** `admin` or `developer` role

---

#### Schedule Notification

Schedules a notification for future delivery.

```dart
Future<Map<String, dynamic>> scheduleNotification(
  Session session, {
  required String title,
  required String message,
  required DateTime scheduledAt,
  String type = 'info',
  String? relatedAction,
  Map<String, dynamic>? data,
  String targetType = 'single',
  List<String>? targetRoles,
  List<String>? targetUserIds,
  String? createdBy,
})
```

**Example:**

```dart
final result = await endpoints.notification.scheduleNotification(
  session,
  title: 'Scheduled Maintenance',
  message: 'System will be down for maintenance',
  scheduledAt: DateTime.now().add(Duration(hours: 24)),
  type: 'system',
  targetType: 'all',
  createdBy: adminUserId,
);
```

---

#### Handle Notification Created

Processes a notification that was created via the Flutter client.

```dart
Future<Map<String, dynamic>> handleNotificationCreated(
  Session session, {
  required String notificationId,
})
```

**Note:** This is called automatically by the Flutter client after creating a notification with status `sent`.

---

#### Handle Scheduled Notification

Webhook endpoint called by QStash when a scheduled notification is due.

```dart
Future<Map<String, dynamic>> handleScheduledNotification(
  Session session, {
  required String notificationId,
})
```

**Note:** This is called automatically by QStash at the scheduled time.

---

#### Update Notification Status

Updates the status and delivery statistics of a notification.

```dart
Future<Map<String, dynamic>> updateNotificationStatus(
  Session session, {
  required String notificationId,
  String? status,
  String? oneSignalNotificationId,
  String? errorMessage,
  int? recipientsCount,
  int? successfulDeliveries,
  int? failedDeliveries,
  String? userId,
})
```

**Requires:** `admin` or `developer` role

---

#### Convenience Methods

##### Send App Update Notification

```dart
Future<Map<String, dynamic>> sendAppUpdateNotification(
  Session session, {
  required String version,
  required String updateMessage,
  bool isRequired = false,
})
```

##### Send Feature Announcement

```dart
Future<Map<String, dynamic>> sendFeatureAnnouncement(
  Session session, {
  required String featureName,
  required String description,
})
```

##### Send Activity Notification

```dart
Future<Map<String, dynamic>> sendActivityNotification(
  Session session, {
  required String userId,
  required String activityTitle,
  required String activityMessage,
})
```

---

## Data Models

### NotificationModel

```dart
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? relatedAction;
  final Map<String, dynamic>? data;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String targetType;
  final List<String>? targetRoles;
  final List<String>? targetUserIds;
  final String? createdBy;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  
  // OneSignal fields
  final String? oneSignalNotificationId;
  final String? sound;
  final String? category;
  final int priority;
  final String? errorMessage;
  final int? recipientsCount;
  final int? successfulDeliveries;
  final int? failedDeliveries;
  
  // User-specific fields
  final bool isRead;
  final DateTime? readAt;
}
```

### Notification Types

| Type | Description | Use Case |
|------|-------------|----------|
| `success` | Success message | Action completed successfully |
| `warning` | Warning message | Potential issue or caution |
| `alert` | Critical alert | Urgent attention required |
| `info` | Informational | General information |
| `system` | System message | System announcements |
| `user` | User interaction | User-to-user notifications |
| `report` | Report update | Report status changes |
| `location_alert` | Location-based | Nearby hazards or events |
| `submission_status` | Submission update | Form/request status |
| `promotion` | Promotional | Features, updates, announcements |
| `reminder` | Reminder | Scheduled reminders |

### Notification Status

| Status | Description |
|--------|-------------|
| `draft` | Saved but not sent |
| `scheduled` | Scheduled for future delivery |
| `sent` | Successfully sent |
| `failed` | Failed to send |

### Target Types

| Type | Description | Required Fields |
|------|-------------|-----------------|
| `single` | Single user | `targetUserIds` (1 user) |
| `custom` | Multiple specific users | `targetUserIds` (multiple) |
| `role` | Users with specific roles | `targetRoles` |
| `all` | All users | None |

---

## Error Handling

### Common Errors

#### Permission Denied

```json
{
  "success": false,
  "error": "Permission denied. Only developers and authorities can create notifications."
}
```

**Solution:** Ensure the user has the required role.

#### Validation Failed

```json
{
  "success": false,
  "error": "Validation failed",
  "validation_errors": [
    "Title is required",
    "Message exceeds maximum length of 500 characters"
  ]
}
```

**Solution:** Fix the validation errors listed.

#### Cannot Update Sent Notification

```json
{
  "success": false,
  "error": "Cannot update notification with status 'sent'. Sent notifications are immutable."
}
```

**Solution:** Sent notifications cannot be modified. Create a new notification instead.

#### Rate Limit Exceeded

```json
{
  "success": false,
  "error": "Rate limit exceeded. Maximum 100 notifications per hour."
}
```

**Solution:** Wait before sending more notifications or contact an administrator.

---

## Rate Limiting

### Limits

| Operation | Limit | Window |
|-----------|-------|--------|
| Create notification | 100 | 1 hour |
| Broadcast to all | 10 | 1 hour |
| Update notification | 200 | 1 hour |

### Handling Rate Limits

```dart
try {
  await api.createNotification(...);
} catch (e) {
  if (e.toString().contains('Rate limit exceeded')) {
    // Show user-friendly message
    showError('You are sending notifications too quickly. Please wait a moment.');
  }
}
```

---

## Examples

### Example 1: Send Immediate Notification

```dart
final api = NotificationApi();

final result = await api.createNotification(
  createdBy: currentUserId,
  title: 'Report Verified',
  message: 'Your road hazard report has been verified by authorities',
  type: 'success',
  targetType: 'single',
  targetUserIds: [reportAuthorId],
  sound: 'success',
  priority: 6,
  data: {
    'report_id': reportId,
    'action': 'view_report',
  },
);

print('Notification sent: ${result['id']}');
```

### Example 2: Schedule Notification

```dart
final scheduledTime = DateTime.now().add(Duration(hours: 24));

final result = await api.createNotification(
  createdBy: currentUserId,
  title: 'Maintenance Reminder',
  message: 'System maintenance will begin in 1 hour',
  type: 'system',
  status: 'scheduled',
  scheduledAt: scheduledTime,
  targetType: 'all',
  sound: 'default',
  priority: 7,
);

print('Notification scheduled for: ${scheduledTime.toIso8601String()}');
```

### Example 3: Send to Multiple Users

```dart
// Get nearby users
final nearbyUsers = await getNearbyUsers(
  latitude: 37.7749,
  longitude: -122.4194,
  radiusKm: 5.0,
);

final result = await api.createNotification(
  createdBy: currentUserId,
  title: '⚠️ Road Hazard Nearby',
  message: 'A pothole was reported 2km from your location',
  type: 'location_alert',
  targetType: 'custom',
  targetUserIds: nearbyUsers.map((u) => u.id).toList(),
  sound: 'alert',
  category: 'alert',
  priority: 8,
  data: {
    'report_id': reportId,
    'latitude': 37.7749,
    'longitude': -122.4194,
    'distance_km': 2.0,
  },
);

print('Sent to ${nearbyUsers.length} nearby users');
```

### Example 4: Send to Role

```dart
final result = await api.createNotification(
  createdBy: currentUserId,
  title: 'New Authority Request',
  message: 'A user has requested authority access',
  type: 'user',
  targetType: 'role',
  targetRoles: ['admin', 'developer'],
  sound: 'default',
  priority: 6,
  data: {
    'request_id': requestId,
    'action': 'view_request',
  },
);
```

### Example 5: Save as Draft

```dart
final draft = await api.createNotification(
  createdBy: currentUserId,
  title: 'Draft Announcement',
  message: 'This will be reviewed before sending',
  type: 'promotion',
  status: 'draft',
  targetType: 'all',
);

// Later, update and send
await api.updateNotification(
  notificationId: draft['id'],
  title: 'Final Announcement',
  message: 'Reviewed and approved message',
  type: 'promotion',
  status: 'sent', // Triggers immediate send
);
```

### Example 6: Filter User Notifications

```dart
// Get unread alerts from last 24 hours
final recentAlerts = await api.getUserNotifications(
  userId: currentUserId,
  type: 'alert',
  isRead: false,
  startDate: DateTime.now().subtract(Duration(hours: 24)),
);

print('You have ${recentAlerts.length} unread alerts');
```

### Example 7: Data Notification (Silent)

```dart
// Register action handler in OneSignalService
oneSignalService.registerActionHandler('refresh_reports', (data) async {
  final category = data['category'] as String?;
  await reportRepository.refreshReports(category: category);
});

// Send data notification from backend
await oneSignalService.sendDataNotification(
  userIds: [userId],
  data: {
    'action_type': 'refresh_reports',
    'category': 'safety',
  },
);
```

---

## Testing

### Test Notification Creation

```dart
// Test creating a notification
final testNotification = await api.createNotification(
  createdBy: testUserId,
  title: 'Test Notification',
  message: 'This is a test',
  type: 'info',
  targetType: 'single',
  targetUserIds: [testUserId],
);

assert(testNotification['status'] == 'sent');
```

### Test Scheduled Notification

```dart
// Create scheduled notification
final scheduled = await api.createNotification(
  createdBy: testUserId,
  title: 'Scheduled Test',
  message: 'This should be sent later',
  type: 'info',
  status: 'scheduled',
  scheduledAt: DateTime.now().add(Duration(minutes: 5)),
  targetType: 'single',
  targetUserIds: [testUserId],
);

// Manually trigger processing (for testing)
final result = await api.testProcessScheduledNotification(scheduled['id']);
assert(result['success'] == true);
```

---

## Best Practices

1. **Use appropriate notification types** - Choose the type that best matches the content
2. **Include actionable data** - Add data payload for navigation
3. **Set appropriate priorities** - Higher priority for urgent notifications
4. **Use custom sounds** - Different sounds for different notification types
5. **Respect user preferences** - Check notification settings before sending
6. **Handle errors gracefully** - Always wrap API calls in try-catch
7. **Test on real devices** - Push notifications don't work on simulators
8. **Monitor delivery stats** - Check OneSignal dashboard for delivery rates
9. **Don't spam users** - Respect rate limits and user preferences
10. **Localize messages** - Support multiple languages

---

## Related Documentation

- [User Guide](./USER_GUIDE.md) - End-user documentation
- [Notification Usage Guide](./NOTIFICATION_USAGE.md) - Quick reference
- [OneSignal Setup](./ONESIGNAL_SETUP.md) - OneSignal configuration
- [Database Schema](../database/schema.sql) - Database structure

---

**Last Updated**: 2024-11-25  
**Version**: 2.0.0  
**Maintainer**: Pavra Team
