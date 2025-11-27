# Design Document

## Overview

This design document outlines the implementation of automated push notification triggers for business events in the Pavra road safety application. While the OneSignal notification infrastructure is already in place (as implemented in the onesignal-notification-integration spec), the system currently lacks automated notifications for critical user interactions and system events.

This feature will implement 25+ notification trigger points across 8 major modules:
- Report System (submission, verification, voting)
- Authority Request System (submission, approval, rejection)
- Reputation System (changes, milestones)
- AI Detection System (critical hazards, offline sync)
- Route System (monitoring, saves)
- User System (onboarding, role changes)
- System Maintenance (announcements, updates)

The design introduces a centralized NotificationHelperService that simplifies notification creation with pre-configured templates, and extends existing APIs with methods for nearby user and route monitoring resolution.

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Business Event Sources                        │
├─────────────────────────────────────────────────────────────────┤
│  ReportIssueApi  │  AuthorityRequestApi  │  ReputationApi       │
│  AiDetectionApi  │  SavedRouteApi        │  UserApi             │
└────────────┬────────────────────────────────────────────────────┘
             │ Triggers
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              NotificationHelperService (NEW)                     │
├─────────────────────────────────────────────────────────────────┤
│  - notifyReportSubmitted()                                       │
│  - notifyNearbyUsers()                                           │
│  - notifyReportVerified()                                        │
│  - notifyRequestApproved()                                       │
│  - notifyReputationChange()                                      │
│  - notifyCriticalDetection()                                     │
│  - ... (25+ notification methods)                                │
└────────────┬────────────────────────────────────────────────────┘
             │ Uses
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              NotificationAPI (Existing)                          │
├─────────────────────────────────────────────────────────────────┤
│  - createNotification()                                          │
│  - Handles OneSignal integration                                 │
│  - Manages database records                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Example: Report Submission

```
1. User submits report
   ↓
2. ReportIssueApi.submitReport()
   ↓
3. Report saved to database
   ↓
4. NotificationHelperService.notifyReportSubmitted(userId, reportId)
   ↓
5. NotificationAPI.createNotification() → Success notification
   ↓
6. UserApi.getNearbyUsers(lat, lng, radius)
   ↓
7. NotificationHelperService.notifyNearbyUsers(reportId, nearbyUserIds)
   ↓
8. NotificationAPI.createNotification() → Location alert
   ↓
9. OneSignal delivers push notifications
```


## Components and Interfaces

### NotificationHelperService (NEW)

A centralized service that provides pre-configured notification methods for all business events.

```dart
class NotificationHelperService {
  final NotificationApi _notificationApi;
  
  NotificationHelperService(this._notificationApi);
  
  // ========== Report Notifications ==========
  
  Future<void> notifyReportSubmitted({
    required String userId,
    required String reportId,
    required String title,
  });
  
  Future<void> notifyNearbyUsers({
    required String reportId,
    required String title,
    required double latitude,
    required double longitude,
    required String severity,
    required List<String> nearbyUserIds,
  });
  
  Future<void> notifyReportVerified({
    required String userId,
    required String reportId,
    required String reviewerId,
  });
  
  Future<void> notifyReportSpam({
    required String userId,
    required String reportId,
    required String reviewerId,
    String? comment,
  });
  
  Future<void> notifyVoteThreshold({
    required String userId,
    required String reportId,
    required String voteType, // 'verified' or 'spam'
    required int voteCount,
  });
  
  // ========== Authority Request Notifications ==========
  
  Future<void> notifyRequestSubmitted({
    required String userId,
    required String requestId,
  });
  
  Future<void> notifyRequestApproved({
    required String userId,
    required String requestId,
    required String reviewerId,
  });
  
  Future<void> notifyRequestRejected({
    required String userId,
    required String requestId,
    required String reviewerId,
    String? comment,
  });
  
  Future<void> notifyAdminsNewRequest({
    required String requestId,
    required String userId,
    required String username,
  });
  
  // ========== Reputation Notifications ==========
  
  Future<void> notifyReputationChange({
    required String userId,
    required int changeAmount,
    required String actionType,
    required int scoreAfter,
  });
  
  Future<void> notifyReputationMilestone({
    required String userId,
    required int milestone,
  });
  
  // ========== AI Detection Notifications ==========
  
  Future<void> notifyCriticalDetection({
    required String userId,
    required String detectionId,
    required String issueType,
    required String severity,
    required double latitude,
    required double longitude,
    required double confidence,
  });
  
  Future<void> notifyOfflineQueueProcessed({
    required String userId,
    required int processedCount,
  });
  
  // ========== Route Notifications ==========
  
  Future<void> notifyMonitoredRouteIssue({
    required String reportId,
    required String title,
    required double latitude,
    required double longitude,
    required List<String> monitoringUserIds,
  });
  
  Future<void> notifyRouteSaved({
    required String userId,
    required String routeId,
    required String routeName,
  });
  
  Future<void> notifyRouteMonitoringEnabled({
    required String userId,
    required String routeId,
    required String routeName,
  });
  
  // ========== User Notifications ==========
  
  Future<void> notifyWelcomeNewUser({
    required String userId,
  });
  
  Future<void> notifyRoleChanged({
    required String userId,
    required String newRole,
  });
  
  // ========== System Notifications ==========
  
  Future<void> notifySystemMaintenance({
    required DateTime maintenanceStart,
    required DateTime maintenanceEnd,
  });
  
  Future<void> notifyAppUpdate({
    required String newVersion,
    required String updateUrl,
    String? releaseNotes,
  });
  
  Future<void> notifyImportantAnnouncement({
    required String adminId,
    required String title,
    required String message,
    String? announcementId,
  });
}
```

### UserApi Extensions (NEW)

```dart
class UserApi {
  /// Get users within radius of a location who have location alerts enabled
  Future<List<String>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });
}
```

### SavedRouteApi Extensions (NEW)

```dart
class SavedRouteApi {
  /// Get users monitoring routes that pass through a location
  Future<List<String>> getUsersMonitoringRoute({
    required double latitude,
    required double longitude,
    double bufferKm = 0.5,
  });
}
```


## Data Models

### Notification Configuration

```dart
class NotificationConfig {
  final String type;
  final String sound;
  final String category;
  final int priority;
  
  const NotificationConfig({
    required this.type,
    required this.sound,
    required this.category,
    required this.priority,
  });
  
  // Pre-configured notification types
  static const reportSuccess = NotificationConfig(
    type: 'success',
    sound: 'success',
    category: 'status',
    priority: 5,
  );
  
  static const nearbyAlert = NotificationConfig(
    type: 'location_alert',
    sound: 'alert',
    category: 'alert',
    priority: 8,
  );
  
  static const criticalAlert = NotificationConfig(
    type: 'alert',
    sound: 'alert',
    category: 'alert',
    priority: 10,
  );
  
  static const authorityApproved = NotificationConfig(
    type: 'success',
    sound: 'success',
    category: 'status',
    priority: 9,
  );
  
  static const reputationIncrease = NotificationConfig(
    type: 'success',
    sound: 'success',
    category: 'status',
    priority: 5,
  );
  
  static const reputationDecrease = NotificationConfig(
    type: 'warning',
    sound: 'warning',
    category: 'warning',
    priority: 6,
  );
}
```

### Database Functions (NEW)

#### get_nearby_users

```sql
CREATE OR REPLACE FUNCTION get_nearby_users(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT p.id
  FROM profiles p
  INNER JOIN user_alert_preferences uap ON p.id = uap.user_id
  WHERE 
    -- User has location alerts enabled
    uap.location_alerts_enabled = true
    -- User's alert radius covers this location
    AND uap.alert_radius_km >= radius_km
    -- User has notifications enabled globally
    AND p.notifications_enabled = true
    -- Don't notify the reporter themselves
    AND p.id != auth.uid()
    -- User is not deleted
    AND p.is_deleted = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### get_users_monitoring_route

```sql
CREATE OR REPLACE FUNCTION get_users_monitoring_route(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  buffer_km DOUBLE PRECISION DEFAULT 0.5
)
RETURNS TABLE (user_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT sr.user_id
  FROM saved_routes sr
  WHERE 
    -- Route monitoring is enabled
    sr.is_monitoring = true
    -- Route is not deleted
    AND sr.is_deleted = false
    -- Route passes within buffer distance of the location
    -- (This requires PostGIS extension for spatial queries)
    -- Simplified version: check if any waypoint is within buffer
    AND EXISTS (
      SELECT 1
      FROM route_waypoints rw
      WHERE rw.route_id = sr.id
      AND ST_DWithin(
        ST_MakePoint(rw.longitude, rw.latitude)::geography,
        ST_MakePoint(lng, lat)::geography,
        buffer_km * 1000 -- Convert km to meters
      )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing all acceptance criteria, several properties can be consolidated:
- Properties 10.2-10.5 (nearby user filtering) can be combined into a single comprehensive filtering property
- Properties 11.2-11.4 (route monitoring filtering) can be combined into a single comprehensive filtering property
- Properties 13.1-13.5 (error handling) can be combined into a single graceful error handling property

### Report Notification Properties

**Property 1: Report submission creates success notification**
*For any* successful report submission, a success notification should be created for the report creator
**Validates: Requirements 1.1**

**Property 2: Report submission queries nearby users**
*For any* report submission with valid location, the system should query for nearby users within the specified radius
**Validates: Requirements 1.2**

**Property 3: Nearby users receive location alerts**
*For any* report submission where nearby users exist, location alert notifications should be created for all nearby users
**Validates: Requirements 1.3**

**Property 4: Nearby alerts contain report details**
*For any* nearby user notification, the notification data should include report ID, location (latitude, longitude), and severity
**Validates: Requirements 1.4**

**Property 5: Report verification creates success notification**
*For any* report marked as reviewed by an authority, a success notification should be created for the report creator
**Validates: Requirements 2.1**

**Property 6: Report spam creates warning notification**
*For any* report marked as spam by an authority, a warning notification should be created for the report creator including the spam reason
**Validates: Requirements 2.2**

**Property 7: Vote threshold notifications include count**
*For any* vote threshold notification (verification or spam), the notification data should include the vote count
**Validates: Requirements 2.5**

### Authority Request Properties

**Property 8: Request submission creates confirmation**
*For any* authority request submission, an info notification should be created for the requester
**Validates: Requirements 3.1**

**Property 9: Request approval creates high-priority notification**
*For any* approved authority request, a success notification with priority >= 9 should be created for the requester
**Validates: Requirements 3.2**

**Property 10: Request rejection includes reason**
*For any* rejected authority request, a warning notification should be created for the requester including the rejection reason
**Validates: Requirements 3.3**

**Property 11: New requests notify admins**
*For any* new authority request submission, info notifications should be created for all users with developer or admin roles
**Validates: Requirements 3.4**

**Property 12: Admin notifications include request details**
*For any* admin notification about a new request, the notification data should include the requester's user ID and request ID
**Validates: Requirements 3.5**

### Reputation Properties

**Property 13: Positive reputation change creates success notification**
*For any* reputation increase (changeAmount > 0), a success notification should be created showing points gained and reason
**Validates: Requirements 4.1**

**Property 14: Negative reputation change creates warning notification**
*For any* reputation decrease (changeAmount < 0), a warning notification should be created showing points lost and reason
**Validates: Requirements 4.2**

**Property 15: Milestone notifications include achievement messages**
*For any* reputation milestone notification (25, 50, 75, 100), the notification should include achievement-specific messages and icons
**Validates: Requirements 4.4**

### AI Detection Properties

**Property 16: Critical detections create maximum priority alerts**
*For any* AI detection with severity 'critical', an alert notification with priority = 10 should be created
**Validates: Requirements 5.1**

**Property 17: High severity detections create high priority alerts**
*For any* AI detection with severity 'high', an alert notification with priority >= 8 should be created
**Validates: Requirements 5.2**

**Property 18: Critical detection alerts include detection details**
*For any* critical or high severity detection notification, the notification data should include detection type, confidence, and location
**Validates: Requirements 5.3**

**Property 19: Offline queue processing includes sync count**
*For any* offline detection queue processing notification, the notification message should include the number of synced detections
**Validates: Requirements 5.5**

### Route Monitoring Properties

**Property 20: Report submission queries monitored routes**
*For any* report submission with valid location, the system should query for users monitoring routes within 500m of the location
**Validates: Requirements 6.1**

**Property 21: Monitored route users receive alerts**
*For any* report submission where monitoring users exist, location alert notifications should be created for those users
**Validates: Requirements 6.2**

**Property 22: Route monitoring alerts include route information**
*For any* route monitoring notification, the notification data should include report details and affected route information
**Validates: Requirements 6.3**

**Property 23: Route save creates confirmation**
*For any* successful route save, a success notification should be created for the user
**Validates: Requirements 6.4**

**Property 24: Route monitoring enablement creates confirmation**
*For any* route monitoring enablement, an info notification should be created for the user
**Validates: Requirements 6.5**

### User Onboarding Properties

**Property 25: New user profile creates welcome notification**
*For any* new user profile creation, an info notification with onboarding guidance should be created for the user
**Validates: Requirements 7.1, 7.2**

**Property 26: Role change creates notification with new role**
*For any* user role change (where new role != old role), an info notification should be created including the new role name
**Validates: Requirements 7.3, 7.4**

### System Maintenance Properties

**Property 27: App update notifications include version details**
*For any* app update notification, the notification data should include the version number and release notes link
**Validates: Requirements 8.5**

**Property 28: Maintenance notifications include time window**
*For any* maintenance notification, the notification data should include maintenance start and end times
**Validates: Requirements 8.4**

**Property 29: System notifications target all users**
*For any* system maintenance, app update, or announcement notification, the target_type should be 'all'
**Validates: Requirements 8.2, 8.3**

### Helper Service Properties

**Property 30: Notification methods configure sound, category, and priority**
*For any* notification created via NotificationHelperService, the notification should have sound, category, and priority automatically configured based on notification type
**Validates: Requirements 9.2**

**Property 31: Notification creation failures are logged without exceptions**
*For any* notification creation failure in NotificationHelperService, an error should be logged and no exception should be thrown
**Validates: Requirements 9.3, 13.1, 13.2**

**Property 32: Notification data validation occurs before creation**
*For any* notification creation with invalid required fields, the system should validate and handle the error before calling NotificationAPI
**Validates: Requirements 9.4**

### User Resolution Properties

**Property 33: Nearby users query applies all filters**
*For any* getNearbyUsers call, the returned users should have location_alerts_enabled=true, notifications_enabled=true, is_deleted=false, and should exclude the current user
**Validates: Requirements 10.2, 10.3, 10.4, 10.5**

**Property 34: Nearby users are within specified radius**
*For any* getNearbyUsers call with radius R, all returned users should be within R kilometers of the specified location
**Validates: Requirements 10.1**

**Property 35: Monitored route query applies all filters**
*For any* getUsersMonitoringRoute call, the returned routes should have is_monitoring=true and is_deleted=false
**Validates: Requirements 11.2, 11.4**

**Property 36: Monitored routes are within buffer distance**
*For any* getUsersMonitoringRoute call with buffer B, all returned routes should pass within B kilometers of the specified location
**Validates: Requirements 11.1**

**Property 37: Monitored route query returns user IDs**
*For any* getUsersMonitoringRoute call, the return value should be a list of user IDs (route owners)
**Validates: Requirements 11.3**

### Integration Properties

**Property 38: Report submission triggers notifications**
*For any* successful ReportIssueApi.submitReport call, both report submission and nearby user notifications should be triggered
**Validates: Requirements 12.1**

**Property 39: Report review triggers verification notification**
*For any* successful ReportIssueApi.markAsReviewed call, a report verification notification should be triggered
**Validates: Requirements 12.2**

**Property 40: Report spam triggers spam notification**
*For any* successful ReportIssueApi.markAsSpam call, a spam notification should be triggered
**Validates: Requirements 12.3**

**Property 41: Reputation change triggers notifications**
*For any* successful ReputationApi.addReputationRecord call, reputation change and (if applicable) milestone notifications should be triggered
**Validates: Requirements 12.4**

**Property 42: Authority status update triggers notifications**
*For any* successful AuthorityRequestApi.updateRequestStatus call, approval or rejection notification should be triggered based on the new status
**Validates: Requirements 12.5**

### Error Handling Properties

**Property 43: Notification failures don't disrupt business logic**
*For any* notification creation failure, the calling business logic should continue execution without throwing exceptions
**Validates: Requirements 13.2, 13.5**

**Property 44: OneSignal unavailability is handled gracefully**
*For any* OneSignal API unavailability, the system should log the failure and continue without crashing
**Validates: Requirements 13.3**

**Property 45: Database query failures are handled gracefully**
*For any* database query failure (nearby users, monitored routes), the system should log the error and skip the affected notifications
**Validates: Requirements 13.4**

**Property 46: Performance warnings are logged for slow operations**
*For any* notification operation exceeding performance thresholds, a performance warning should be logged
**Validates: Requirements 14.5**

### Edge Case Properties

**Property 47: Empty nearby users list doesn't cause errors**
*For any* report submission where getNearbyUsers returns an empty list, no error should occur and no nearby notifications should be created
**Validates: Requirements 1.5**

**Property 48: Zero reputation change skips notification**
*For any* reputation change where changeAmount = 0, no notification should be created
**Validates: Requirements 4.5**

**Property 49: Low severity detections skip notification**
*For any* AI detection with severity 'moderate' or 'low', no notification should be created
**Validates: Requirements 5.4**

**Property 50: Same role change skips notification**
*For any* role change where new role = old role, no notification should be created
**Validates: Requirements 7.5**

**Property 51: Empty monitored routes list doesn't cause errors**
*For any* report submission where getUsersMonitoringRoute returns an empty list, no error should occur and no route monitoring notifications should be created
**Validates: Requirements 11.5**

### Example-Based Tests

**Example 1: Verification vote threshold**
Given a report with 5 verification votes, a community verification notification should be created
**Validates: Requirements 2.3**

**Example 2: Spam vote threshold**
Given a report with 3 spam votes, a community flagging notification should be created
**Validates: Requirements 2.4**

**Example 3: Reputation milestone 25**
Given a user reaching reputation score 25, a milestone notification with bronze achievement message should be created
**Validates: Requirements 4.3**

**Example 4: Reputation milestone 50**
Given a user reaching reputation score 50, a milestone notification with silver achievement message should be created
**Validates: Requirements 4.3**

**Example 5: Reputation milestone 75**
Given a user reaching reputation score 75, a milestone notification with gold achievement message should be created
**Validates: Requirements 4.3**

**Example 6: Reputation milestone 100**
Given a user reaching reputation score 100, a milestone notification with crown achievement message should be created
**Validates: Requirements 4.3**

**Example 7: Maintenance notification timing**
Given a maintenance scheduled for time T, a notification should be created at T - 24 hours
**Validates: Requirements 8.1**

**Example 8: Helper service initialization**
Given NotificationHelperService initialization, all required notification methods should be available
**Validates: Requirements 9.1**


## Error Handling

### Error Handling Strategy

All notification operations should be wrapped in try-catch blocks to prevent disrupting business logic:

```dart
// In NotificationHelperService
Future<void> notifyReportSubmitted({
  required String userId,
  required String reportId,
  required String title,
}) async {
  try {
    await _notificationApi.createNotification(
      createdBy: 'system',
      title: 'Report Submitted Successfully ✅',
      message: 'Your road issue report has been submitted',
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      data: {'action': 'view_report', 'report_id': reportId},
      sound: 'success',
      category: 'status',
      priority: 5,
    );
  } catch (e, stackTrace) {
    // Log error but don't throw - notification failures shouldn't disrupt business logic
    developer.log(
      'Failed to send report submission notification',
      name: 'NotificationHelperService',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
```

### Error Types

1. **Network Errors**: OneSignal API unavailable
   - Log error and continue
   - Don't retry immediately to avoid blocking

2. **Database Errors**: Query failures for nearby users or monitored routes
   - Log error and skip affected notifications
   - Continue with other notification types

3. **Validation Errors**: Invalid notification data
   - Log error with details
   - Skip notification creation

4. **Permission Errors**: User lacks permission to create notifications
   - Log error
   - Skip notification creation

### Logging Strategy

```dart
// Structured logging with context
developer.log(
  'Notification creation failed',
  name: 'NotificationHelperService',
  error: e,
  stackTrace: stackTrace,
  level: 1000, // ERROR level
  time: DateTime.now(),
);

// Performance logging
if (duration > Duration(milliseconds: 500)) {
  developer.log(
    'Slow notification operation: ${duration.inMilliseconds}ms',
    name: 'NotificationHelperService',
    level: 900, // WARNING level
  );
}
```

## Testing Strategy

### Unit Tests

Unit tests will verify individual notification helper methods:

```dart
group('NotificationHelperService', () {
  late MockNotificationApi mockApi;
  late NotificationHelperService service;
  
  setUp(() {
    mockApi = MockNotificationApi();
    service = NotificationHelperService(mockApi);
  });
  
  test('notifyReportSubmitted creates success notification', () async {
    await service.notifyReportSubmitted(
      userId: 'user-123',
      reportId: 'report-456',
      title: 'Test Report',
    );
    
    verify(mockApi.createNotification(
      createdBy: 'system',
      title: contains('Successfully'),
      type: 'success',
      targetUserIds: ['user-123'],
      sound: 'success',
      category: 'status',
      priority: 5,
    )).called(1);
  });
  
  test('notifyNearbyUsers creates location alerts', () async {
    await service.notifyNearbyUsers(
      reportId: 'report-123',
      title: 'Pothole',
      latitude: 40.7128,
      longitude: -74.0060,
      severity: 'high',
      nearbyUserIds: ['user-1', 'user-2', 'user-3'],
    );
    
    verify(mockApi.createNotification(
      title: contains('Nearby'),
      type: 'location_alert',
      targetType: 'custom',
      targetUserIds: ['user-1', 'user-2', 'user-3'],
      sound: 'alert',
      category: 'alert',
      priority: 8,
    )).called(1);
  });
  
  test('notification failure does not throw exception', () async {
    when(mockApi.createNotification(any)).thenThrow(Exception('API Error'));
    
    // Should not throw
    await service.notifyReportSubmitted(
      userId: 'user-123',
      reportId: 'report-456',
      title: 'Test Report',
    );
  });
});
```

### Property-Based Tests

Property-based tests will use the `test` package with custom generators:

```dart
// Property 1: Report submission creates success notification
test('Property 1: Report submission creates success notification', () {
  check(
    any.tuple3(
      any.uuid, // userId
      any.uuid, // reportId
      any.string, // title
    ),
  ).times(100).satisfies((tuple) async {
    final (userId, reportId, title) = tuple;
    
    await service.notifyReportSubmitted(
      userId: userId,
      reportId: reportId,
      title: title,
    );
    
    // Verify notification was created
    final notifications = await getCreatedNotifications();
    expect(
      notifications.any((n) => 
        n['type'] == 'success' &&
        n['targetUserIds'].contains(userId)
      ),
      isTrue,
    );
  });
});

// Property 33: Nearby users query applies all filters
test('Property 33: Nearby users query applies all filters', () {
  check(
    any.tuple3(
      any.doubleInRange(-90, 90), // latitude
      any.doubleInRange(-180, 180), // longitude
      any.doubleInRange(1, 10), // radius
    ),
  ).times(100).satisfies((tuple) async {
    final (lat, lng, radius) = tuple;
    
    final nearbyUsers = await userApi.getNearbyUsers(
      latitude: lat,
      longitude: lng,
      radiusKm: radius,
    );
    
    // Verify all returned users meet filter criteria
    for (final userId in nearbyUsers) {
      final user = await getUserById(userId);
      final prefs = await getUserAlertPreferences(userId);
      
      expect(prefs['location_alerts_enabled'], isTrue);
      expect(user['notifications_enabled'], isTrue);
      expect(user['is_deleted'], isFalse);
      expect(userId, isNot(equals(currentUserId)));
    }
  });
});
```

### Integration Tests

Integration tests will verify end-to-end notification flows:

```dart
testWidgets('Report submission triggers notifications', (tester) async {
  // 1. Setup: Login and navigate to report submission
  await tester.pumpWidget(MyApp());
  await loginAsUser(tester, 'test@example.com');
  await navigateToReportSubmission(tester);
  
  // 2. Submit report
  await fillReportForm(tester, title: 'Test Pothole', severity: 'high');
  await tester.tap(find.byKey(Key('submit_button')));
  await tester.pumpAndSettle();
  
  // 3. Verify success notification
  await navigateToNotifications(tester);
  expect(find.text('Report Submitted Successfully'), findsOneWidget);
  
  // 4. Verify nearby users received alerts (if any)
  final nearbyNotifications = await getNearbyUserNotifications();
  if (nearbyNotifications.isNotEmpty) {
    expect(
      nearbyNotifications.every((n) => n['type'] == 'location_alert'),
      isTrue,
    );
  }
});
```

## Implementation Notes

### Notification Helper Service Implementation

The NotificationHelperService should be implemented as a singleton or provided via dependency injection:

```dart
// In main.dart or service locator
final notificationApi = NotificationApi();
final notificationHelper = NotificationHelperService(notificationApi);

// Make available to other services
GetIt.instance.registerSingleton<NotificationHelperService>(notificationHelper);
```

### Integration Points

Each API should inject NotificationHelperService and call appropriate methods after successful operations:

```dart
// In ReportIssueApi
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
    final report = await _repository.submitReportIssue(id);
    
    // Send success notification
    await _notificationHelper.notifyReportSubmitted(
      userId: report.createdBy!,
      reportId: report.id,
      title: report.title ?? 'Road Issue',
    );
    
    // Notify nearby users
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
      
      // Notify users monitoring routes
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

### Database Function Setup

The database functions should be created during migration:

```sql
-- Create PostGIS extension if not exists (for spatial queries)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create get_nearby_users function
-- (See Data Models section for full implementation)

-- Create get_users_monitoring_route function
-- (See Data Models section for full implementation)

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_nearby_users TO authenticated;
GRANT EXECUTE ON FUNCTION get_users_monitoring_route TO authenticated;
```

### Performance Considerations

1. **Database Indexes**: Ensure indexes exist for spatial queries
   ```sql
   CREATE INDEX IF NOT EXISTS idx_route_waypoints_location 
   ON route_waypoints USING GIST (ST_MakePoint(longitude, latitude));
   ```

2. **Batch Operations**: When notifying multiple users, use OneSignal's batch API
   ```dart
   // NotificationAPI already handles this via target_user_ids array
   ```

3. **Async Operations**: All notification operations should be non-blocking
   ```dart
   // Don't await notification operations if they're not critical
   unawaited(_notificationHelper.notifyReportSubmitted(...));
   ```

4. **Caching**: Cache user preferences to reduce database queries
   ```dart
   // Consider caching user alert preferences
   final cachedPrefs = await _cache.get('user_prefs_$userId');
   ```

### Security Considerations

1. **Permission Checks**: NotificationAPI already handles permission checks
2. **Data Validation**: Validate all input data before creating notifications
3. **Rate Limiting**: Consider rate limiting notification creation per user
4. **PII Protection**: Don't include sensitive user data in notification payloads

### Monitoring and Metrics

Track key metrics for notification system health:

```dart
// Metrics to track
- Notification creation success rate
- Notification delivery rate (from OneSignal)
- Average notification creation time
- Nearby user query performance
- Route monitoring query performance
- Error rates by notification type
```

