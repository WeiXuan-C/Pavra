import 'package:serverpod/serverpod.dart';
import '../services/onesignal_service.dart';
import '../services/supabase_service.dart';

/// Endpoint for notification operations
///
/// Handles sending push notifications via OneSignal
/// and managing notification records in Supabase
class NotificationEndpoint extends Endpoint {
  /// Get OneSignal service instance with credentials from server
  OneSignalService _getOneSignalService(Session session) {
    final appId = session.serverpod.getPassword('oneSignalAppId') ?? '';
    final apiKey = session.serverpod.getPassword('oneSignalApiKey') ?? '';

    return OneSignalService(
      appId: appId,
      apiKey: apiKey,
    );
  }

  /// Get Supabase service instance
  SupabaseService get _supabase => SupabaseService.instance;

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
  }) async {
    try {
      final oneSignal = _getOneSignalService(session);

      // 1. Create notification record in Supabase
      final notificationData = {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_action': relatedAction,
        'data': data,
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
  }) async {
    try {
      final oneSignal = _getOneSignalService(session);

      // 1. Create notification records in Supabase for each user
      final notificationDataList = userIds
          .map((userId) => {
                'user_id': userId,
                'title': title,
                'message': message,
                'type': type,
                'related_action': relatedAction,
                'data': data,
              })
          .toList();

      final notifications =
          await _supabase.insert('notifications', notificationDataList);

      // 2. Send push notification via OneSignal
      try {
        await oneSignal.sendToUsers(
          userIds: userIds,
          title: title,
          message: message,
          data: {
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
        'count': notifications.length,
        'notifications': notifications,
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
}
