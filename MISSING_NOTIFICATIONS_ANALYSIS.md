# Missing Push Notifications Analysis

## Executive Summary

Based on the OneSignal integration specification and comprehensive codebase analysis, this document identifies all features that should have push notifications but are currently missing. The analysis covers 8 major modules with **25+ critical notification points** that need implementation.

**Current Status:**
- ✅ OneSignal SDK integrated
- ✅ Notification database tables created  
- ✅ Notification UI screens implemented
- ❌ **Business event notification triggers missing**
- ❌ **Automated system notifications missing**
- ❌ **Location-based real-time alerts missing**

---

## 🎯 Impact Analysis

### User Experience Impact
- **Safety**: Users miss critical nearby hazard alerts
- **Engagement**: No feedback on report submissions and status changes
- **Motivation**: No reputation change notifications to encourage participation
- **Transparency**: Users unaware of authority request status

### Business Impact
- **Retention**: Lower user engagement without timely notifications
- **Safety Mission**: Reduced effectiveness of hazard warning system
- **User Satisfaction**: Frustration from lack of feedback

---

## 📊 Missing Notifications by Module


## 1. Report System (`report_issue_api.dart`)

### 1.1 Report Submission Success ⭐
**Location**: `ReportIssueApi.submitReport()`  
**Current Status**: ❌ No notification  
**Priority**: **HIGH**  
**User Impact**: Users don't know if their report was successfully submitted

**Implementation**:
```dart
// After successful submission in submitReport()
await notificationApi.createNotification(
  createdBy: 'system',
  title: 'Report Submitted Successfully ✅',
  message: 'Your road issue report has been submitted and is awaiting review',
  type: 'success',
  targetType: 'single',
  targetUserIds: [userId],
  data: {
    'action': 'view_report',
    'report_id': reportId,
  },
  sound: 'success',
  category: 'status',
);
```

---

### 1.2 Nearby Report Alert ⭐⭐⭐
**Location**: `ReportIssueApi.submitReport()`  
**Current Status**: ❌ No notification  
**Priority**: **CRITICAL**  
**User Impact**: Users miss critical safety alerts about nearby hazards

**Implementation**:
```dart
// After report submission, notify nearby users
final nearbyUsers = await userApi.getNearbyUsers(
  latitude: latitude,
  longitude: longitude,
  radiusKm: 5.0,
);

if (nearbyUsers.isNotEmpty) {
  await notificationApi.createNotification(
    createdBy: 'system',
    title: '⚠️ Nearby Road Hazard Alert',
    message: 'A new road issue has been reported near your location: $title',
    type: 'location_alert',
    targetType: 'custom',
    targetUserIds: nearbyUsers,
    data: {
      'action': 'view_report',
      'report_id': reportId,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
    },
    sound: 'alert',
    category: 'alert',
    priority: 8,
  );
}
```

**Additional Requirements**:
- Need to implement `UserApi.getNearbyUsers()` method
- Need Supabase function `get_nearby_users()` (see implementation guide)
- Should respect user alert preferences (alert_radius_km, location_alerts_enabled)

---

### 1.3 Report Verified by Authority ⭐
**Location**: `ReportIssueApi.markAsReviewed()`  
**Current Status**: ❌ No notification  
**Priority**: **HIGH**  
**User Impact**: Users don't know when their reports are verified

**Implementation**:
```dart
// After authority marks report as reviewed
final report = await getReportById(issueId);

await notificationApi.createNotification(
  createdBy: reviewerId,
  title: 'Report Verified ✅',
  message: 'Your report has been verified by an authority',
  type: 'success',
  targetType: 'single',
  targetUserIds: [report.createdBy],
  relatedAction: reportId,
  data: {
    'action': 'view_report',
    'report_id': reportId,
  },
  sound: 'success',
  category: 'status',
  priority: 6,
);
```

---

### 1.4 Report Marked as Spam
**Location**: `ReportIssueApi.markAsSpam()`  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: Users don't know why their report was rejected

**Implementation**:
```dart
// After authority marks report as spam
final report = await getReportById(issueId);

await notificationApi.createNotification(
  createdBy: reviewerId,
  title: 'Report Marked as Spam ⚠️',
  message: comment ?? 'Your report was marked as spam. Please ensure you submit valid road issues.',
  type: 'warning',
  targetType: 'single',
  targetUserIds: [report.createdBy],
  relatedAction: reportId,
  data: {
    'action': 'view_report',
    'report_id': reportId,
  },
  sound: 'warning',
  category: 'warning',
  priority: 6,
);
```

---

### 1.5 Vote Threshold Reached
**Location**: `ReportIssueApi.voteVerify()` / `voteSpam()`  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: Users miss community validation feedback

**Implementation**:
```dart
// After vote is cast, check if threshold is reached
final voteCounts = await getVoteCounts(issueId);
final report = await getReportById(issueId);

// Notify on verification threshold (e.g., 5 verifications)
if (voteCounts['verified'] == 5) {
  await notificationApi.createNotification(
    createdBy: 'system',
    title: 'Community Verified 👥',
    message: 'Your report has been verified by ${voteCounts['verified']} community members',
    type: 'info',
    targetType: 'single',
    targetUserIds: [report.createdBy],
    data: {
      'action': 'view_report',
      'report_id': issueId,
      'vote_count': voteCounts['verified'],
    },
    sound: 'default',
    category: 'social',
    priority: 5,
  );
}

// Notify on spam threshold (e.g., 3 spam votes)
if (voteCounts['spam'] == 3) {
  await notificationApi.createNotification(
    createdBy: 'system',
    title: 'Report Flagged ⚠️',
    message: 'Your report has been flagged by community members. It will be reviewed.',
    type: 'warning',
    targetType: 'single',
    targetUserIds: [report.createdBy],
    data: {
      'action': 'view_report',
      'report_id': issueId,
    },
    sound: 'warning',
    category: 'warning',
    priority: 6,
  );
}
```

---


## 2. Authority Request System (`authority_request_api.dart`)

### 2.1 Request Submitted
**Location**: `AuthorityRequestApi.createRequest()`  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: Users don't receive confirmation of submission

**Implementation**:
```dart
// After request creation
await notificationApi.createNotification(
  createdBy: 'system',
  title: 'Authority Request Submitted 📋',
  message: 'Your authority verification request has been submitted. We will review it within 3-5 business days.',
  type: 'info',
  targetType: 'single',
  targetUserIds: [userId],
  data: {
    'action': 'view_request',
    'request_id': requestId,
  },
  sound: 'default',
  category: 'status',
  priority: 5,
);
```

---

### 2.2 Request Approved ⭐⭐
**Location**: `AuthorityRequestApi.updateRequestStatus()` (status='approved')  
**Current Status**: ❌ No notification  
**Priority**: **CRITICAL**  
**User Impact**: Users don't know they've been granted authority privileges

**Implementation**:
```dart
// After approval
if (status == 'approved') {
  await notificationApi.createNotification(
    createdBy: reviewedBy,
    title: '🎉 Authority Request Approved',
    message: 'Congratulations! Your authority verification has been approved. You can now review reports.',
    type: 'success',
    targetType: 'single',
    targetUserIds: [request['user_id']],
    data: {
      'action': 'view_profile',
      'request_id': requestId,
    },
    sound: 'success',
    category: 'status',
    priority: 9,
  );
}
```

---

### 2.3 Request Rejected ⭐⭐
**Location**: `AuthorityRequestApi.updateRequestStatus()` (status='rejected')  
**Current Status**: ❌ No notification  
**Priority**: **CRITICAL**  
**User Impact**: Users don't know why their request was rejected

**Implementation**:
```dart
// After rejection
if (status == 'rejected') {
  await notificationApi.createNotification(
    createdBy: reviewedBy,
    title: 'Authority Request Rejected ❌',
    message: reviewedComment ?? 'Your authority verification request was not approved.',
    type: 'warning',
    targetType: 'single',
    targetUserIds: [request['user_id']],
    data: {
      'action': 'view_request',
      'request_id': requestId,
    },
    sound: 'warning',
    category: 'status',
    priority: 7,
  );
}
```

---

### 2.4 New Pending Request (Admin Notification)
**Location**: `AuthorityRequestApi.createRequest()`  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: Admins don't know about new requests requiring review

**Implementation**:
```dart
// Notify admins/developers about new request
await notificationApi.createNotification(
  createdBy: userId,
  title: 'New Authority Request 📝',
  message: 'User $username submitted an authority verification request',
  type: 'info',
  targetType: 'role',
  targetRoles: ['developer', 'admin'],
  data: {
    'action': 'review_request',
    'request_id': requestId,
    'user_id': userId,
  },
  sound: 'default',
  category: 'system',
  priority: 6,
);
```

---


## 3. Reputation System (`reputation_api.dart`)

### 3.1 Reputation Increased ⭐
**Location**: `ReputationApi.addReputationRecord()` (changeAmount > 0)  
**Current Status**: ❌ No notification  
**Priority**: **HIGH**  
**User Impact**: Users miss positive feedback that motivates participation

**Implementation**:
```dart
// After positive reputation change
if (changeAmount > 0) {
  await notificationApi.createNotification(
    createdBy: 'system',
    title: 'Reputation Increased ⬆️ +$changeAmount',
    message: 'You earned $changeAmount reputation points for ${_getActionLabel(actionType)}',
    type: 'success',
    targetType: 'single',
    targetUserIds: [userId],
    data: {
      'action': 'view_profile',
      'reputation_change': changeAmount,
      'action_type': actionType,
      'new_score': scoreAfter,
    },
    sound: 'success',
    category: 'status',
    priority: 5,
  );
}
```

---

### 3.2 Reputation Decreased
**Location**: `ReputationApi.addReputationRecord()` (changeAmount < 0)  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: Users don't understand why they lost reputation

**Implementation**:
```dart
// After negative reputation change
if (changeAmount < 0) {
  await notificationApi.createNotification(
    createdBy: 'system',
    title: 'Reputation Decreased ⬇️ $changeAmount',
    message: 'You lost ${changeAmount.abs()} reputation points for ${_getActionLabel(actionType)}',
    type: 'warning',
    targetType: 'single',
    targetUserIds: [userId],
    data: {
      'action': 'view_profile',
      'reputation_change': changeAmount,
      'action_type': actionType,
      'new_score': scoreAfter,
    },
    sound: 'warning',
    category: 'warning',
    priority: 6,
  );
}
```

---

### 3.3 Reputation Milestone Achieved
**Location**: `ReputationApi.addReputationRecord()`  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: Users miss achievement celebrations

**Implementation**:
```dart
// After reaching reputation milestones (25, 50, 75, 100)
final milestones = [25, 50, 75, 100];
if (milestones.contains(scoreAfter) && scoreAfter > scoreBefore) {
  String achievementMessage = '';
  String achievementIcon = '🏆';
  
  switch (scoreAfter) {
    case 25:
      achievementMessage = 'You\'re becoming a trusted contributor!';
      achievementIcon = '🥉';
      break;
    case 50:
      achievementMessage = 'You\'re a valued community member!';
      achievementIcon = '🥈';
      break;
    case 75:
      achievementMessage = 'You\'re an expert road reporter!';
      achievementIcon = '🥇';
      break;
    case 100:
      achievementMessage = 'You\'ve reached maximum reputation!';
      achievementIcon = '👑';
      break;
  }
  
  await notificationApi.createNotification(
    createdBy: 'system',
    title: '$achievementIcon Milestone Achieved!',
    message: 'Congratulations! Your reputation score reached $scoreAfter. $achievementMessage',
    type: 'success',
    targetType: 'single',
    targetUserIds: [userId],
    data: {
      'action': 'view_profile',
      'milestone': scoreAfter,
    },
    sound: 'success',
    category: 'status',
    priority: 7,
  );
}
```

**Helper Function**:
```dart
String _getActionLabel(String actionType) {
  switch (actionType) {
    case 'UPLOAD_ISSUE': return 'submitting a report';
    case 'FIRST_REPORTER': return 'being the first to report';
    case 'DUPLICATE_REPORT': return 'duplicate report';
    case 'ABUSE_REPORT': return 'system abuse';
    case 'MANUAL_ADJUSTMENT': return 'manual adjustment';
    default: return actionType;
  }
}
```

---


## 4. AI Detection System (`ai_detection_api.dart`)

### 4.1 Critical Issue Detected ⭐⭐
**Location**: `AiDetectionApi.detectRoadDamage()` (severity='critical' or 'high')  
**Current Status**: ❌ No notification  
**Priority**: **CRITICAL**  
**User Impact**: Users miss immediate alerts about severe road hazards

**Implementation**:
```dart
// After AI detects critical/high severity issue
final detection = DetectionModel.fromJson(detectionData);

if (detection.severity == 'critical' || detection.severity == 'high') {
  await notificationApi.createNotification(
    createdBy: 'system',
    title: '🚨 Critical Road Hazard Detected',
    message: 'AI detected ${detection.type} at your location. Immediate reporting recommended.',
    type: 'alert',
    targetType: 'single',
    targetUserIds: [userId],
    data: {
      'action': 'create_report',
      'detection_id': detection.id,
      'latitude': latitude,
      'longitude': longitude,
      'severity': detection.severity,
      'type': detection.type,
      'confidence': detection.confidence,
    },
    sound: 'alert',
    category: 'alert',
    priority: 10,
  );
}
```

---

### 4.2 Offline Queue Processed
**Location**: `DetectionQueueManager` (after processing queued detections)  
**Current Status**: ❌ No notification  
**Priority**: **LOW**  
**User Impact**: Users don't know when offline detections are synced

**Implementation**:
```dart
// After offline queue is processed
if (processedCount > 0) {
  await notificationApi.createNotification(
    createdBy: 'system',
    title: 'Offline Detections Synced ✅',
    message: 'Successfully processed $processedCount offline detection records',
    type: 'info',
    targetType: 'single',
    targetUserIds: [userId],
    data: {
      'action': 'view_history',
      'processed_count': processedCount,
    },
    sound: 'default',
    category: 'status',
    priority: 3,
  );
}
```

---

### 4.3 Detection Failed (Optional)
**Location**: `AiDetectionApi.detectRoadDamage()` (on error)  
**Current Status**: ❌ No notification  
**Priority**: **LOW**  
**User Impact**: May be too noisy; consider only for API errors

**Implementation**:
```dart
// After detection fails (only for API errors, not network errors)
catch (e) {
  if (e is DetectionException && e.type == DetectionExceptionType.api) {
    await notificationApi.createNotification(
      createdBy: 'system',
      title: 'Detection Failed ⚠️',
      message: 'Road detection failed. Please try again later.',
      type: 'warning',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'retry_detection',
        'error': e.message,
      },
      sound: 'warning',
      category: 'error',
      priority: 4,
    );
  }
}
```

---


## 5. User System (`user_api.dart`)

### 5.1 Welcome New User
**Location**: `UserApi.createProfile()` or `upsertProfile()`  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: New users miss onboarding guidance

**Implementation**:
```dart
// After profile creation (first time user)
await notificationApi.createNotification(
  createdBy: 'system',
  title: 'Welcome to Pavra! 👋',
  message: 'Thanks for joining! Start reporting road issues to make our roads safer.',
  type: 'info',
  targetType: 'single',
  targetUserIds: [userId],
  data: {
    'action': 'view_onboarding',
  },
  sound: 'default',
  category: 'system',
  priority: 5,
);
```

---

### 5.2 Role Changed
**Location**: `UserApi.updateProfile()` (when role changes)  
**Current Status**: ❌ No notification  
**Priority**: **LOW**  
**User Impact**: Users don't know about role changes

**Implementation**:
```dart
// After role update
if (role != null && role != currentRole) {
  String roleLabel = role == 'authority' ? 'Authority' : 
                     role == 'developer' ? 'Developer' : 
                     role == 'admin' ? 'Admin' : 'User';
  
  await notificationApi.createNotification(
    createdBy: 'system',
    title: 'Account Role Updated 🔄',
    message: 'Your account role has been updated to: $roleLabel',
    type: 'info',
    targetType: 'single',
    targetUserIds: [userId],
    data: {
      'action': 'view_profile',
      'new_role': role,
    },
    sound: 'default',
    category: 'status',
    priority: 6,
  );
}
```

---


## 6. Route System (`saved_route_api.dart`)

### 6.1 New Issue on Monitored Route ⭐⭐
**Location**: After report submission (requires new logic)  
**Current Status**: ❌ No notification  
**Priority**: **CRITICAL**  
**User Impact**: Users miss hazards on their regular routes

**Implementation**:
```dart
// In ReportIssueApi.submitReport(), after creating report
// Check if any users are monitoring routes that pass through this location
final affectedUsers = await savedRouteApi.getUsersMonitoringRoute(
  latitude: latitude,
  longitude: longitude,
  radiusKm: 0.5, // 500m buffer around route
);

if (affectedUsers.isNotEmpty) {
  await notificationApi.createNotification(
    createdBy: 'system',
    title: '⚠️ Issue on Your Monitored Route',
    message: 'A new road issue was reported on one of your monitored routes',
    type: 'location_alert',
    targetType: 'custom',
    targetUserIds: affectedUsers,
    data: {
      'action': 'view_report',
      'report_id': reportId,
      'latitude': latitude,
      'longitude': longitude,
    },
    sound: 'alert',
    category: 'alert',
    priority: 8,
  );
}
```

**Additional Requirements**:
- Need to implement `SavedRouteApi.getUsersMonitoringRoute()` method
- Need to check if report location intersects with any monitored route polylines
- Should respect user's route monitoring preferences

---

### 6.2 Route Saved Successfully
**Location**: `SavedRouteApi.createRoute()`  
**Current Status**: ❌ No notification  
**Priority**: **LOW**  
**User Impact**: Minor - users see UI confirmation

**Implementation**:
```dart
// After route is saved
await notificationApi.createNotification(
  createdBy: 'system',
  title: 'Route Saved ✅',
  message: 'Route "$name" has been saved successfully',
  type: 'success',
  targetType: 'single',
  targetUserIds: [userId],
  data: {
    'action': 'view_route',
    'route_id': routeId,
  },
  sound: 'success',
  category: 'status',
  priority: 3,
);
```

---

### 6.3 Route Monitoring Enabled
**Location**: `SavedRouteApi.toggleRouteMonitoring()` (when is_monitoring changes to true)  
**Current Status**: ❌ No notification  
**Priority**: **LOW**  
**User Impact**: Users should know monitoring is active

**Implementation**:
```dart
// After monitoring is enabled
if (isMonitoring) {
  final route = await getRouteById(routeId);
  
  await notificationApi.createNotification(
    createdBy: 'system',
    title: 'Route Monitoring Enabled 👁️',
    message: 'You will receive notifications about new issues on route "${route.name}"',
    type: 'info',
    targetType: 'single',
    targetUserIds: [userId],
    data: {
      'action': 'view_route',
      'route_id': routeId,
    },
    sound: 'default',
    category: 'status',
    priority: 4,
  );
}
```

---


## 7. System Maintenance & Admin

### 7.1 System Maintenance Notification
**Location**: Admin panel or scheduled job  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: Users unaware of planned downtime

**Implementation**:
```dart
// Before scheduled maintenance (24 hours in advance)
await notificationApi.createNotification(
  createdBy: 'system',
  title: 'Scheduled Maintenance 🔧',
  message: 'The app will undergo maintenance on $maintenanceDate from $startTime to $endTime',
  type: 'system',
  targetType: 'all',
  data: {
    'maintenance_start': maintenanceStart.toIso8601String(),
    'maintenance_end': maintenanceEnd.toIso8601String(),
  },
  sound: 'default',
  category: 'system',
  priority: 7,
  scheduledAt: maintenanceStart.subtract(Duration(hours: 24)),
);
```

---

### 7.2 App Update Available
**Location**: Version check service  
**Current Status**: ❌ No notification  
**Priority**: **LOW**  
**User Impact**: Users miss new features and bug fixes

**Implementation**:
```dart
// When new version is available
await notificationApi.createNotification(
  createdBy: 'system',
  title: 'New Version Available 🎉',
  message: 'Pavra $newVersion is now available with new features and improvements',
  type: 'promotion',
  targetType: 'all',
  data: {
    'action': 'update_app',
    'version': newVersion,
    'update_url': updateUrl,
    'release_notes': releaseNotes,
  },
  sound: 'default',
  category: 'promo',
  priority: 4,
);
```

---

### 7.3 Important Announcement
**Location**: Admin panel  
**Current Status**: ❌ No notification  
**Priority**: **MEDIUM**  
**User Impact**: Users miss important communications

**Implementation**:
```dart
// Admin creates announcement
await notificationApi.createNotification(
  createdBy: adminId,
  title: announcementTitle,
  message: announcementMessage,
  type: 'promotion',
  targetType: 'all',
  data: {
    'action': 'view_announcement',
    'announcement_id': announcementId,
  },
  sound: 'default',
  category: 'promo',
  priority: 6,
);
```

---


## 8. Social Interactions (Future Features)

### 8.1 User Follows Your Report
**Location**: Requires new feature - Report follow system  
**Current Status**: ❌ Feature doesn't exist  
**Priority**: **LOW** (Future enhancement)  
**User Impact**: Would increase engagement

**Suggested Implementation**:
```dart
// When user follows a report
await notificationApi.createNotification(
  createdBy: followerId,
  title: 'Someone Followed Your Report 👀',
  message: '$followerName is now following your report',
  type: 'user',
  targetType: 'single',
  targetUserIds: [reportCreatorId],
  data: {
    'action': 'view_report',
    'report_id': reportId,
    'follower_id': followerId,
  },
  sound: 'default',
  category: 'social',
  priority: 4,
);
```

---

### 8.2 Report Comments
**Location**: Requires new feature - Comment system  
**Current Status**: ❌ Feature doesn't exist  
**Priority**: **LOW** (Future enhancement)  
**User Impact**: Would increase community engagement

**Suggested Implementation**:
```dart
// When someone comments on a report
await notificationApi.createNotification(
  createdBy: commenterId,
  title: 'New Comment 💬',
  message: '$commenterName commented on your report',
  type: 'user',
  targetType: 'single',
  targetUserIds: [reportCreatorId],
  data: {
    'action': 'view_report',
    'report_id': reportId,
    'comment_id': commentId,
  },
  sound: 'default',
  category: 'social',
  priority: 5,
);
```

---


## 📋 Implementation Priority

### 🔴 CRITICAL Priority (Must Implement)
1. **Nearby Report Alerts** - Core safety feature ⭐⭐⭐
2. **Authority Request Approval/Rejection** - Essential user feedback ⭐⭐
3. **Critical AI Detection Alerts** - Immediate safety warnings ⭐⭐
4. **Monitored Route Alerts** - Proactive safety feature ⭐⭐

### 🟠 HIGH Priority (Should Implement)
5. **Report Submission Success** - User confirmation ⭐
6. **Report Verified** - Positive feedback loop ⭐
7. **Reputation Increased** - User motivation ⭐

### 🟡 MEDIUM Priority (Recommended)
8. **Report Marked as Spam** - User education
9. **Reputation Decreased** - Transparency
10. **Vote Threshold Reached** - Community validation
11. **Reputation Milestones** - Achievement system
12. **Request Submitted** - Confirmation
13. **New Pending Request (Admin)** - Admin workflow
14. **System Maintenance** - User communication
15. **Important Announcements** - Admin communication

### 🟢 LOW Priority (Optional)
16. **Welcome New User** - Onboarding
17. **Role Changed** - Status update
18. **Route Saved** - Confirmation
19. **Route Monitoring Enabled** - Status update
20. **Offline Queue Processed** - Sync confirmation
21. **App Update Available** - Feature awareness
22. **Detection Failed** - Error notification (may be noisy)

### 🔵 FUTURE Enhancements
23. **User Follows Report** - Requires new feature
24. **Report Comments** - Requires new feature

---


## 🛠️ Implementation Guide

### Step 1: Create Notification Helper Service

Create a centralized service to simplify notification creation:

```dart
// lib/core/services/notification_helper_service.dart
import '../api/notification/notification_api.dart';

class NotificationHelperService {
  final NotificationApi _notificationApi;
  
  NotificationHelperService(this._notificationApi);
  
  // ========== Report Notifications ==========
  
  Future<void> notifyReportSubmitted({
    required String userId,
    required String reportId,
    required String title,
  }) async {
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
    );
  }
  
  Future<void> notifyNearbyUsers({
    required String reportId,
    required String title,
    required double latitude,
    required double longitude,
    required String severity,
    required List<String> nearbyUserIds,
  }) async {
    if (nearbyUserIds.isEmpty) return;
    
    await _notificationApi.createNotification(
      createdBy: 'system',
      title: '⚠️ Nearby Road Hazard Alert',
      message: 'A new road issue has been reported near your location: $title',
      type: 'location_alert',
      targetType: 'custom',
      targetUserIds: nearbyUserIds,
      data: {
        'action': 'view_report',
        'report_id': reportId,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
      },
      sound: 'alert',
      category: 'alert',
      priority: 8,
    );
  }
  
  Future<void> notifyReportVerified({
    required String userId,
    required String reportId,
    required String reviewerId,
  }) async {
    await _notificationApi.createNotification(
      createdBy: reviewerId,
      title: 'Report Verified ✅',
      message: 'Your report has been verified by an authority',
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      relatedAction: reportId,
      data: {'action': 'view_report', 'report_id': reportId},
      sound: 'success',
      category: 'status',
      priority: 6,
    );
  }
  
  // ========== Authority Request Notifications ==========
  
  Future<void> notifyRequestApproved({
    required String userId,
    required String requestId,
    required String reviewerId,
  }) async {
    await _notificationApi.createNotification(
      createdBy: reviewerId,
      title: '🎉 Authority Request Approved',
      message: 'Congratulations! Your authority verification has been approved',
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      data: {'action': 'view_profile', 'request_id': requestId},
      sound: 'success',
      category: 'status',
      priority: 9,
    );
  }
  
  Future<void> notifyRequestRejected({
    required String userId,
    required String requestId,
    required String reviewerId,
    String? comment,
  }) async {
    await _notificationApi.createNotification(
      createdBy: reviewerId,
      title: 'Authority Request Rejected ❌',
      message: comment ?? 'Your authority verification request was not approved',
      type: 'warning',
      targetType: 'single',
      targetUserIds: [userId],
      data: {'action': 'view_request', 'request_id': requestId},
      sound: 'warning',
      category: 'status',
      priority: 7,
    );
  }
  
  // ========== Reputation Notifications ==========
  
  Future<void> notifyReputationChange({
    required String userId,
    required int changeAmount,
    required String actionType,
    required int scoreAfter,
  }) async {
    if (changeAmount == 0) return;
    
    final isPositive = changeAmount > 0;
    await _notificationApi.createNotification(
      createdBy: 'system',
      title: isPositive 
        ? 'Reputation Increased ⬆️ +$changeAmount'
        : 'Reputation Decreased ⬇️ $changeAmount',
      message: isPositive
        ? 'You earned $changeAmount reputation points for ${_getActionLabel(actionType)}'
        : 'You lost ${changeAmount.abs()} reputation points for ${_getActionLabel(actionType)}',
      type: isPositive ? 'success' : 'warning',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_profile',
        'reputation_change': changeAmount,
        'action_type': actionType,
        'new_score': scoreAfter,
      },
      sound: isPositive ? 'success' : 'warning',
      category: 'status',
    );
  }
  
  Future<void> notifyReputationMilestone({
    required String userId,
    required int milestone,
  }) async {
    String achievementMessage = '';
    String achievementIcon = '🏆';
    
    switch (milestone) {
      case 25:
        achievementMessage = 'You\'re becoming a trusted contributor!';
        achievementIcon = '🥉';
        break;
      case 50:
        achievementMessage = 'You\'re a valued community member!';
        achievementIcon = '🥈';
        break;
      case 75:
        achievementMessage = 'You\'re an expert road reporter!';
        achievementIcon = '🥇';
        break;
      case 100:
        achievementMessage = 'You\'ve reached maximum reputation!';
        achievementIcon = '👑';
        break;
    }
    
    await _notificationApi.createNotification(
      createdBy: 'system',
      title: '$achievementIcon Milestone Achieved!',
      message: 'Congratulations! Your reputation score reached $milestone. $achievementMessage',
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      data: {'action': 'view_profile', 'milestone': milestone},
      sound: 'success',
      category: 'status',
      priority: 7,
    );
  }
  
  // ========== AI Detection Notifications ==========
  
  Future<void> notifyCriticalDetection({
    required String userId,
    required String detectionId,
    required String issueType,
    required String severity,
    required double latitude,
    required double longitude,
    required double confidence,
  }) async {
    await _notificationApi.createNotification(
      createdBy: 'system',
      title: '🚨 Critical Road Hazard Detected',
      message: 'AI detected $issueType at your location. Immediate reporting recommended.',
      type: 'alert',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'create_report',
        'detection_id': detectionId,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        'type': issueType,
        'confidence': confidence,
      },
      sound: 'alert',
      category: 'alert',
      priority: 10,
    );
  }
  
  // ========== Helper Methods ==========
  
  String _getActionLabel(String actionType) {
    switch (actionType) {
      case 'UPLOAD_ISSUE': return 'submitting a report';
      case 'FIRST_REPORTER': return 'being the first to report';
      case 'DUPLICATE_REPORT': return 'duplicate report';
      case 'ABUSE_REPORT': return 'system abuse';
      case 'MANUAL_ADJUSTMENT': return 'manual adjustment';
      default: return actionType;
    }
  }
}
```

---

### Step 2: Integrate into API Classes

Example integration in `ReportIssueApi`:

```dart
// lib/core/api/report_issue/report_issue_api.dart
class ReportIssueApi {
  final NotificationHelperService _notificationHelper;
  final UserApi _userApi;
  
  ReportIssueApi(
    this._supabase,
    this._notificationHelper,
    this._userApi,
  ) {
    // ... existing initialization
  }
  
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
    }
    
    return report;
  }
}
```

---

### Step 3: Implement Get Nearby Users

Add method to `UserApi`:

```dart
// lib/core/api/user/user_api.dart
class UserApi {
  /// Get users within radius of a location who have location alerts enabled
  Future<List<String>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // Use Supabase RPC function
      final result = await _db.rpc(
        'get_nearby_users',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_km': radiusKm,
        },
      );
      
      return (result as List).map((e) => e['id'] as String).toList();
    } catch (e) {
      developer.log('Error getting nearby users: $e', name: 'UserApi');
      return [];
    }
  }
}
```

---

### Step 4: Create Supabase Function

Create database function to get nearby users:

```sql
-- lib/database/functions/get_nearby_users.sql

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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_nearby_users(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
```

**Note**: This function assumes you have a `location_alerts_enabled` column in `user_alert_preferences`. If not, add it:

```sql
ALTER TABLE user_alert_preferences 
ADD COLUMN IF NOT EXISTS location_alerts_enabled BOOLEAN DEFAULT true;
```

---


## 📊 Notification Type Mapping

| Event | Type | Sound | Category | Priority | Urgency |
|-------|------|-------|----------|----------|---------|
| Report Submitted | success | success | status | 5 | Normal |
| Nearby Report Alert | location_alert | alert | alert | 8 | High |
| Report Verified | success | success | status | 6 | Normal |
| Report Spam | warning | warning | warning | 6 | Normal |
| Request Approved | success | success | status | 9 | High |
| Request Rejected | warning | warning | status | 7 | Normal |
| Reputation Increased | success | success | status | 5 | Normal |
| Reputation Decreased | warning | warning | warning | 6 | Normal |
| Reputation Milestone | success | success | status | 7 | Normal |
| Critical AI Detection | alert | alert | alert | 10 | Critical |
| Monitored Route Issue | location_alert | alert | alert | 8 | High |
| Welcome New User | info | default | system | 5 | Normal |
| System Maintenance | system | default | system | 7 | Normal |
| App Update | promotion | default | promo | 4 | Low |
| Vote Threshold | info | default | social | 5 | Normal |

---

## 🧪 Testing Strategy

### Unit Tests

```dart
// test/services/notification_helper_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('NotificationHelperService', () {
    late MockNotificationApi mockApi;
    late NotificationHelperService service;
    
    setUp(() {
      mockApi = MockNotificationApi();
      service = NotificationHelperService(mockApi);
    });
    
    test('should send report submission notification', () async {
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
      )).called(1);
    });
    
    test('should send nearby users notification', () async {
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
        priority: 8,
      )).called(1);
    });
    
    test('should not send notification if no nearby users', () async {
      await service.notifyNearbyUsers(
        reportId: 'report-123',
        title: 'Pothole',
        latitude: 40.7128,
        longitude: -74.0060,
        severity: 'high',
        nearbyUserIds: [],
      );
      
      verifyNever(mockApi.createNotification(any));
    });
  });
}
```

---

### Integration Tests

```dart
// integration_test/notification_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Notification Flow', () {
    testWidgets('Report submission triggers notification', (tester) async {
      // 1. Login
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // 2. Navigate to report submission
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // 3. Fill form and submit
      await tester.enterText(find.byKey(Key('title_field')), 'Test Report');
      await tester.enterText(find.byKey(Key('description_field')), 'Test Description');
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pumpAndSettle();
      
      // 4. Verify success message
      expect(find.text('Report Submitted Successfully'), findsOneWidget);
      
      // 5. Check notification was created
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      
      expect(find.text('Report Submitted Successfully'), findsOneWidget);
    });
    
    testWidgets('Authority approval triggers notification', (tester) async {
      // Test authority request approval flow
      // ...
    });
  });
}
```

---


## 🔍 Code Location Reference

### Files to Modify

1. **lib/core/api/report_issue/report_issue_api.dart**
   - `submitReport()` - Add report submission success + nearby user notifications
   - `markAsReviewed()` - Add report verification notification
   - `markAsSpam()` - Add spam notification
   - `voteVerify()` / `voteSpam()` - Add vote threshold notifications

2. **lib/core/api/authority_request/authority_request_api.dart**
   - `createRequest()` - Add request submission + admin notification
   - `updateRequestStatus()` - Add approval/rejection notifications

3. **lib/core/api/reputation/reputation_api.dart**
   - `addReputationRecord()` - Add reputation change + milestone notifications

4. **lib/core/api/detection/ai_detection_api.dart**
   - `detectRoadDamage()` - Add critical detection notification

5. **lib/core/api/user/user_api.dart**
   - `createProfile()` / `upsertProfile()` - Add welcome notification
   - `updateProfile()` - Add role change notification
   - Add `getNearbyUsers()` method

6. **lib/core/api/saved_route/saved_route_api.dart**
   - `createRoute()` - Add route saved notification
   - `toggleRouteMonitoring()` - Add monitoring enabled notification
   - Add `getUsersMonitoringRoute()` method

### Files to Create

1. **lib/core/services/notification_helper_service.dart**
   - Centralized notification creation service

2. **lib/database/functions/get_nearby_users.sql**
   - Supabase function to get nearby users

3. **lib/database/functions/get_users_monitoring_route.sql**
   - Supabase function to get users monitoring a route

---

## 📝 Implementation Checklist

### Phase 1: Critical Notifications (Week 1)
- [ ] Create `NotificationHelperService`
- [ ] Implement `getNearbyUsers()` in UserApi
- [ ] Create `get_nearby_users()` Supabase function
- [ ] Add nearby report alert notification
- [ ] Add authority request approval notification
- [ ] Add authority request rejection notification
- [ ] Add critical AI detection notification
- [ ] Test critical notifications

### Phase 2: High Priority Notifications (Week 2)
- [ ] Add report submission success notification
- [ ] Add report verified notification
- [ ] Add reputation increased notification
- [ ] Implement reputation milestone detection
- [ ] Add reputation milestone notification
- [ ] Test high priority notifications

### Phase 3: Medium Priority Notifications (Week 3)
- [ ] Add report spam notification
- [ ] Add reputation decreased notification
- [ ] Add vote threshold notifications
- [ ] Add request submitted notification
- [ ] Add new pending request (admin) notification
- [ ] Add system maintenance notification
- [ ] Add important announcement notification
- [ ] Test medium priority notifications

### Phase 4: Low Priority & Route Monitoring (Week 4)
- [ ] Implement `getUsersMonitoringRoute()` in SavedRouteApi
- [ ] Create `get_users_monitoring_route()` Supabase function
- [ ] Add monitored route issue notification
- [ ] Add welcome new user notification
- [ ] Add role changed notification
- [ ] Add route saved notification
- [ ] Add route monitoring enabled notification
- [ ] Add offline queue processed notification
- [ ] Add app update notification
- [ ] Test all remaining notifications

### Phase 5: Testing & Optimization (Week 5)
- [ ] Write unit tests for NotificationHelperService
- [ ] Write integration tests for notification flows
- [ ] Performance testing (notification delivery time)
- [ ] User acceptance testing
- [ ] Monitor notification open rates
- [ ] Optimize notification content based on feedback
- [ ] Document notification system

---

## 🎯 Expected Outcomes

After implementing these notifications, users will experience:

### Improved Safety
- **Real-time hazard alerts** for nearby road issues
- **Proactive warnings** for monitored routes
- **Immediate feedback** on critical AI detections

### Better Engagement
- **Timely feedback** on report submissions and status
- **Motivation** through reputation notifications
- **Community validation** through vote notifications

### Enhanced Transparency
- **Clear communication** on authority request status
- **System updates** for maintenance and new features
- **Achievement recognition** through milestones

### Measurable Metrics
- **Notification open rate**: Target 40%+
- **User retention**: Expected 15-20% increase
- **Report submission rate**: Expected 10-15% increase
- **User satisfaction**: Expected improvement in app ratings

---

## 📚 Related Documentation

- [OneSignal Integration Spec](.kiro/specs/onesignal-notification-integration/)
- [Notification Usage Guide](lib/docs/NOTIFICATION_USAGE.md)
- [API Documentation](lib/docs/API_DOCUMENTATION.md)
- [Architecture](lib/docs/ARCHITECTURE.md)
- [Database Schema](lib/database/schema.sql)

---

## 🔄 Maintenance & Updates

### Regular Reviews
- **Monthly**: Review notification open rates and adjust content
- **Quarterly**: Analyze user feedback and add new notification types
- **Annually**: Comprehensive audit of notification system

### Monitoring
- Track notification delivery success rate
- Monitor OneSignal API usage and costs
- Analyze user engagement with different notification types
- Identify and fix notification spam issues

### Future Enhancements
- Notification preferences per category
- Quiet hours customization
- Notification grouping/bundling
- Rich notifications with images
- Action buttons in notifications
- Notification history export

---

**Document Version**: 1.0  
**Last Updated**: 2024-11-27  
**Author**: Pavra Development Team  
**Status**: Ready for Implementation

