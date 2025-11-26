import 'package:logging/logging.dart';
import 'supabase_service.dart';

/// Service for alerting on notification failures and issues
///
/// Monitors notification delivery and alerts administrators when:
/// - High failure rates are detected
/// - OneSignal API errors occur
/// - QStash scheduling failures happen
class NotificationAlertingService {
  static final _log = Logger('NotificationAlertingService');
  final SupabaseService _supabase = SupabaseService.instance;

  // Thresholds for alerting
  static const double highFailureRateThreshold = 20.0; // 20% failure rate
  static const int minimumNotificationsForAlert = 10; // Need at least 10 notifications to trigger alert
  static const Duration alertCheckWindow = Duration(hours: 1); // Check last hour

  /// Check for high failure rates and alert if threshold exceeded
  ///
  /// Analyzes recent notifications to detect if failure rate exceeds threshold
  /// Returns true if alert was triggered
  Future<bool> checkAndAlertHighFailureRate() async {
    try {
      _log.info('🔍 Checking for high failure rates...');

      // Get notifications from the last hour
      final cutoffTime = DateTime.now().subtract(alertCheckWindow);
      final recentNotifications = await _supabase.select(
        'notifications',
        orderBy: 'created_at',
        ascending: false,
      );

      // Filter to last hour in memory
      final filteredNotifications = recentNotifications.where((notification) {
        final createdAt = DateTime.parse(notification['created_at'] as String);
        return createdAt.isAfter(cutoffTime);
      }).toList();

      if (filteredNotifications.length < minimumNotificationsForAlert) {
        _log.fine('ℹ️  Not enough notifications to check (${filteredNotifications.length} < $minimumNotificationsForAlert)');
        return false;
      }

      // Calculate failure rate
      final failedCount = filteredNotifications.where((n) => n['status'] == 'failed').length;
      final totalCount = filteredNotifications.length;
      final failureRate = (failedCount / totalCount * 100);

      _log.info('📊 Failure rate: ${failureRate.toStringAsFixed(2)}% ($failedCount/$totalCount)');

      if (failureRate >= highFailureRateThreshold) {
        _log.warning('⚠️  HIGH FAILURE RATE DETECTED: ${failureRate.toStringAsFixed(2)}%');
        
        // Create alert notification for admins
        await _createAdminAlert(
          title: 'High Notification Failure Rate',
          message: 'Notification failure rate is ${failureRate.toStringAsFixed(1)}% ($failedCount/$totalCount in last hour)',
          severity: 'warning',
          data: {
            'alert_type': 'high_failure_rate',
            'failure_rate': failureRate,
            'failed_count': failedCount,
            'total_count': totalCount,
            'time_window': alertCheckWindow.inHours,
          },
        );

        return true;
      }

      _log.info('✅ Failure rate is within acceptable range');
      return false;
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to check failure rate');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Alert on OneSignal API error
  ///
  /// Creates an alert notification when OneSignal API errors occur
  Future<void> alertOneSignalError({
    required String notificationId,
    required String errorMessage,
    int? statusCode,
  }) async {
    try {
      _log.warning('⚠️  OneSignal API Error detected');
      _log.warning('   Notification ID: $notificationId');
      _log.warning('   Error: $errorMessage');
      if (statusCode != null) {
        _log.warning('   Status Code: $statusCode');
      }

      await _createAdminAlert(
        title: 'OneSignal API Error',
        message: 'Failed to send notification: $errorMessage',
        severity: 'error',
        data: {
          'alert_type': 'onesignal_error',
          'notification_id': notificationId,
          'error_message': errorMessage,
          if (statusCode != null) 'status_code': statusCode,
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to create OneSignal error alert');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
    }
  }

  /// Alert on QStash scheduling failure
  ///
  /// Creates an alert notification when QStash scheduling fails
  Future<void> alertQStashError({
    required String notificationId,
    required String errorMessage,
    DateTime? scheduledAt,
  }) async {
    try {
      _log.warning('⚠️  QStash Scheduling Error detected');
      _log.warning('   Notification ID: $notificationId');
      _log.warning('   Error: $errorMessage');
      if (scheduledAt != null) {
        _log.warning('   Scheduled for: ${scheduledAt.toIso8601String()}');
      }

      await _createAdminAlert(
        title: 'QStash Scheduling Error',
        message: 'Failed to schedule notification: $errorMessage',
        severity: 'error',
        data: {
          'alert_type': 'qstash_error',
          'notification_id': notificationId,
          'error_message': errorMessage,
          if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to create QStash error alert');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
    }
  }

  /// Alert on repeated failures for a specific notification
  ///
  /// Tracks retry attempts and alerts if a notification fails multiple times
  Future<void> alertRepeatedFailure({
    required String notificationId,
    required int attemptCount,
    required String lastError,
  }) async {
    try {
      _log.warning('⚠️  Repeated Failure detected');
      _log.warning('   Notification ID: $notificationId');
      _log.warning('   Attempts: $attemptCount');
      _log.warning('   Last Error: $lastError');

      await _createAdminAlert(
        title: 'Repeated Notification Failure',
        message: 'Notification failed after $attemptCount attempts: $lastError',
        severity: 'error',
        data: {
          'alert_type': 'repeated_failure',
          'notification_id': notificationId,
          'attempt_count': attemptCount,
          'last_error': lastError,
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to create repeated failure alert');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
    }
  }

  /// Create an alert notification for administrators
  ///
  /// Internal method to create system alert notifications
  Future<void> _createAdminAlert({
    required String title,
    required String message,
    required String severity,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all admin and developer users
      final users = await _supabase.select('profiles');
      final adminUsers = users.where((user) {
        final role = user['role'] as String?;
        return role == 'admin' || role == 'developer';
      }).toList();

      if (adminUsers.isEmpty) {
        _log.warning('⚠️  No admin users found to send alert to');
        return;
      }

      final adminUserIds = adminUsers.map((user) => user['id'] as String).toList();

      // Create alert notification
      final notificationData = {
        'title': title,
        'message': message,
        'type': 'alert',
        'status': 'sent',
        'target_type': 'custom',
        'target_user_ids': adminUserIds,
        'sound': 'alert',
        'category': 'alert',
        'priority': 10, // Highest priority
        'data': {
          'severity': severity,
          'alert_category': 'notification_system',
          ...?data,
        },
      };

      await _supabase.insert('notifications', [notificationData]);

      _log.info('✅ Admin alert created: $title');
      _log.info('   Recipients: ${adminUserIds.length} admins');
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to create admin alert');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      // Don't rethrow - alerting failures should not break the main flow
    }
  }

  /// Get recent alerts for dashboard
  ///
  /// Returns list of recent alert notifications
  Future<List<Map<String, dynamic>>> getRecentAlerts({
    int limit = 50,
  }) async {
    try {
      _log.info('📊 Fetching recent alerts (limit: $limit)');

      final alerts = await _supabase.select(
        'notifications',
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      // Filter to only alert type notifications
      final filteredAlerts = alerts.where((notification) {
        final type = notification['type'] as String?;
        final data = notification['data'] as Map<String, dynamic>?;
        final alertCategory = data?['alert_category'] as String?;
        return type == 'alert' || alertCategory == 'notification_system';
      }).toList();

      _log.info('✅ Retrieved ${filteredAlerts.length} alerts');

      return filteredAlerts;
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to get recent alerts');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      return [];
    }
  }

  /// Check system health and alert if issues detected
  ///
  /// Performs comprehensive health check and creates alerts for any issues
  Future<Map<String, dynamic>> checkSystemHealth() async {
    try {
      _log.info('🏥 Performing system health check...');

      final issues = <String>[];
      
      // Check 1: High failure rate
      final hasHighFailureRate = await checkAndAlertHighFailureRate();
      if (hasHighFailureRate) {
        issues.add('High failure rate detected');
      }

      // Check 2: Recent failed notifications
      final recentNotifications = await _supabase.select(
        'notifications',
        orderBy: 'created_at',
        ascending: false,
        limit: 100,
      );

      final recentFailed = recentNotifications.where((n) => n['status'] == 'failed').length;
      if (recentFailed > 10) {
        issues.add('$recentFailed failed notifications in recent history');
      }

      // Check 3: Stuck scheduled notifications
      final now = DateTime.now();
      final scheduledNotifications = await _supabase.select(
        'notifications',
      );

      final stuckScheduled = scheduledNotifications.where((notification) {
        final status = notification['status'] as String;
        if (status != 'scheduled') return false;

        final scheduledAt = notification['scheduled_at'] as String?;
        if (scheduledAt == null) return false;

        final scheduledTime = DateTime.parse(scheduledAt);
        // If scheduled time is more than 1 hour in the past, it's stuck
        return scheduledTime.isBefore(now.subtract(Duration(hours: 1)));
      }).toList();

      if (stuckScheduled.isNotEmpty) {
        issues.add('${stuckScheduled.length} stuck scheduled notifications');
        
        // Alert on stuck notifications
        await _createAdminAlert(
          title: 'Stuck Scheduled Notifications',
          message: '${stuckScheduled.length} notifications are stuck in scheduled status',
          severity: 'warning',
          data: {
            'alert_type': 'stuck_scheduled',
            'count': stuckScheduled.length,
            'notification_ids': stuckScheduled.map((n) => n['id']).take(10).toList(),
          },
        );
      }

      final isHealthy = issues.isEmpty;

      _log.info(isHealthy ? '✅ System health check passed' : '⚠️  System health issues detected');
      if (!isHealthy) {
        for (final issue in issues) {
          _log.warning('   - $issue');
        }
      }

      return {
        'healthy': isHealthy,
        'issues': issues,
        'checked_at': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to perform health check');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      
      return {
        'healthy': false,
        'issues': ['Health check failed: $e'],
        'checked_at': DateTime.now().toIso8601String(),
      };
    }
  }
}
