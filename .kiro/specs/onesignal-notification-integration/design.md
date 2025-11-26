# Design Document

## Overview

This design document outlines the architecture and implementation details for integrating OneSignal push notifications into the existing notification system. The solution enhances the current notification infrastructure with real-time push delivery, notification categories, custom sounds, data notifications, and comprehensive CRUD operations.

The design leverages the existing two-table architecture (`notifications` and `user_notifications`) and extends it with OneSignal integration on both the Flutter client and Serverpod backend. The system supports multiple delivery modes (immediate, scheduled, draft), various targeting strategies (single, custom, role-based, broadcast), and rich notification features including categories, sounds, and deep linking.

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Client                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ OneSignalService │  │ NotificationAPI  │  │ UI Components │ │
│  │  - Initialize    │  │  - CRUD Ops      │  │  - List       │ │
│  │  - Register      │  │  - Filtering     │  │  - Form       │ │
│  │  - Handle Events │  │  - Status Track  │  │  - Detail     │ │
│  └──────────────────┘  └──────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ▲ │
                              │ │ HTTP/Supabase
                              │ ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Supabase Backend                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ notifications    │  │ user_            │  │ Database      │ │
│  │ table            │  │ notifications    │  │ Functions     │ │
│  │  - Definitions   │  │ table            │  │  - Triggers   │ │
│  │  - Metadata      │  │  - User Records  │  │  - Auto-      │ │
│  │  - Status        │  │  - Read Status   │  │    Create     │ │
│  └──────────────────┘  └──────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ▲ │
                              │ │ HTTP
                              │ ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Serverpod Server                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ OneSignalService │  │ Notification     │  │ QStash        │ │
│  │  - Send Push     │  │ Endpoints        │  │ Scheduler     │ │
│  │  - Schedule      │  │  - Create        │  │  - Delayed    │ │
│  │  - Cancel        │  │  - Process       │  │    Delivery   │ │
│  │  - Track Status  │  │  - Handle Events │  │               │ │
│  └──────────────────┘  └──────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ▲ │
                              │ │ REST API
                              │ ▼
┌─────────────────────────────────────────────────────────────────┐
│                      OneSignal Service                           │
├─────────────────────────────────────────────────────────────────┤
│  - Push Notification Delivery                                    │
│  - Device Registration                                           │
│  - User Targeting                                                │
│  - Delivery Analytics                                            │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

#### Immediate Notification Flow
1. Developer creates notification with status='sent' via Flutter UI
2. Flutter calls NotificationAPI.createNotification()
3. Supabase inserts record into `notifications` table
4. Database trigger creates records in `user_notifications` table
5. Flutter calls Serverpod endpoint `/notification/handleNotificationCreated`
6. Serverpod OneSignalService sends push notification via OneSignal REST API
7. OneSignal delivers push to target devices
8. Devices receive and display notification

#### Scheduled Notification Flow
1. Developer creates notification with status='scheduled' and future timestamp
2. Flutter calls NotificationAPI.createNotification()
3. Supabase inserts record into `notifications` table (no user_notifications yet)
4. Flutter calls Serverpod endpoint `/notification/scheduleNotificationById`
5. Serverpod schedules job via QStash for future execution
6. At scheduled time, QStash triggers Serverpod webhook
7. Serverpod updates notification status to 'sent'
8. Database trigger creates user_notifications records
9. Serverpod sends push notification via OneSignal
10. OneSignal delivers push to target devices

#### Draft Notification Flow
1. Developer creates notification with status='draft'
2. Flutter calls NotificationAPI.createNotification()
3. Supabase inserts record into `notifications` table
4. No further action until developer updates status

## Components and Interfaces

### Flutter Client Components

#### OneSignalService (Enhanced)

```dart
class OneSignalService {
  // Initialization
  Future<void> initialize();
  
  // User Management
  Future<void> setExternalUserId(String userId);
  Future<void> removeExternalUserId();
  
  // Event Handlers
  void setupNotificationHandlers();
  void handleNotificationClick(Map<String, dynamic> data);
  void handleForegroundNotification(OSNotification notification);
  
  // Permission Management
  Future<bool> requestPermission();
  bool get areNotificationsEnabled;
  
  // Tags and Targeting
  Future<void> setTags(Map<String, String> tags);
  Future<void> removeTags(List<String> keys);
  
  // Navigation
  void navigateToScreen(String route, Map<String, dynamic>? params);
  
  // Properties
  String? get playerId;
  bool get isInitialized;
}
```

#### NotificationAPI (Enhanced)

```dart
class NotificationAPI {
  // CRUD Operations
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
    String? oneSignalNotificationId,
  });
  
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
  });
  
  Future<void> deleteNotification({required String notificationId});
  Future<void> hardDeleteNotification({required String notificationId});
  
  // Query Operations
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    String? type,
    bool? isRead,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<List<Map<String, dynamic>>> getAllNotifications({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // User Actions
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  });
  
  Future<void> markAllAsRead(String userId);
  
  Future<void> deleteNotificationForUser({
    required String notificationId,
    required String userId,
  });
  
  // Status Tracking
  Future<Map<String, dynamic>> getNotificationStatus(String notificationId);
  Future<int> getUnreadCount(String userId);
}
```

### Serverpod Server Components

#### OneSignalService (Enhanced)

```dart
class OneSignalService {
  // Basic Sending
  Future<OneSignalResponse> sendToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
  });
  
  Future<OneSignalResponse> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
  });
  
  Future<OneSignalResponse> sendToAll({
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
  });
  
  Future<OneSignalResponse> sendWithFilters({
    required String title,
    required String message,
    required List<Map<String, dynamic>> filters,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
  });
  
  // Data Notifications
  Future<OneSignalResponse> sendDataNotification({
    required List<String> userIds,
    required Map<String, dynamic> data,
  });
  
  // Scheduling
  Future<OneSignalResponse> scheduleNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required DateTime sendAt,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
  });
  
  Future<void> cancelScheduledNotification(String oneSignalNotificationId);
  
  // Status and Analytics
  Future<Map<String, dynamic>> getNotificationStatus(String oneSignalNotificationId);
  Future<Map<String, dynamic>> getDeliveryStats(String oneSignalNotificationId);
}
```

#### NotificationEndpoint (Enhanced)

```dart
class NotificationEndpoint extends Endpoint {
  // Webhook Handlers
  Future<void> handleNotificationCreated(Session session, String notificationId);
  Future<void> handleScheduledNotification(Session session, String notificationId);
  
  // Scheduling
  Future<void> scheduleNotificationById(
    Session session,
    String notificationId,
    DateTime scheduledAt,
  );
  
  // Status Updates
  Future<void> updateNotificationStatus(
    Session session,
    String notificationId,
    String status,
    String? oneSignalNotificationId,
    String? errorMessage,
  );
  
  // Testing
  Future<Map<String, dynamic>> testProcessScheduledNotification(
    Session session,
    String notificationId,
  );
}
```

## Data Models

### Database Schema Enhancements

#### notifications table (Enhanced)

```sql
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (
    type IN (
      'success', 'warning', 'alert', 'info',
      'system', 'user', 'report', 'location_alert',
      'submission_status', 'promotion', 'reminder'
    )
  ),
  related_action UUID REFERENCES action_log(id) ON DELETE SET NULL,
  data JSONB DEFAULT '{}',
  status TEXT DEFAULT 'sent' CHECK (
    status IN ('draft', 'scheduled', 'sent', 'failed')
  ),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  target_type TEXT DEFAULT 'single' CHECK (
    target_type IN ('single', 'all', 'role', 'custom')
  ),
  target_roles TEXT[],
  target_user_ids UUID[],
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  
  -- OneSignal Integration Fields (NEW)
  onesignal_notification_id TEXT,
  sound TEXT,
  category TEXT,
  priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
  error_message TEXT,
  recipients_count INTEGER,
  successful_deliveries INTEGER,
  failed_deliveries INTEGER
);
```

#### user_notifications table (No changes needed)

The existing schema is sufficient for user-level notification management.

### Dart Models

#### NotificationModel (Enhanced)

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
  
  // User-specific fields (from user_notifications join)
  final bool isRead;
  final DateTime? readAt;
  final NotificationSource source;
}
```

#### OneSignalResponse

```dart
class OneSignalResponse {
  final String id;
  final int recipients;
  final Map<String, dynamic>? errors;
  
  bool get isSuccess => errors == null || errors!.isEmpty;
}
```

#### NotificationCategory

```dart
enum NotificationCategory {
  alarm('alarm'),
  call('call'),
  email('email'),
  error('err'),
  event('event'),
  message('msg'),
  navigation('navigation'),
  progress('progress'),
  promo('promo'),
  recommendation('recommendation'),
  reminder('reminder'),
  service('service'),
  social('social'),
  status('status'),
  system('sys'),
  transport('transport');
  
  final String value;
  const NotificationCategory(this.value);
}
```

## Error Handling

### Error Types

1. **OneSignal API Errors**
   - Invalid API key
   - Rate limiting
   - Network failures
   - Invalid payload

2. **Database Errors**
   - Constraint violations
   - Connection failures
   - Transaction rollbacks

3. **Scheduling Errors**
   - QStash failures
   - Invalid schedule times
   - Missed schedules

4. **Validation Errors**
   - Invalid notification data
   - Missing required fields
   - Invalid target specifications

### Error Handling Strategy

```dart
// Client-side error handling
try {
  await notificationAPI.createNotification(...);
} on NetworkException catch (e) {
  // Show network error message
  showError('Network error: ${e.message}');
} on ValidationException catch (e) {
  // Show validation errors
  showError('Validation error: ${e.message}');
} on ApiException catch (e) {
  // Show API error
  showError('API error: ${e.message}');
} catch (e) {
  // Show generic error
  showError('An unexpected error occurred');
}

// Server-side error handling
try {
  final response = await oneSignalService.sendToUser(...);
  if (!response.isSuccess) {
    // Update notification status to failed
    await updateNotificationStatus(
      notificationId,
      'failed',
      null,
      response.errors.toString(),
    );
  }
} catch (e) {
  // Log error and update status
  logger.error('Failed to send notification', error: e);
  await updateNotificationStatus(
    notificationId,
    'failed',
    null,
    e.toString(),
  );
}
```

## Testing Strategy

### Unit Tests

1. **OneSignalService Tests**
   - Test initialization
   - Test user ID linking
   - Test event handler registration
   - Test navigation logic

2. **NotificationAPI Tests**
   - Test CRUD operations
   - Test filtering logic
   - Test status updates
   - Test error handling

3. **Model Tests**
   - Test JSON serialization/deserialization
   - Test model validation
   - Test copyWith methods

### Integration Tests

1. **End-to-End Notification Flow**
   - Create notification → Send push → Receive on device
   - Schedule notification → Wait → Receive at scheduled time
   - Update draft → Send → Receive on device

2. **User Interaction Tests**
   - Tap notification → Navigate to correct screen
   - Mark as read → Update UI
   - Delete notification → Remove from list

3. **Multi-User Tests**
   - Send to multiple users → All receive
   - Send to role → Only role members receive
   - Send to all → All users receive

### Property-Based Tests

Property-based tests will be defined in the Correctness Properties section below.


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing all acceptance criteria, several properties can be consolidated to reduce redundancy:

- Properties 6.1-6.4 (notification type mapping) can be combined into a single property about type-to-configuration mapping
- Properties 2.4-2.7 (targeting) can be combined into a single property about target resolution
- Properties 12.3-12.6 (filtering) can be combined into a single property about filter correctness

### Core Properties

**Property 1: Initialization establishes OneSignal connection**
*For any* device initialization, after successful initialization, the OneSignal service should have a valid player ID
**Validates: Requirements 1.1**

**Property 2: Login-logout round trip clears external user ID**
*For any* user, logging in then logging out should result in no external user ID being set in OneSignal
**Validates: Requirements 1.2, 1.3**

**Property 3: Notification display preserves content**
*For any* notification sent via OneSignal, the displayed notification title and message should match the sent notification data
**Validates: Requirements 1.4**

**Property 4: Notification navigation matches payload**
*For any* notification with navigation data, tapping the notification should navigate to the screen specified in the payload
**Validates: Requirements 1.5**

**Property 5: Sent notifications trigger immediate delivery**
*For any* notification created with status='sent', the system should make a OneSignal API call within a reasonable timeout
**Validates: Requirements 2.1**

**Property 6: Scheduled notifications create scheduling jobs**
*For any* notification created with status='scheduled' and a future timestamp, the system should create a corresponding QStash job
**Validates: Requirements 2.2**

**Property 7: Draft notifications do not trigger delivery**
*For any* notification created with status='draft', the system should not make OneSignal API calls or create QStash jobs
**Validates: Requirements 2.3**

**Property 8: Target resolution creates correct user notification records**
*For any* notification with a target specification (single, custom, role, all), the number and identity of user_notification records should match the resolved target users
**Validates: Requirements 2.4, 2.5, 2.6, 2.7**

**Property 9: Sent notifications have user notification records**
*For any* notification with status='sent', there should exist at least one corresponding user_notification record
**Validates: Requirements 2.8**

**Property 10: Draft updates do not trigger delivery**
*For any* notification with status='draft', updating its fields should not trigger OneSignal API calls
**Validates: Requirements 3.1**

**Property 11: Status transition to sent triggers delivery**
*For any* notification updated from status='draft' to status='sent', the system should make a OneSignal API call
**Validates: Requirements 3.2**

**Property 12: Status transition to scheduled creates scheduling job**
*For any* notification updated from status='draft' to status='scheduled', the system should create a QStash job
**Validates: Requirements 3.3**

**Property 13: Sent notifications are immutable**
*For any* notification with status='sent', attempting to update it should result in an error
**Validates: Requirements 3.4**

**Property 14: Scheduled notification updates cancel previous schedule**
*For any* scheduled notification that is updated, the previous QStash job should be cancelled and a new one created
**Validates: Requirements 3.5**

**Property 15: Draft deletion is soft delete**
*For any* notification with status='draft', deleting it should set is_deleted=true without removing the record
**Validates: Requirements 4.1**

**Property 16: Scheduled deletion cancels OneSignal notification**
*For any* notification with status='scheduled', deleting it should cancel the OneSignal scheduled notification and set is_deleted=true
**Validates: Requirements 4.2**

**Property 17: Sent notifications cannot be deleted**
*For any* notification with status='sent', attempting to delete it should result in an error
**Validates: Requirements 4.3**

**Property 18: Hard delete cascades to user notifications**
*For any* notification that is hard deleted, all associated user_notification records should also be removed
**Validates: Requirements 4.4**

**Property 19: Mark as read updates fields correctly**
*For any* user notification marked as read, both is_read should be true and read_at should be set to a valid timestamp
**Validates: Requirements 5.1**

**Property 20: Mark all as read clears unread count**
*For any* user, after marking all notifications as read, the unread count should be zero
**Validates: Requirements 5.2**

**Property 21: User deletion is isolated**
*For any* notification deleted by one user, other users' user_notification records for the same notification should remain unchanged
**Validates: Requirements 5.3**

**Property 22: Deleted notifications are filtered from view**
*For any* user's notification list, no notification with is_deleted=true should be included
**Validates: Requirements 5.4**

**Property 23: Notification type maps to correct configuration**
*For any* notification type (alert, warning, info, success), the OneSignal payload should contain the correct priority and sound values according to the type mapping
**Validates: Requirements 6.1, 6.2, 6.3, 6.4**

**Property 24: Category is included in payload**
*For any* notification created with a category, the OneSignal payload should contain that category value
**Validates: Requirements 6.5**

**Property 25: Data-only notifications are silent**
*For any* notification with data payload but no title or message, the OneSignal payload should be configured as a silent notification
**Validates: Requirements 7.1**

**Property 26: Data notification action handlers are invoked**
*For any* data notification with an action type, the corresponding action handler should be called
**Validates: Requirements 7.3**

**Property 27: Data notification errors are logged without crashing**
*For any* data notification that fails to process, an error should be logged and the app should continue running
**Validates: Requirements 7.4**

**Property 28: Custom sound is included in payload**
*For any* notification created with a custom sound parameter, the OneSignal payload should contain that sound value
**Validates: Requirements 8.1**

**Property 29: Default sound when no sound specified**
*For any* notification created without a sound parameter, the OneSignal payload should not include a sound field (allowing OS default)
**Validates: Requirements 8.4**

**Property 30: Navigation data extraction is correct**
*For any* notification with navigation data, the extracted route should match the route specified in the payload
**Validates: Requirements 9.1**

**Property 31: Successful send stores OneSignal ID**
*For any* notification successfully sent via OneSignal, the onesignal_notification_id field should be populated with the returned ID
**Validates: Requirements 10.1**

**Property 32: Failed send updates status**
*For any* notification that fails to send, the status should be updated to 'failed' and error_message should be populated
**Validates: Requirements 10.2**

**Property 33: Scheduled notification processing updates status**
*For any* scheduled notification that is processed, the status should change from 'scheduled' to 'sent' and sent_at should be set
**Validates: Requirements 10.3**

**Property 34: Status query returns current state**
*For any* notification, querying its status should return values that match the current database record
**Validates: Requirements 10.4**

**Property 35: Delivery statistics are stored**
*For any* notification with OneSignal delivery statistics, the recipients_count and successful_deliveries fields should be populated
**Validates: Requirements 10.5**

**Property 36: System events trigger notifications**
*For any* system event (report creation, verification, reputation change, request status change, maintenance), a corresponding notification should be created
**Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5**

**Property 37: User notifications are correctly filtered**
*For any* user requesting their notifications, all returned notifications should have a user_notification record for that user
**Validates: Requirements 12.1**

**Property 38: All notifications query returns complete set**
*For any* developer requesting all notifications, the returned count should match the total count of non-deleted notifications in the database
**Validates: Requirements 12.2**

**Property 39: Filters return only matching notifications**
*For any* filter criteria (type, status, date range, read status), all returned notifications should satisfy the filter condition
**Validates: Requirements 12.3, 12.4, 12.5, 12.6**

### Example-Based Tests

**Example 1: Report detail navigation**
Given a notification with data: `{"type": "report", "report_id": "123"}`, tapping should navigate to `/report/123`
**Validates: Requirements 9.2**

**Example 2: User profile navigation**
Given a notification with data: `{"type": "user", "user_id": "456"}`, tapping should navigate to `/profile/456`
**Validates: Requirements 9.3**

**Example 3: Default navigation**
Given a notification with no navigation data, tapping should navigate to `/home`
**Validates: Requirements 9.4**

## Implementation Notes

### OneSignal Configuration

#### Client-Side (Flutter)

```dart
// Initialize OneSignal
await OneSignal.initialize(appId);

// Request permission
await OneSignal.Notifications.requestPermission(true);

// Set external user ID on login
OneSignal.login(userId);

// Remove external user ID on logout
OneSignal.logout();

// Handle notification clicks
OneSignal.Notifications.addClickListener((event) {
  final data = event.notification.additionalData;
  handleNotificationClick(data);
});

// Handle foreground notifications
OneSignal.Notifications.addForegroundWillDisplayListener((event) {
  // Show in-app banner or allow default behavior
});
```

#### Server-Side (Serverpod)

```dart
// Send to specific users
final response = await http.post(
  Uri.parse('https://api.onesignal.com/notifications'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Basic $apiKey',
  },
  body: jsonEncode({
    'app_id': appId,
    'include_aliases': {
      'external_id': userIds,
    },
    'target_channel': 'push',
    'headings': {'en': title},
    'contents': {'en': message},
    'data': customData,
    'android_sound': soundFile,
    'android_channel_id': category,
    'priority': priority,
  }),
);
```

### Notification Sounds

Place custom sound files in:
- Android: `android/app/src/main/res/raw/`
- iOS: `ios/Runner/Resources/`

Sound file names:
- `alert.wav` - Critical alerts
- `warning.wav` - Warnings
- `success.wav` - Success notifications
- `default.wav` - Default sound

### Notification Categories (Android)

Create notification channels in Android:

```kotlin
// In MainActivity.kt or Application class
val channels = listOf(
    NotificationChannel("alert", "Alerts", NotificationManager.IMPORTANCE_HIGH),
    NotificationChannel("warning", "Warnings", NotificationManager.IMPORTANCE_DEFAULT),
    NotificationChannel("info", "Information", NotificationManager.IMPORTANCE_LOW),
    NotificationChannel("success", "Success", NotificationManager.IMPORTANCE_DEFAULT)
)

val notificationManager = getSystemService(NotificationManager::class.java)
channels.forEach { notificationManager.createNotificationChannel(it) }
```

### Database Migration

Add new columns to notifications table:

```sql
ALTER TABLE public.notifications
ADD COLUMN onesignal_notification_id TEXT,
ADD COLUMN sound TEXT,
ADD COLUMN category TEXT,
ADD COLUMN priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
ADD COLUMN error_message TEXT,
ADD COLUMN recipients_count INTEGER,
ADD COLUMN successful_deliveries INTEGER,
ADD COLUMN failed_deliveries INTEGER;
```

### QStash Integration

Schedule notifications using QStash:

```dart
// Schedule via QStash
final response = await http.post(
  Uri.parse('https://qstash.upstash.io/v2/publish/$callbackUrl'),
  headers: {
    'Authorization': 'Bearer $qstashToken',
    'Upstash-Delay': '${delaySeconds}s',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'notificationId': notificationId,
  }),
);
```

### Testing with Property-Based Testing

Use the `test` package with custom generators for property-based testing:

```dart
// Example property test
test('Property 8: Target resolution creates correct user notification records', () {
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    // Generate random notification with random target type
    final targetType = ['single', 'custom', 'role', 'all'][random.nextInt(4)];
    final notification = generateRandomNotification(targetType: targetType);
    
    // Create notification
    final result = await createNotification(notification);
    
    // Query user_notifications
    final userNotifications = await getUserNotifications(result.id);
    
    // Verify count matches expected
    final expectedCount = calculateExpectedRecipients(notification);
    expect(userNotifications.length, equals(expectedCount));
  }
});
```

## Security Considerations

1. **API Key Protection**
   - Store OneSignal API keys in environment variables
   - Never expose API keys in client-side code
   - Use server-side endpoints for all OneSignal API calls

2. **User Authorization**
   - Verify user permissions before creating notifications
   - Ensure users can only delete their own user_notification records
   - Restrict admin operations (hard delete, status updates) to authorized roles

3. **Data Validation**
   - Validate all notification data before sending
   - Sanitize user input to prevent injection attacks
   - Limit notification payload size

4. **Rate Limiting**
   - Implement rate limiting on notification creation endpoints
   - Prevent spam by limiting notifications per user per time period
   - Monitor OneSignal API usage to avoid quota exhaustion

## Performance Considerations

1. **Batch Operations**
   - Use batch inserts for user_notifications records
   - Send notifications to multiple users in single OneSignal API call
   - Implement pagination for notification lists

2. **Caching**
   - Cache unread count to reduce database queries
   - Cache user role information for targeting
   - Implement local notification cache on client

3. **Async Processing**
   - Process notification creation asynchronously
   - Use background jobs for scheduled notifications
   - Implement retry logic for failed sends

4. **Database Optimization**
   - Add indexes on frequently queried columns (user_id, status, created_at)
   - Implement soft delete cleanup job for old records
   - Archive old notifications to separate table

## Monitoring and Logging

1. **Metrics to Track**
   - Notification send success rate
   - Average delivery time
   - User engagement (open rate, click rate)
   - Error rates by type

2. **Logging Strategy**
   - Log all notification creation events
   - Log OneSignal API responses
   - Log delivery failures with error details
   - Log user interactions (read, delete, click)

3. **Alerting**
   - Alert on high failure rates
   - Alert on OneSignal API errors
   - Alert on QStash scheduling failures
   - Alert on database constraint violations
