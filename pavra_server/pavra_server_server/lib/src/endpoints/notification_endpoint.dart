import 'dart:io';
import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../services/onesignal_service.dart';
import '../services/supabase_service.dart';
import '../services/upstash_redis_service.dart';

/// Endpoint for notification operations
///
/// Handles sending push notifications via OneSignal
/// and managing notification records in Supabase
/// Supports scheduled notifications via Upstash Redis
class NotificationEndpoint extends Endpoint {
  /// Get OneSignal service instance with credentials from server
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
      session.log(
        '⚠️ OneSignal credentials not configured. Push notifications will not be sent.',
        level: LogLevel.warning,
      );
    }

    return OneSignalService(
      appId: appId,
      apiKey: apiKey,
    );
  }

  /// Get Supabase service instance
  SupabaseService get _supabase => SupabaseService.instance;

  /// Get Upstash Redis service instance
  UpstashRedisService get _redis => UpstashRedisService.instance;

  /// Send notification to a specific user
  ///
  /// Creates notification record in Supabase and sends push via OneSignal
  Future<Map<String, dynamic>> sendToUser(
    Session session, {
    required String userId,
    required String title,
    required String message,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
    String? createdBy,
  }) async {
    try {
      final oneSignal = _getOneSignalService(session);

      // 1. Create notification record in Supabase
      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'related_action': relatedAction,
        'data': data,
        'target_type': 'single',
        'target_user_ids': [userId],
        'created_by': createdBy,
      };

      final notifications =
          await _supabase.insert('notifications', [notificationData]);
      final notification = notifications.first;

      // 2. Send push notification via OneSignal
      try {
        await oneSignal.sendToUser(
          userId: userId,
          title: title,
          message: message,
          data: {
            'notification_id': notification['id'],
            'type': type,
            ...?data,
          },
        );
      } catch (e) {
        session.log('⚠️ Failed to send push notification: $e',
            level: LogLevel.warning);
        // Continue even if push fails - notification is still in database
      }

      return {
        'success': true,
        'notification': notification,
      };
    } catch (e) {
      session.log('❌ Error sending notification: $e', level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send notification to multiple users
  Future<Map<String, dynamic>> sendToUsers(
    Session session, {
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
    String? createdBy,
  }) async {
    try {
      final oneSignal = _getOneSignalService(session);

      // 1. Create single notification record with target_user_ids array
      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'related_action': relatedAction,
        'data': data,
        'target_type': 'custom',
        'target_user_ids': userIds,
        'created_by': createdBy,
      };

      final notifications =
          await _supabase.insert('notifications', [notificationData]);

      // 2. Send push notification via OneSignal
      try {
        await oneSignal.sendToUsers(
          userIds: userIds,
          title: title,
          message: message,
          data: {
            'notification_id': notifications.first['id'],
            'type': type,
            ...?data,
          },
        );
      } catch (e) {
        session.log('⚠️ Failed to send push notification: $e',
            level: LogLevel.warning);
      }

      return {
        'success': true,
        'count': userIds.length,
        'notification': notifications.first,
      };
    } catch (e) {
      session.log('❌ Error sending notifications: $e', level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send notification to all users (broadcast)
  ///
  /// Use with caution - sends to ALL users
  Future<Map<String, dynamic>> sendToAll(
    Session session, {
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    try {
      final oneSignal = _getOneSignalService(session);

      // Send push notification via OneSignal
      final result = await oneSignal.sendToAll(
        title: title,
        message: message,
        data: {
          'type': type,
          ...?data,
        },
      );

      // Note: We don't create individual notification records for broadcast
      // as it would create too many database entries
      // Users will receive the push notification directly

      return {
        'success': true,
        'onesignal_result': result,
      };
    } catch (e) {
      session.log('❌ Error sending broadcast: $e', level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send app update notification
  ///
  /// Convenience method for sending app update notifications
  Future<Map<String, dynamic>> sendAppUpdateNotification(
    Session session, {
    required String version,
    required String updateMessage,
    bool isRequired = false,
  }) async {
    return await sendToAll(
      session,
      title: isRequired ? 'Update Required' : 'New Update Available',
      message: 'Version $version: $updateMessage',
      type: isRequired ? 'alert' : 'system',
      data: {
        'update_type': 'app_update',
        'version': version,
        'is_required': isRequired,
      },
    );
  }

  /// Send new feature announcement
  Future<Map<String, dynamic>> sendFeatureAnnouncement(
    Session session, {
    required String featureName,
    required String description,
  }) async {
    return await sendToAll(
      session,
      title: 'New Feature: $featureName',
      message: description,
      type: 'promotion',
      data: {
        'announcement_type': 'new_feature',
        'feature_name': featureName,
      },
    );
  }

  /// Send activity notification
  Future<Map<String, dynamic>> sendActivityNotification(
    Session session, {
    required String userId,
    required String activityTitle,
    required String activityMessage,
  }) async {
    return await sendToUser(
      session,
      userId: userId,
      title: activityTitle,
      message: activityMessage,
      type: 'promotion',
      data: {
        'notification_type': 'activity',
      },
    );
  }

  /// Schedule a notification to be sent at a specific time
  ///
  /// Creates notification record in Supabase with 'scheduled' status
  /// and stores in Redis for processing
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
  }) async {
    try {
      // 1. Create notification record in Supabase with 'scheduled' status
      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'related_action': relatedAction,
        'data': data,
        'status': 'scheduled',
        'scheduled_at': scheduledAt.toIso8601String(),
        'target_type': targetType,
        'target_roles': targetRoles,
        'target_user_ids': targetUserIds,
        'created_by': createdBy,
      };

      final notifications =
          await _supabase.insert('notifications', [notificationData]);
      final notification = notifications.first;

      // 2. Store in Redis for scheduled processing
      final scheduleKey =
          'scheduled_notification:${scheduledAt.millisecondsSinceEpoch}:${notification['id']}';
      final scheduleData = jsonEncode({
        'notification_id': notification['id'],
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'target_type': targetType,
        'target_user_ids': targetUserIds,
        'scheduled_at': scheduledAt.toIso8601String(),
      });

      await _redis.set(scheduleKey, scheduleData);

      session.log(
        '✓ Notification scheduled for ${scheduledAt.toIso8601String()}',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'notification': notification,
        'scheduled_at': scheduledAt.toIso8601String(),
      };
    } catch (e) {
      session.log('❌ Error scheduling notification: $e', level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Schedule notification for multiple users
  Future<Map<String, dynamic>> scheduleNotificationForUsers(
    Session session, {
    required List<String> userIds,
    required String title,
    required String message,
    required DateTime scheduledAt,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
    String? createdBy,
  }) async {
    try {
      // Create single notification with target_user_ids array
      final result = await scheduleNotification(
        session,
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        type: type,
        relatedAction: relatedAction,
        data: data,
        targetType: 'custom',
        targetUserIds: userIds,
        createdBy: createdBy,
      );

      return result;
    } catch (e) {
      session.log('❌ Error scheduling notifications: $e',
          level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Cancel a scheduled notification
  Future<Map<String, dynamic>> cancelScheduledNotification(
    Session session, {
    required String notificationId,
  }) async {
    try {
      // 1. Update notification status in Supabase
      await _supabase.update(
        'notifications',
        {
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': notificationId},
      );

      // 2. Remove from Redis (we need to find the key first)
      // Note: In production, you might want to maintain an index
      // For now, we'll just update the database status

      session.log('✓ Notification cancelled: $notificationId',
          level: LogLevel.info);

      return {
        'success': true,
        'notification_id': notificationId,
      };
    } catch (e) {
      session.log('❌ Error cancelling notification: $e', level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Handle notification created from Flutter client
  ///
  /// This is called when a notification is created via the Flutter app
  /// It sends the push notification based on target_type
  Future<Map<String, dynamic>> handleNotificationCreated(
    Session session, {
    required String notificationId,
  }) async {
    try {
      // 1. Get notification from Supabase
      final notifications = await _supabase.select(
        'notifications',
        filters: {'id': notificationId},
      );

      if (notifications.isEmpty) {
        throw Exception('Notification not found: $notificationId');
      }

      final notification = notifications.first;
      final status = notification['status'] as String;

      // 2. Only send if status is 'sent'
      if (status != 'sent') {
        return {
          'success': true,
          'message': 'Notification is not ready to send (status: $status)',
        };
      }

      final oneSignal = _getOneSignalService(session);
      final targetType = notification['target_type'] as String? ?? 'single';
      final title = notification['title'] as String;
      final message = notification['message'] as String;
      final type = notification['type'] as String;
      final data = notification['data'] as Map<String, dynamic>?;

      // 3. Send based on target_type
      switch (targetType) {
        case 'single':
          // Send to single user (get from target_user_ids array)
          final targetUserIds = notification['target_user_ids'] as List?;
          if (targetUserIds != null && targetUserIds.isNotEmpty) {
            final userId = targetUserIds.first as String;
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
          }
          break;

        case 'all':
          // Send to all users
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

        case 'role':
          // Send to users with specific roles
          final targetRoles = notification['target_roles'] as List?;
          if (targetRoles != null && targetRoles.isNotEmpty) {
            // Get users with these roles
            final users = await _supabase.select('profiles');
            final filteredUsers = users.where((user) {
              final role = user['role'] as String?;
              return role != null && targetRoles.contains(role);
            }).toList();

            final userIds =
                filteredUsers.map((user) => user['id'] as String).toList();

            if (userIds.isNotEmpty) {
              // Update target_user_ids in database for RLS policy
              await _supabase.update(
                'notifications',
                {'target_user_ids': userIds},
                filters: {'id': notificationId},
              );

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

        case 'custom':
          // Send to custom list of users
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
      }

      session.log('✓ Push notification sent for: $notificationId',
          level: LogLevel.info);

      return {
        'success': true,
        'notification_id': notificationId,
        'target_type': targetType,
      };
    } catch (e) {
      session.log('❌ Error handling notification: $e', level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Process scheduled notifications (called by cron job or task)
  ///
  /// This should be called periodically to check for and send scheduled notifications
  Future<Map<String, dynamic>> processScheduledNotifications(
    Session session,
  ) async {
    try {
      final now = DateTime.now();

      // Get all scheduled notifications that are due
      final dueNotifications = await _supabase.select(
        'notifications',
        filters: {'status': 'scheduled'},
      );

      // Filter by scheduled_at in memory (Supabase doesn't support <= in filters)
      final filteredNotifications = dueNotifications.where((notification) {
        final scheduledAt = DateTime.parse(notification['scheduled_at']);
        return scheduledAt.isBefore(now) || scheduledAt.isAtSameMomentAs(now);
      }).toList();

      final results = <Map<String, dynamic>>[];

      for (final notification in filteredNotifications) {
        try {
          final oneSignal = _getOneSignalService(session);
          final targetType = notification['target_type'] as String? ?? 'single';
          final targetUserIds = notification['target_user_ids'] as List?;

          // Send push notification based on target_type
          if (targetType == 'single' &&
              targetUserIds != null &&
              targetUserIds.isNotEmpty) {
            await oneSignal.sendToUser(
              userId: targetUserIds.first as String,
              title: notification['title'],
              message: notification['message'],
              data: {
                'notification_id': notification['id'],
                'type': notification['type'],
                ...?notification['data'],
              },
            );
          } else if (targetType == 'custom' &&
              targetUserIds != null &&
              targetUserIds.isNotEmpty) {
            await oneSignal.sendToUsers(
              userIds: targetUserIds.cast<String>(),
              title: notification['title'],
              message: notification['message'],
              data: {
                'notification_id': notification['id'],
                'type': notification['type'],
                ...?notification['data'],
              },
            );
          } else if (targetType == 'all') {
            await oneSignal.sendToAll(
              title: notification['title'],
              message: notification['message'],
              data: {
                'notification_id': notification['id'],
                'type': notification['type'],
                ...?notification['data'],
              },
            );
          }

          // Update notification status
          await _supabase.update(
            'notifications',
            {
              'status': 'sent',
              'sent_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            },
            filters: {'id': notification['id']},
          );

          results.add({
            'notification_id': notification['id'],
            'status': 'sent',
          });
        } catch (e) {
          // Mark as failed
          await _supabase.update(
            'notifications',
            {
              'status': 'failed',
              'updated_at': now.toIso8601String(),
            },
            filters: {'id': notification['id']},
          );

          results.add({
            'notification_id': notification['id'],
            'status': 'failed',
            'error': e.toString(),
          });
        }
      }

      session.log('✓ Processed ${results.length} scheduled notifications',
          level: LogLevel.info);

      return {
        'success': true,
        'processed': results.length,
        'results': results,
      };
    } catch (e) {
      session.log('❌ Error processing scheduled notifications: $e',
          level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
