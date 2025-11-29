import 'dart:developer' as developer;
import '../api/notification/notification_api.dart';

/// NotificationHelperService - Centralized service for creating notifications
/// with pre-configured templates for all business events.
///
/// This service simplifies notification creation by providing methods for each
/// notification type with automatic configuration of sound, category, and priority.
/// All methods include error handling to prevent notification failures from
/// disrupting business logic.
class NotificationHelperService {
  final NotificationApi _notificationApi;

  NotificationHelperService(this._notificationApi);

  /// Internal helper to wrap notification creation with error handling
  /// and performance monitoring
  Future<void> _createNotificationSafely({
    required String title,
    required String message,
    required String type,
    required String targetType,
    List<String>? targetRoles,
    List<String>? targetUserIds,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
    String methodName = 'createNotification',
  }) async {
    final startTime = DateTime.now();
    
    // Use 'system' as createdBy for automated notifications
    const createdBy = 'system';
    
    developer.log(
      '🔔 Creating notification: $title',
      name: 'NotificationHelperService',
      time: DateTime.now(),
    );
    developer.log(
      '   Method: $methodName, Type: $type, Target: $targetType, Users: ${targetUserIds?.length ?? 0}',
      name: 'NotificationHelperService',
      time: DateTime.now(),
    );
    
    try {
      final result = await _notificationApi.createNotification(
        createdBy: createdBy,
        title: title,
        message: message,
        type: type,
        targetType: targetType,
        targetRoles: targetRoles,
        targetUserIds: targetUserIds,
        data: data,
        sound: sound,
        category: category,
        priority: priority ?? 5,
      );
      
      developer.log(
        '✅ Notification created successfully: ${result['id']}',
        name: 'NotificationHelperService',
        time: DateTime.now(),
      );

      // Performance logging for slow operations
      final duration = DateTime.now().difference(startTime);
      if (duration.inMilliseconds > 500) {
        developer.log(
          'Slow notification operation: ${duration.inMilliseconds}ms in $methodName',
          name: 'NotificationHelperService',
          level: 900, // WARNING level
          time: DateTime.now(),
        );
      }
    } catch (e, stackTrace) {
      // Log error with full context but don't throw - notification failures shouldn't disrupt business logic
      developer.log(
        'Failed to create notification in $methodName',
        name: 'NotificationHelperService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR level
        time: DateTime.now(),
      );
      
      // Log additional context for debugging
      developer.log(
        'Notification context: type=$type, targetType=$targetType, '
        'targetUserIds=${targetUserIds?.length ?? 0}, targetRoles=${targetRoles?.length ?? 0}, '
        'priority=${priority ?? 5}, sound=$sound, category=$category',
        name: 'NotificationHelperService',
        level: 1000, // ERROR level
        time: DateTime.now(),
      );
    }
  }

  // ========== Report Notifications ==========

  /// Notify user that their report was successfully submitted
  Future<void> notifyReportSubmitted({
    required String userId,
    required String reportId,
    required String title,
  }) async {
    await _createNotificationSafely(
      title: 'Report Submitted Successfully ✅',
      message: 'Your road issue report "$title" has been submitted',
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_report',
        'report_id': reportId,
      },
      sound: 'success',
      category: 'status',
      priority: 5,
      methodName: 'notifyReportSubmitted',
    );
  }

  /// Notify nearby users about a new report in their area
  Future<void> notifyNearbyUsers({
    required String reportId,
    required String title,
    required double latitude,
    required double longitude,
    required String severity,
    required List<String> nearbyUserIds,
  }) async {
    if (nearbyUserIds.isEmpty) {
      return; // Skip if no nearby users
    }

    await _createNotificationSafely(
      title: '⚠️ Nearby Road Issue Alert',
      message: 'A $severity severity issue "$title" was reported near you',
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
      methodName: 'notifyNearbyUsers',
    );
  }

  /// Notify user that their report was verified by an authority
  Future<void> notifyReportVerified({
    required String userId,
    required String reportId,
    required String reviewerId,
  }) async {
    await _createNotificationSafely(
      title: 'Report Verified ✓',
      message: 'Your report has been verified by an authority',
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_report',
        'report_id': reportId,
        'reviewer_id': reviewerId,
      },
      sound: 'success',
      category: 'status',
      priority: 6,
      methodName: 'notifyReportVerified',
    );
  }

  /// Notify user that their report was marked as spam
  Future<void> notifyReportSpam({
    required String userId,
    required String reportId,
    required String reviewerId,
    String? comment,
  }) async {
    final message = comment != null
        ? 'Your report was marked as spam. Reason: $comment'
        : 'Your report was marked as spam by an authority';

    await _createNotificationSafely(
      title: '⚠️ Report Marked as Spam',
      message: message,
      type: 'warning',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_report',
        'report_id': reportId,
        'reviewer_id': reviewerId,
        'comment': comment,
      },
      sound: 'warning',
      category: 'warning',
      priority: 6,
      methodName: 'notifyReportSpam',
    );
  }

  /// Notify user when their report reaches vote thresholds
  Future<void> notifyVoteThreshold({
    required String userId,
    required String reportId,
    required String voteType,
    required int voteCount,
  }) async {
    final isVerified = voteType == 'verified';
    final title = isVerified
        ? '✓ Community Verification'
        : '⚠️ Community Flagging';
    final message = isVerified
        ? 'Your report received $voteCount verification votes from the community'
        : 'Your report received $voteCount spam votes from the community';

    await _createNotificationSafely(
      title: title,
      message: message,
      type: isVerified ? 'info' : 'warning',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_report',
        'report_id': reportId,
        'vote_type': voteType,
        'vote_count': voteCount,
      },
      sound: isVerified ? 'success' : 'warning',
      category: isVerified ? 'status' : 'warning',
      priority: 6,
      methodName: 'notifyVoteThreshold',
    );
  }


  // ========== Authority Request Notifications ==========

  /// Notify user that their authority request was submitted
  Future<void> notifyRequestSubmitted({
    required String userId,
    required String requestId,
  }) async {
    await _createNotificationSafely(
      title: 'Authority Request Submitted',
      message: 'Your authority verification request has been submitted and is under review',
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
      methodName: 'notifyRequestSubmitted',
    );
  }

  /// Notify user that their authority request was approved
  Future<void> notifyRequestApproved({
    required String userId,
    required String requestId,
    required String reviewerId,
  }) async {
    await _createNotificationSafely(
      title: '🎉 Authority Request Approved',
      message: 'Congratulations! Your authority verification request has been approved',
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_request',
        'request_id': requestId,
        'reviewer_id': reviewerId,
      },
      sound: 'success',
      category: 'status',
      priority: 9,
      methodName: 'notifyRequestApproved',
    );
  }

  /// Notify user that their authority request was rejected
  Future<void> notifyRequestRejected({
    required String userId,
    required String requestId,
    required String reviewerId,
    String? comment,
  }) async {
    final message = comment != null
        ? 'Your authority request was rejected. Reason: $comment'
        : 'Your authority verification request was rejected';

    await _createNotificationSafely(
      title: 'Authority Request Rejected',
      message: message,
      type: 'warning',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_request',
        'request_id': requestId,
        'reviewer_id': reviewerId,
        'comment': comment,
      },
      sound: 'warning',
      category: 'warning',
      priority: 7,
      methodName: 'notifyRequestRejected',
    );
  }

  /// Notify admins about a new authority request
  Future<void> notifyAdminsNewRequest({
    required String requestId,
    required String userId,
    required String username,
  }) async {
    await _createNotificationSafely(
      title: '📋 New Authority Request',
      message: 'User $username has submitted an authority verification request',
      type: 'info',
      targetType: 'role',
      targetRoles: ['admin', 'developer'],
      data: {
        'action': 'review_request',
        'request_id': requestId,
        'user_id': userId,
      },
      sound: 'default',
      category: 'status',
      priority: 7,
      methodName: 'notifyAdminsNewRequest',
    );
  }


  // ========== Reputation Notifications ==========

  /// Notify user about reputation changes
  Future<void> notifyReputationChange({
    required String userId,
    required int changeAmount,
    required String actionType,
    required int scoreAfter,
  }) async {
    if (changeAmount == 0) {
      return; // Skip notification for zero change
    }

    final isPositive = changeAmount > 0;
    final title = isPositive
        ? '⬆️ Reputation Increased'
        : '⬇️ Reputation Decreased';
    final message = isPositive
        ? 'You gained ${changeAmount.abs()} reputation points for $actionType. Total: $scoreAfter'
        : 'You lost ${changeAmount.abs()} reputation points for $actionType. Total: $scoreAfter';

    await _createNotificationSafely(
      title: title,
      message: message,
      type: isPositive ? 'success' : 'warning',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_profile',
        'change_amount': changeAmount,
        'action_type': actionType,
        'score_after': scoreAfter,
      },
      sound: isPositive ? 'success' : 'warning',
      category: 'status',
      priority: isPositive ? 5 : 6,
      methodName: 'notifyReputationChange',
    );
  }

  /// Notify user about reaching reputation milestones
  Future<void> notifyReputationMilestone({
    required String userId,
    required int milestone,
  }) async {
    // Define milestone-specific messages and icons
    final milestoneData = _getMilestoneData(milestone);
    if (milestoneData == null) {
      return; // Invalid milestone
    }

    await _createNotificationSafely(
      title: '${milestoneData['icon']} ${milestoneData['title']}',
      message: milestoneData['message'],
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_profile',
        'milestone': milestone,
        'achievement': milestoneData['achievement'],
      },
      sound: 'success',
      category: 'status',
      priority: 7,
      methodName: 'notifyReputationMilestone',
    );
  }

  /// Get milestone-specific data
  Map<String, dynamic>? _getMilestoneData(int milestone) {
    switch (milestone) {
      case 25:
        return {
          'icon': '🥉',
          'title': 'Bronze Achievement',
          'message': 'Congratulations! You\'ve reached 25 reputation points',
          'achievement': 'bronze',
        };
      case 50:
        return {
          'icon': '🥈',
          'title': 'Silver Achievement',
          'message': 'Amazing! You\'ve reached 50 reputation points',
          'achievement': 'silver',
        };
      case 75:
        return {
          'icon': '🥇',
          'title': 'Gold Achievement',
          'message': 'Excellent! You\'ve reached 75 reputation points',
          'achievement': 'gold',
        };
      case 100:
        return {
          'icon': '👑',
          'title': 'Crown Achievement',
          'message': 'Outstanding! You\'ve reached 100 reputation points',
          'achievement': 'crown',
        };
      default:
        return null;
    }
  }


  // ========== AI Detection Notifications ==========

  /// Notify user about critical AI detections
  Future<void> notifyCriticalDetection({
    required String userId,
    required String detectionId,
    required String issueType,
    required String severity,
    required double latitude,
    required double longitude,
    required double confidence,
  }) async {
    final isCritical = severity.toLowerCase() == 'critical';
    final priority = isCritical ? 10 : 8;
    final title = isCritical
        ? '🚨 Critical Road Hazard Detected'
        : '⚠️ High Severity Road Issue Detected';
    final message = 'AI detected a $severity severity $issueType (${(confidence * 100).toStringAsFixed(0)}% confidence)';

    await _createNotificationSafely(
      title: title,
      message: message,
      type: 'alert',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_detection',
        'detection_id': detectionId,
        'issue_type': issueType,
        'severity': severity,
        'latitude': latitude,
        'longitude': longitude,
        'confidence': confidence,
      },
      sound: 'alert',
      category: 'alert',
      priority: priority,
      methodName: 'notifyCriticalDetection',
    );
  }

  /// Notify user about offline queue processing
  Future<void> notifyOfflineQueueProcessed({
    required String userId,
    required int processedCount,
  }) async {
    await _createNotificationSafely(
      title: '✓ Offline Detections Synced',
      message: '$processedCount detection${processedCount != 1 ? 's' : ''} from offline queue have been processed',
      type: 'info',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_detections',
        'processed_count': processedCount,
      },
      sound: 'default',
      category: 'status',
      priority: 5,
      methodName: 'notifyOfflineQueueProcessed',
    );
  }


  // ========== Route Notifications ==========

  /// Notify users monitoring routes about issues
  Future<void> notifyMonitoredRouteIssue({
    required String reportId,
    required String title,
    required double latitude,
    required double longitude,
    required List<String> monitoringUserIds,
  }) async {
    if (monitoringUserIds.isEmpty) {
      return; // Skip if no monitoring users
    }

    await _createNotificationSafely(
      title: '🛣️ Issue on Monitored Route',
      message: 'A road issue "$title" was reported on one of your monitored routes',
      type: 'location_alert',
      targetType: 'custom',
      targetUserIds: monitoringUserIds,
      data: {
        'action': 'view_report',
        'report_id': reportId,
        'latitude': latitude,
        'longitude': longitude,
      },
      sound: 'alert',
      category: 'alert',
      priority: 8,
      methodName: 'notifyMonitoredRouteIssue',
    );
  }

  /// Notify user that their route was saved
  Future<void> notifyRouteSaved({
    required String userId,
    required String routeId,
    required String routeName,
  }) async {
    await _createNotificationSafely(
      title: '✓ Route Saved',
      message: 'Your route "$routeName" has been saved successfully',
      type: 'success',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_route',
        'route_id': routeId,
      },
      sound: 'success',
      category: 'status',
      priority: 5,
      methodName: 'notifyRouteSaved',
    );
  }

  /// Notify user that route monitoring was enabled
  Future<void> notifyRouteMonitoringEnabled({
    required String userId,
    required String routeId,
    required String routeName,
  }) async {
    await _createNotificationSafely(
      title: '👁️ Route Monitoring Enabled',
      message: 'You will now receive alerts for issues on "$routeName"',
      type: 'info',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_route',
        'route_id': routeId,
      },
      sound: 'default',
      category: 'status',
      priority: 5,
      methodName: 'notifyRouteMonitoringEnabled',
    );
  }


  // ========== User Onboarding Notifications ==========

  /// Welcome new users with onboarding guidance
  Future<void> notifyWelcomeNewUser({
    required String userId,
  }) async {
    await _createNotificationSafely(
      title: '👋 Welcome to Pavra!',
      message: 'Start reporting road issues, earn reputation, and help make roads safer for everyone',
      type: 'info',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_onboarding',
      },
      sound: 'default',
      category: 'status',
      priority: 6,
      methodName: 'notifyWelcomeNewUser',
    );
  }

  /// Notify user about role changes
  Future<void> notifyRoleChanged({
    required String userId,
    required String newRole,
  }) async {
    await _createNotificationSafely(
      title: '🔄 Role Updated',
      message: 'Your role has been changed to $newRole',
      type: 'info',
      targetType: 'single',
      targetUserIds: [userId],
      data: {
        'action': 'view_profile',
        'new_role': newRole,
      },
      sound: 'default',
      category: 'status',
      priority: 6,
      methodName: 'notifyRoleChanged',
    );
  }


  // ========== System Notifications ==========

  /// Notify all users about system maintenance
  Future<void> notifySystemMaintenance({
    required DateTime maintenanceStart,
    required DateTime maintenanceEnd,
  }) async {
    final startFormatted = _formatDateTime(maintenanceStart);
    final endFormatted = _formatDateTime(maintenanceEnd);

    await _createNotificationSafely(
      title: '🔧 Scheduled Maintenance',
      message: 'System maintenance scheduled from $startFormatted to $endFormatted',
      type: 'system',
      targetType: 'all',
      data: {
        'action': 'view_announcement',
        'maintenance_start': maintenanceStart.toIso8601String(),
        'maintenance_end': maintenanceEnd.toIso8601String(),
      },
      sound: 'default',
      category: 'status',
      priority: 7,
      methodName: 'notifySystemMaintenance',
    );
  }

  /// Notify all users about app updates
  Future<void> notifyAppUpdate({
    required String newVersion,
    required String updateUrl,
    String? releaseNotes,
  }) async {
    final message = releaseNotes != null
        ? 'Version $newVersion is now available. $releaseNotes'
        : 'Version $newVersion is now available with new features and improvements';

    await _createNotificationSafely(
      title: '🚀 App Update Available',
      message: message,
      type: 'promotion',
      targetType: 'all',
      data: {
        'action': 'open_url',
        'url': updateUrl,
        'version': newVersion,
        'release_notes': releaseNotes,
      },
      sound: 'default',
      category: 'status',
      priority: 6,
      methodName: 'notifyAppUpdate',
    );
  }

  /// Notify all users about important announcements
  Future<void> notifyImportantAnnouncement({
    required String adminId,
    required String title,
    required String message,
    String? announcementId,
  }) async {
    await _createNotificationSafely(
      title: '📢 $title',
      message: message,
      type: 'promotion',
      targetType: 'all',
      data: {
        'action': 'view_announcement',
        'announcement_id': announcementId,
        'admin_id': adminId,
      },
      sound: 'default',
      category: 'status',
      priority: 7,
      methodName: 'notifyImportantAnnouncement',
    );
  }

  /// Helper to format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
