import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod/protocol.dart';
import '../services/qstash_service.dart';
import '../services/supabase_service.dart';
import '../services/onesignal_service.dart';

/// Handler for processing scheduled notifications triggered by QStash
///
/// This is called by QStash webhook when a scheduled notification is due
class ScheduledNotificationTask {
  /// Process a single scheduled notification from QStash webhook
  static Future<Map<String, dynamic>> processNotification({
    required Session session,
    required String notificationId,
  }) async {
    try {
      session.log('🔔 Processing scheduled notification: $notificationId');

      final supabase = SupabaseService.instance;

      // Get notification from Supabase
      final notifications = await supabase.select(
        'notifications',
        filters: {'id': notificationId},
      );

      if (notifications.isEmpty) {
        throw Exception('Notification not found: $notificationId');
      }

      final notification = notifications.first;
      final status = notification['status'] as String?;

      // Check if already sent
      if (status == 'sent') {
        session.log('⚠️ Notification already sent: $notificationId');
        return {'success': true, 'message': 'Already sent'};
      }

      // Send the notification
      await _sendScheduledNotification(session, notification);

      // Update notification status in Supabase
      final now = DateTime.now();
      await supabase.update(
        'notifications',
        {
          'status': 'sent',
          'sent_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        filters: {'id': notificationId},
      );

      session.log('✓ Sent scheduled notification: $notificationId');

      return {
        'success': true,
        'notificationId': notificationId,
      };
    } catch (e) {
      session.log('❌ Error processing scheduled notification: $e',
          level: LogLevel.error);

      // Mark as failed in Supabase
      try {
        final supabase = SupabaseService.instance;
        await supabase.update(
          'notifications',
          {
            'status': 'failed',
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'id': notificationId},
        );
      } catch (_) {}

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send a scheduled notification via OneSignal
  static Future<void> _sendScheduledNotification(
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
  static OneSignalService _getOneSignalService(Session session) {
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
      stderr.writeln(
        '⚠️ OneSignal credentials not configured. Push notifications will not be sent.',
      );
    }

    return OneSignalService(
      appId: appId,
      apiKey: apiKey,
    );
  }

  /// Schedule a notification using QStash
  static Future<Map<String, dynamic>> scheduleNotification({
    required String notificationId,
    required DateTime scheduledAt,
    required String callbackUrl,
  }) async {
    try {
      final qstash = QStashService.instance;

      final result = await qstash.scheduleNotification(
        notificationId: notificationId,
        scheduledAt: scheduledAt,
        callbackUrl: callbackUrl,
      );

      stdout.writeln('✓ Scheduled notification via QStash: $notificationId');
      return result;
    } catch (e) {
      stderr.writeln('❌ Failed to schedule notification: $e');
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  static Future<bool> cancelScheduledNotification(String messageId) async {
    try {
      final qstash = QStashService.instance;
      return await qstash.cancelScheduledNotification(messageId);
    } catch (e) {
      stderr.writeln('❌ Failed to cancel scheduled notification: $e');
      return false;
    }
  }
}
