# Notification Trigger Guide

## Overview

This guide documents all notification trigger points in the Pavra application, providing code examples for each integration and best practices for error handling. Use this guide when integrating notifications into new or existing business logic.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Report System Triggers](#report-system-triggers)
3. [Authority Request Triggers](#authority-request-triggers)
4. [Reputation System Triggers](#reputation-system-triggers)
5. [AI Detection Triggers](#ai-detection-triggers)
6. [Route System Triggers](#route-system-triggers)
7. [User System Triggers](#user-system-triggers)
8. [System Notifications](#system-notifications)
9. [Error Handling Best Practices](#error-handling-best-practices)
10. [Testing Notification Triggers](#testing-notification-triggers)

---

## Architecture Overview

### Notification Flow

```
Business Event → API Method → NotificationHelperService → NotificationAPI → OneSignal
```

### Key Principles

1. **Non-Blocking**: Notifications never block business logic
2. **Error Resilient**: Notification failures are logged but don't throw exceptions
3. **Async Operations**: All notification calls are asynchronous
4. **Dependency Injection**: NotificationHelperService is injected into APIs

### Setup

```dart
// In your API class constructor
class YourApi {
  final NotificationHelperService _notificationHelper;
  
  YourApi(this._notificationHelper);
}
```

---

## Report System Triggers

### 1. Report Submission

**Trigger Point:** After successful report submission  
**Location:** `lib/core/api/report_issue/report_issue_api.dart`  
**Method:** `submitReport()`

**Notifications Sent:**
1. Success notification to report creator
2. Location alerts to nearby users (if any)
3. Route monitoring alerts to affected route users (if any)


**Implementation:**

```dart
Future<ReportIssueModel> submitReport(String id) async {
  try {
    // 1. Submit the report
    final report = await _repository.submitReportIssue(id);
    
    // 2. Send success notification to creator
    await _notificationHelper.notifyReportSubmitted(
      userId: report.createdBy!,
      reportId: report.id,
      title: report.title ?? 'Road Issue',
    );
    
    // 3. Notify nearby users and route monitors (if location available)
    if (report.latitude != null && report.longitude != null) {
      await _notifyNearbyAndMonitoringUsers(report);
    }
    
    return report;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to submit report',
      name: 'ReportIssueApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

Future<void> _notifyNearbyAndMonitoringUsers(ReportIssueModel report) async {
  try {
    // Query nearby users and monitoring users in parallel
    final results = await Future.wait([
      _userApi.getNearbyUsers(
        latitude: report.latitude!,
        longitude: report.longitude!,
        radiusKm: 5.0,
      ),
      _savedRouteApi.getUsersMonitoringRoute(
        latitude: report.latitude!,
        longitude: report.longitude!,
        bufferKm: 0.5,
      ),
    ]);
    
    final nearbyUsers = results[0];
    final monitoringUsers = results[1];
    
    // Send notifications in parallel
    await Future.wait([
      if (nearbyUsers.isNotEmpty)
        _notificationHelper.notifyNearbyUsers(
          reportId: report.id,
          title: report.title ?? 'Road Issue',
          latitude: report.latitude!,
          longitude: report.longitude!,
          severity: report.severity ?? 'moderate',
          nearbyUserIds: nearbyUsers,
        ),
      if (monitoringUsers.isNotEmpty)
        _notificationHelper.notifyMonitoredRouteIssue(
          reportId: report.id,
          title: report.title ?? 'Road Issue',
          latitude: report.latitude!,
          longitude: report.longitude!,
          monitoringUserIds: monitoringUsers,
        ),
    ]);
  } catch (e, stackTrace) {
    // Log but don't throw - notification failures shouldn't block report submission
    developer.log(
      'Failed to notify nearby/monitoring users',
      name: 'ReportIssueApi',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
```

**Requirements Validated:** 1.1, 1.2, 1.3, 1.4, 6.1, 6.2

---

### 2. Report Verification

**Trigger Point:** After authority marks report as reviewed  
**Location:** `lib/core/api/report_issue/report_issue_api.dart`  
**Method:** `markAsReviewed()`

**Notifications Sent:**
1. Verification success notification to report creator

**Implementation:**

```dart
Future<ReportIssueModel> markAsReviewed(String reportId) async {
  try {
    final report = await _repository.markAsReviewed(reportId);
    
    // Notify report creator about verification
    await _notificationHelper.notifyReportVerified(
      userId: report.createdBy!,
      reportId: report.id,
      reviewerId: _authService.currentUserId!,
    );
    
    return report;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to mark report as reviewed',
      name: 'ReportIssueApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 2.1

---

### 3. Report Spam

**Trigger Point:** After authority marks report as spam  
**Location:** `lib/core/api/report_issue/report_issue_api.dart`  
**Method:** `markAsSpam()`

**Notifications Sent:**
1. Spam warning notification to report creator (with reason)

**Implementation:**

```dart
Future<ReportIssueModel> markAsSpam(String reportId, String? comment) async {
  try {
    final report = await _repository.markAsSpam(reportId, comment);
    
    // Notify report creator about spam marking
    await _notificationHelper.notifyReportSpam(
      userId: report.createdBy!,
      reportId: report.id,
      reviewerId: _authService.currentUserId!,
      comment: comment,
    );
    
    return report;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to mark report as spam',
      name: 'ReportIssueApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 2.2

---

### 4. Vote Thresholds

**Trigger Point:** After vote is cast and threshold is reached  
**Location:** `lib/core/api/report_issue/report_issue_api.dart`  
**Methods:** `voteVerify()`, `voteSpam()`

**Notifications Sent:**
1. Community verification notification (at 5 verified votes)
2. Community flagging notification (at 3 spam votes)

**Implementation:**

```dart
Future<void> voteVerify(String reportId) async {
  try {
    await _repository.voteVerify(reportId);
    
    // Check if threshold reached
    final report = await _repository.getReportById(reportId);
    final verifiedVotes = report.verifiedVotes ?? 0;
    
    if (verifiedVotes == 5) {
      await _notificationHelper.notifyVoteThreshold(
        userId: report.createdBy!,
        reportId: report.id,
        voteType: 'verified',
        voteCount: verifiedVotes,
      );
    }
  } catch (e, stackTrace) {
    developer.log(
      'Failed to process verify vote',
      name: 'ReportIssueApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

Future<void> voteSpam(String reportId) async {
  try {
    await _repository.voteSpam(reportId);
    
    // Check if threshold reached
    final report = await _repository.getReportById(reportId);
    final spamVotes = report.spamVotes ?? 0;
    
    if (spamVotes == 3) {
      await _notificationHelper.notifyVoteThreshold(
        userId: report.createdBy!,
        reportId: report.id,
        voteType: 'spam',
        voteCount: spamVotes,
      );
    }
  } catch (e, stackTrace) {
    developer.log(
      'Failed to process spam vote',
      name: 'ReportIssueApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 2.3, 2.4, 2.5

---

## Authority Request Triggers

### 5. Request Submission

**Trigger Point:** After authority request is created  
**Location:** `lib/core/api/authority_request/authority_request_api.dart`  
**Method:** `createRequest()`

**Notifications Sent:**
1. Confirmation notification to requester
2. New request notification to all admins/developers

**Implementation:**

```dart
Future<AuthorityRequestModel> createRequest(AuthorityRequestModel request) async {
  try {
    final createdRequest = await _repository.createRequest(request);
    
    // Notify requester about submission
    await _notificationHelper.notifyRequestSubmitted(
      userId: createdRequest.userId,
      requestId: createdRequest.id,
    );
    
    // Notify admins about new request
    final user = await _userApi.getUserById(createdRequest.userId);
    await _notificationHelper.notifyAdminsNewRequest(
      requestId: createdRequest.id,
      userId: createdRequest.userId,
      username: user.username ?? 'Unknown User',
    );
    
    return createdRequest;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to create authority request',
      name: 'AuthorityRequestApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 3.1, 3.4, 3.5

---

### 6. Request Approval/Rejection

**Trigger Point:** After request status is updated  
**Location:** `lib/core/api/authority_request/authority_request_api.dart`  
**Method:** `updateRequestStatus()`

**Notifications Sent:**
1. Approval notification (if approved)
2. Rejection notification with reason (if rejected)

**Implementation:**

```dart
Future<AuthorityRequestModel> updateRequestStatus({
  required String requestId,
  required String status,
  String? comment,
}) async {
  try {
    final request = await _repository.updateRequestStatus(
      requestId: requestId,
      status: status,
      comment: comment,
    );
    
    // Send appropriate notification based on status
    if (status == 'approved') {
      await _notificationHelper.notifyRequestApproved(
        userId: request.userId,
        requestId: request.id,
        reviewerId: _authService.currentUserId!,
      );
    } else if (status == 'rejected') {
      await _notificationHelper.notifyRequestRejected(
        userId: request.userId,
        requestId: request.id,
        reviewerId: _authService.currentUserId!,
        comment: comment,
      );
    }
    
    return request;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to update request status',
      name: 'AuthorityRequestApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 3.2, 3.3

---

## Reputation System Triggers

### 7. Reputation Change

**Trigger Point:** After reputation record is added  
**Location:** `lib/core/api/reputation/reputation_api.dart`  
**Method:** `addReputationRecord()`

**Notifications Sent:**
1. Reputation change notification (if change != 0)
2. Milestone notification (if milestone reached: 25, 50, 75, 100)

**Implementation:**

```dart
Future<ReputationModel> addReputationRecord({
  required String userId,
  required int changeAmount,
  required String actionType,
  String? relatedId,
}) async {
  try {
    final reputation = await _repository.addReputationRecord(
      userId: userId,
      changeAmount: changeAmount,
      actionType: actionType,
      relatedId: relatedId,
    );
    
    // Skip notification if no change
    if (changeAmount == 0) {
      return reputation;
    }
    
    // Notify about reputation change
    await _notificationHelper.notifyReputationChange(
      userId: userId,
      changeAmount: changeAmount,
      actionType: actionType,
      scoreAfter: reputation.totalScore,
    );
    
    // Check for milestone achievements
    final milestone = _checkMilestone(reputation.totalScore, changeAmount);
    if (milestone != null) {
      await _notificationHelper.notifyReputationMilestone(
        userId: userId,
        milestone: milestone,
      );
    }
    
    return reputation;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to add reputation record',
      name: 'ReputationApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

int? _checkMilestone(int currentScore, int changeAmount) {
  final previousScore = currentScore - changeAmount;
  const milestones = [25, 50, 75, 100];
  
  for (final milestone in milestones) {
    if (currentScore >= milestone && previousScore < milestone) {
      return milestone;
    }
  }
  
  return null;
}
```

**Requirements Validated:** 4.1, 4.2, 4.3, 4.4, 4.5

---

## AI Detection Triggers

### 8. Critical Detection

**Trigger Point:** After AI detection is processed  
**Location:** `lib/core/api/detection/ai_detection_api.dart`  
**Method:** `detectRoadDamage()`

**Notifications Sent:**
1. Critical alert (for 'critical' severity)
2. High priority alert (for 'high' severity)
3. No notification (for 'moderate' or 'low' severity)

**Implementation:**

```dart
Future<DetectionModel> detectRoadDamage(File imageFile) async {
  try {
    final detection = await _repository.detectRoadDamage(imageFile);
    
    // Only notify for critical or high severity
    final severity = detection.severity?.toLowerCase() ?? '';
    if (severity == 'critical' || severity == 'high') {
      await _notificationHelper.notifyCriticalDetection(
        userId: _authService.currentUserId!,
        detectionId: detection.id,
        issueType: detection.issueType ?? 'Unknown',
        severity: severity,
        latitude: detection.latitude ?? 0.0,
        longitude: detection.longitude ?? 0.0,
        confidence: detection.confidence ?? 0.0,
      );
    }
    
    return detection;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to detect road damage',
      name: 'AiDetectionApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 5.1, 5.2, 5.3, 5.4

---

### 9. Offline Queue Processing

**Trigger Point:** After offline detection queue is processed  
**Location:** `lib/data/sources/local/detection_queue_manager.dart`  
**Method:** `processQueue()`

**Notifications Sent:**
1. Sync completion notification with count

**Implementation:**

```dart
Future<void> processQueue() async {
  try {
    final queuedDetections = await _getQueuedDetections();
    
    if (queuedDetections.isEmpty) {
      return;
    }
    
    int processedCount = 0;
    
    for (final detection in queuedDetections) {
      try {
        await _uploadDetection(detection);
        await _removeFromQueue(detection.id);
        processedCount++;
      } catch (e) {
        developer.log(
          'Failed to process queued detection',
          name: 'DetectionQueueManager',
          error: e,
        );
      }
    }
    
    // Notify user about sync completion
    if (processedCount > 0) {
      await _notificationHelper.notifyOfflineQueueProcessed(
        userId: _authService.currentUserId!,
        processedCount: processedCount,
      );
    }
  } catch (e, stackTrace) {
    developer.log(
      'Failed to process detection queue',
      name: 'DetectionQueueManager',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
```

**Requirements Validated:** 5.5

---

## Route System Triggers

### 10. Route Save

**Trigger Point:** After route is created  
**Location:** `lib/core/api/saved_route/saved_route_api.dart`  
**Method:** `createRoute()`

**Notifications Sent:**
1. Save confirmation notification

**Implementation:**

```dart
Future<SavedRouteModel> createRoute(SavedRouteModel route) async {
  try {
    final createdRoute = await _repository.createRoute(route);
    
    // Notify user about successful save
    await _notificationHelper.notifyRouteSaved(
      userId: createdRoute.userId,
      routeId: createdRoute.id,
      routeName: createdRoute.name ?? 'Unnamed Route',
    );
    
    return createdRoute;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to create route',
      name: 'SavedRouteApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 6.4

---

### 11. Route Monitoring Toggle

**Trigger Point:** After route monitoring is enabled  
**Location:** `lib/core/api/saved_route/saved_route_api.dart`  
**Method:** `toggleRouteMonitoring()`

**Notifications Sent:**
1. Monitoring enabled confirmation (only when enabling, not disabling)

**Implementation:**

```dart
Future<SavedRouteModel> toggleRouteMonitoring(String routeId, bool isMonitoring) async {
  try {
    final route = await _repository.toggleRouteMonitoring(routeId, isMonitoring);
    
    // Only notify when enabling monitoring
    if (isMonitoring) {
      await _notificationHelper.notifyRouteMonitoringEnabled(
        userId: route.userId,
        routeId: route.id,
        routeName: route.name ?? 'Unnamed Route',
      );
    }
    
    return route;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to toggle route monitoring',
      name: 'SavedRouteApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 6.5

---

## User System Triggers

### 12. New User Welcome

**Trigger Point:** After user profile is created  
**Location:** `lib/core/api/user/user_api.dart`  
**Method:** `createProfile()`

**Notifications Sent:**
1. Welcome notification with onboarding guidance

**Implementation:**

```dart
Future<UserModel> createProfile(UserModel user) async {
  try {
    final createdUser = await _repository.createProfile(user);
    
    // Send welcome notification
    await _notificationHelper.notifyWelcomeNewUser(
      userId: createdUser.id,
    );
    
    return createdUser;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to create user profile',
      name: 'UserApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 7.1, 7.2

---

### 13. Role Change

**Trigger Point:** After user profile is updated with new role  
**Location:** `lib/core/api/user/user_api.dart`  
**Method:** `updateProfile()`

**Notifications Sent:**
1. Role change notification (only if role actually changed)

**Implementation:**

```dart
Future<UserModel> updateProfile(String userId, Map<String, dynamic> updates) async {
  try {
    // Get current user to check for role change
    final currentUser = await _repository.getUserById(userId);
    final oldRole = currentUser.role;
    final newRole = updates['role'] as String?;
    
    // Update the profile
    final updatedUser = await _repository.updateProfile(userId, updates);
    
    // Notify if role changed
    if (newRole != null && newRole != oldRole) {
      await _notificationHelper.notifyRoleChanged(
        userId: userId,
        newRole: newRole,
      );
    }
    
    return updatedUser;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to update user profile',
      name: 'UserApi',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Requirements Validated:** 7.3, 7.4, 7.5

---

## System Notifications

### 14. System Maintenance

**Trigger Point:** Scheduled 24 hours before maintenance  
**Location:** Admin panel or scheduled job  
**Method:** Manual or automated

**Notifications Sent:**
1. Maintenance notification to all users

**Implementation:**

```dart
Future<void> scheduleMaintenanceNotification({
  required DateTime maintenanceStart,
  required DateTime maintenanceEnd,
}) async {
  try {
    // Calculate notification time (24 hours before)
    final notificationTime = maintenanceStart.subtract(Duration(hours: 24));
    
    // Schedule or send immediately if within 24 hours
    if (DateTime.now().isAfter(notificationTime)) {
      await _notificationHelper.notifySystemMaintenance(
        maintenanceStart: maintenanceStart,
        maintenanceEnd: maintenanceEnd,
      );
    } else {
      // Schedule for later (implementation depends on scheduling system)
      await _scheduleNotification(
        time: notificationTime,
        callback: () => _notificationHelper.notifySystemMaintenance(
          maintenanceStart: maintenanceStart,
          maintenanceEnd: maintenanceEnd,
        ),
      );
    }
  } catch (e, stackTrace) {
    developer.log(
      'Failed to schedule maintenance notification',
      name: 'SystemNotifications',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
```

**Requirements Validated:** 8.1, 8.4

---

### 15. App Update

**Trigger Point:** When new version is released  
**Location:** Admin panel or automated release process  
**Method:** Manual or automated

**Notifications Sent:**
1. Update available notification to all users

**Implementation:**

```dart
Future<void> notifyAppUpdate({
  required String newVersion,
  required String updateUrl,
  String? releaseNotes,
}) async {
  try {
    await _notificationHelper.notifyAppUpdate(
      newVersion: newVersion,
      updateUrl: updateUrl,
      releaseNotes: releaseNotes,
    );
  } catch (e, stackTrace) {
    developer.log(
      'Failed to send app update notification',
      name: 'SystemNotifications',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
```

**Requirements Validated:** 8.2, 8.5

---

### 16. Important Announcement

**Trigger Point:** When admin creates announcement  
**Location:** Admin panel  
**Method:** Manual

**Notifications Sent:**
1. Announcement notification to all users

**Implementation:**

```dart
Future<void> sendAnnouncement({
  required String title,
  required String message,
  String? announcementId,
}) async {
  try {
    await _notificationHelper.notifyImportantAnnouncement(
      adminId: _authService.currentUserId!,
      title: title,
      message: message,
      announcementId: announcementId,
    );
  } catch (e, stackTrace) {
    developer.log(
      'Failed to send announcement',
      name: 'SystemNotifications',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
```

**Requirements Validated:** 8.3

---

## Error Handling Best Practices

### 1. Always Wrap Notification Calls

```dart
// ✅ GOOD: Wrapped in try-catch
try {
  await _notificationHelper.notifyReportSubmitted(...);
} catch (e, stackTrace) {
  developer.log('Notification failed', error: e, stackTrace: stackTrace);
  // Don't rethrow - notification failures shouldn't block business logic
}

// ❌ BAD: No error handling
await _notificationHelper.notifyReportSubmitted(...);
```

### 2. Log with Full Context

```dart
// ✅ GOOD: Comprehensive logging
developer.log(
  'Failed to notify nearby users',
  name: 'ReportIssueApi',
  error: e,
  stackTrace: stackTrace,
  level: 1000, // ERROR level
  time: DateTime.now(),
);

// ❌ BAD: Minimal logging
print('Error: $e');
```

### 3. Handle Empty Results Gracefully

```dart
// ✅ GOOD: Check before notifying
final nearbyUsers = await _userApi.getNearbyUsers(...);
if (nearbyUsers.isNotEmpty) {
  await _notificationHelper.notifyNearbyUsers(...);
}

// ❌ BAD: No check
final nearbyUsers = await _userApi.getNearbyUsers(...);
await _notificationHelper.notifyNearbyUsers(...); // May fail if empty
```

### 4. Don't Block Business Logic

```dart
// ✅ GOOD: Notification failure doesn't affect return
Future<Report> submitReport() async {
  final report = await _repository.submit();
  
  try {
    await _notificationHelper.notify(...);
  } catch (e) {
    log(error: e); // Log but don't throw
  }
  
  return report; // Always return
}

// ❌ BAD: Notification failure blocks return
Future<Report> submitReport() async {
  final report = await _repository.submit();
  await _notificationHelper.notify(...); // If this fails, report isn't returned
  return report;
}
```

### 5. Use Parallel Execution When Possible

```dart
// ✅ GOOD: Parallel execution
await Future.wait([
  _notificationHelper.notifyNearbyUsers(...),
  _notificationHelper.notifyMonitoredRouteIssue(...),
]);

// ❌ BAD: Sequential execution
await _notificationHelper.notifyNearbyUsers(...);
await _notificationHelper.notifyMonitoredRouteIssue(...);
```

---

## Testing Notification Triggers

### Unit Testing

Test that notifications are triggered correctly:

```dart
test('submitReport triggers notifications', () async {
  // Arrange
  final mockHelper = MockNotificationHelperService();
  final api = ReportIssueApi(mockHelper, mockUserApi, mockRouteApi);
  
  // Act
  await api.submitReport('report-123');
  
  // Assert
  verify(mockHelper.notifyReportSubmitted(
    userId: any,
    reportId: 'report-123',
    title: any,
  )).called(1);
});
```

### Integration Testing

Test end-to-end notification flow:

```dart
testWidgets('report submission sends notifications', (tester) async {
  // Setup
  await tester.pumpWidget(MyApp());
  await loginAsUser(tester);
  
  // Submit report
  await submitReport(tester, title: 'Test Report');
  
  // Verify notification was created
  final notifications = await getNotifications();
  expect(
    notifications.any((n) => n.title.contains('Successfully')),
    isTrue,
  );
});
```

### Manual Testing Checklist

- [ ] Report submission sends success notification
- [ ] Nearby users receive location alerts
- [ ] Route monitoring users receive alerts
- [ ] Authority approval sends high-priority notification
- [ ] Reputation milestones trigger achievement notifications
- [ ] Critical AI detections send maximum priority alerts
- [ ] Welcome notification sent to new users
- [ ] System maintenance notifications reach all users

---

## Quick Reference

### Notification Priority Levels

| Priority | Use Case | Examples |
|----------|----------|----------|
| 10 | Critical safety alerts | Critical AI detections |
| 9 | High importance | Authority approval |
| 8 | Location alerts | Nearby issues, route monitoring |
| 7 | Important updates | Milestones, admin requests, system maintenance |
| 6 | Status changes | Verification, role changes, updates |
| 5 | Confirmations | Report submitted, route saved |

### Sound Types

| Sound | Use Case |
|-------|----------|
| `alert` | Safety alerts, critical issues |
| `success` | Positive outcomes, achievements |
| `warning` | Negative outcomes, spam |
| `default` | General notifications |

### Category Types

| Category | Use Case |
|----------|----------|
| `alert` | Safety and location alerts |
| `status` | Status updates and confirmations |
| `warning` | Warnings and negative outcomes |

---

## Troubleshooting

### Notifications Not Sending

1. **Check NotificationHelperService injection**
   ```dart
   // Verify service is injected
   print(_notificationHelper != null); // Should be true
   ```

2. **Check error logs**
   ```dart
   // Look for errors in console
   developer.log('Test notification', name: 'NotificationHelperService');
   ```

3. **Verify OneSignal configuration**
   ```dart
   // Check OneSignal is initialized
   final status = await OneSignal.getDeviceState();
   print(status?.userId); // Should have value
   ```

### Notifications Delayed

1. **Check for sequential execution**
   - Use `Future.wait()` for parallel execution
   - Avoid awaiting non-critical operations

2. **Check database query performance**
   - Verify spatial indexes exist
   - Monitor query execution time

3. **Check network connectivity**
   - OneSignal requires internet connection
   - Offline notifications are queued

### Users Not Receiving Notifications

1. **Check user preferences**
   ```sql
   SELECT notifications_enabled, location_alerts_enabled 
   FROM profiles p
   JOIN user_alert_preferences uap ON p.id = uap.user_id
   WHERE p.id = 'user-id';
   ```

2. **Check OneSignal subscription**
   - User must be subscribed to OneSignal
   - Check device state in OneSignal dashboard

3. **Check notification filters**
   - Verify user meets filter criteria
   - Check is_deleted flag

---

## See Also

- [NotificationHelperService API Documentation](./NOTIFICATION_HELPER_SERVICE_API.md)
- [Business Event Notifications API Documentation](./BUSINESS_EVENT_NOTIFICATIONS_API.md)
- [Notification Usage Guide](./NOTIFICATION_USAGE.md)
- [Business Event Notifications Spec](./.kiro/specs/business-event-notifications/)
