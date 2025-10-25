import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../services/upstash_redis_service.dart';
import '../services/supabase_service.dart';
import '../services/onesignal_service.dart';
import '../../server.dart';

/// Task that processes scheduled notifications from Upstash Redis
///
/// This task runs periodically (every minute) to check for and send scheduled notifications
class ScheduledNotificationTask extends FutureCall {
  static const Duration _checkInterval = Duration(minutes: 1);
  static const String _redisKeyPrefix = 'scheduled_notification:';

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      PLog.info('🔔 Running scheduled notification task...');

      final result = await _processScheduledNotifications(session);

      if (result['success'] == true) {
        PLog.info(
          '✓ Scheduled notification task completed: ${result['processed']} notifications processed',
        );
      } else {
        PLog.error('❌ Scheduled notification task failed: ${result['error']}');
      }
    } catch (e, stackTrace) {
      PLog.error('❌ Error in scheduled notification task', e, stackTrace);
    } finally {
      // Schedule next check
      _scheduleNextCheck(session);
    }
  }

  /// Process scheduled notifications from Redis
  Future<Map<String, dynamic>> _processScheduledNotifications(
      Session session) async {
    try {
      final redis = UpstashRedisService.instance;
      final supabase = SupabaseService.instance;
      final now = DateTime.now();

      // Get all scheduled notifications from Supabase
      final notifications = await supabase.select(
        'notifications',
        filters: {'status': 'scheduled'},
      );

      // Filter notifications that are due
      final dueNotifications = notifications.where((notification) {
        final scheduledAt = notification['scheduled_at'];
        if (scheduledAt == null) return false;

        final scheduledTime = DateTime.parse(scheduledAt);
        return scheduledTime.isBefore(now) ||
            scheduledTime.isAtSameMomentAs(now);
      }).toList();

      PLog.info('Found ${dueNotifications.length} due notifications');

      // Process each due notification
      for (final notification in dueNotifications) {
        try {
          await _sendScheduledNotification(session, notification);

          // Update notification status in Supabase
          await supabase.update(
            'notifications',
            {
              'status': 'sent',
              'sent_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            },
            filters: {'id': notification['id']},
          );

          // Remove from Redis if exists
          final redisKey =
              '$_redisKeyPrefix${notification['scheduled_at']}:${notification['id']}';
          await redis.delete(redisKey);

          PLog.info('✓ Sent scheduled notification: ${notification['id']}');
        } catch (e) {
          PLog.error('❌ Failed to send notification ${notification['id']}: $e');

          // Mark as failed in Supabase
          await supabase.update(
            'notifications',
            {
              'status': 'failed',
              'updated_at': now.toIso8601String(),
            },
            filters: {'id': notification['id']},
          );
        }
      }

      return {
        'success': true,
        'processed': dueNotifications.length,
      };
    } catch (e, stackTrace) {
      PLog.error('❌ Error processing scheduled notifications', e, stackTrace);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send a scheduled notification via OneSignal
  Future<void> _sendScheduledNotification(
    Session session,
    Map<String, dynamic> notification,
  ) async {
    final oneSignal = _getOneSignalService(session);
    final targetType = notification['target_type'] as String? ?? 'single';
    final title = notification['title'] as String;
    final message = notification['message'] as String;
    final type = notification['type'] as String;
    final data = notification['data'] as Map<String, dynamic>?;
    final notificationId = notification['id'] as String;

    switch (targetType) {
      case 'single':
        final userId = notification['user_id'] as String;
        await oneSignal.sendToUser(
          userId: userId,
          title: title,
          message: message,
          data: {
            'notification_id': notificationId,
            'type': type,
            ...?data,
          },
        );
        break;

      case 'custom':
        final targetUserIds = notification['target_user_ids'] as List?;
        if (targetUserIds != null && targetUserIds.isNotEmpty) {
          final userIds = targetUserIds.cast<String>();
          await oneSignal.sendToUsers(
            userIds: userIds,
            title: title,
            message: message,
            data: {
              'notification_id': notificationId,
              'type': type,
              ...?data,
            },
          );
        }
        break;

      case 'role':
        final targetRoles = notification['target_roles'] as List?;
        if (targetRoles != null && targetRoles.isNotEmpty) {
          final supabase = SupabaseService.instance;
          final users = await supabase.select('profiles');
          final filteredUsers = users.where((user) {
            final role = user['role'] as String?;
            return role != null && targetRoles.contains(role);
          }).toList();

          final userIds =
              filteredUsers.map((user) => user['id'] as String).toList();

          if (userIds.isNotEmpty) {
            await oneSignal.sendToUsers(
              userIds: userIds,
              title: title,
              message: message,
              data: {
                'notification_id': notificationId,
                'type': type,
                ...?data,
              },
            );
          }
        }
        break;

      case 'all':
        await oneSignal.sendToAll(
          title: title,
          message: message,
          data: {
            'notification_id': notificationId,
            'type': type,
            ...?data,
          },
        );
        break;
    }
  }

  /// Get OneSignal service instance
  OneSignalService _getOneSignalService(Session session) {
    // Try to get from passwords.yaml first
    var appId = session.serverpod.getPassword('oneSignalAppId');
    var apiKey = session.serverpod.getPassword('oneSignalApiKey');

    // If not in passwords.yaml or contains placeholder, try environment variables
    if (appId == null || appId.isEmpty || appId.startsWith('\${')) {
      appId = Platform.environment['ONESIGNAL_APP_ID'] ?? '';
    }
    if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('\${')) {
      apiKey = Platform.environment['ONESIGNAL_API_KEY'] ?? '';
    }

    if (appId.isEmpty || apiKey.isEmpty) {
      PLog.warn(
        '⚠️ OneSignal credentials not configured. Push notifications will not be sent.',
      );
    }

    return OneSignalService(
      appId: appId,
      apiKey: apiKey,
    );
  }

  /// Schedules the next notification check
  void _scheduleNextCheck(Session session) {
    session.serverpod.futureCallAtTime(
      'scheduledNotificationCheck',
      null,
      DateTime.now().add(_checkInterval),
    );
  }
}

/// Initialize the scheduled notification task
Future<void> initializeScheduledNotificationTask(Serverpod pod) async {
  try {
    await pod.futureCallWithDelay(
      'scheduledNotificationCheck',
      null,
      const Duration(minutes: 1),
    );

    PLog.info('✓ Scheduled notification task registered.');
  } catch (e) {
    PLog.warn('⚠️ Failed to register scheduled notification task: $e');
    PLog.warn(
      '   Scheduled notifications will not be automatically sent.',
    );
  }
}
