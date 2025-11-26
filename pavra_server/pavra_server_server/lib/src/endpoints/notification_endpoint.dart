import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../services/onesignal_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_metrics_service.dart';
import '../services/notification_alerting_service.dart';
import '../services/permission_service.dart';
import '../services/notification_validation_service.dart';
import '../services/rate_limiting_service.dart';
import '../tasks/scheduled_notification_task.dart';

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

  /// Get NotificationMetricsService instance
  final NotificationMetricsService _metricsService = NotificationMetricsService();

  /// Get NotificationAlertingService instance
  final NotificationAlertingService _alertingService = NotificationAlertingService();

  /// Get PermissionService instance
  final PermissionService _permissionService = PermissionService();

  /// Get NotificationValidationService instance
  final NotificationValidationService _validationService = NotificationValidationService();

  /// Get RateLimitingService instance
  final RateLimitingService _rateLimitingService = RateLimitingService();

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
      // Permission check: Only developers and authorities can create notifications
      if (createdBy != null) {
        final canCreate = await _permissionService.canCreateNotification(createdBy);
        if (!canCreate) {
          session.log(
            '❌ Permission denied: User $createdBy cannot create notifications',
            level: LogLevel.warning,
          );
          return {
            'success': false,
            'error': 'Permission denied. Only developers and authorities can create notifications.',
          };
        }

        // Rate limiting check
        final rateLimitError = await _rateLimitingService.checkNotificationRateLimit(
          createdBy,
          isBroadcast: false,
        );

        if (rateLimitError != null) {
          session.log(
            '❌ Rate limit exceeded for user: $createdBy',
            level: LogLevel.warning,
          );
          
          // Log the violation
          await _rateLimitingService.logRateLimitViolation(
            createdBy,
            'notification_creation',
          );

          return {
            'success': false,
            'error': rateLimitError,
          };
        }
      }

      // Input validation
      final validationErrors = _validationService.validateNotification(
        title: title,
        message: message,
        type: type,
        targetType: 'single',
        targetUserIds: [userId],
        data: data,
      );

      if (validationErrors.isNotEmpty) {
        session.log(
          '❌ Validation failed: ${validationErrors.join(", ")}',
          level: LogLevel.warning,
        );
        return {
          'success': false,
          'error': 'Validation failed',
          'validation_errors': validationErrors,
        };
      }

      // Sanitize input
      final sanitized = _validationService.sanitizeNotificationData(
        title: title,
        message: message,
        data: data,
      );

      final oneSignal = _getOneSignalService(session);

      // 1. Create notification record in Supabase with sanitized data
      final notificationData = {
        'title': sanitized['title'],
        'message': sanitized['message'],
        'type': type,
        'related_action': relatedAction,
        'data': sanitized['data'],
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
      // Permission check: Only developers and authorities can create notifications
      if (createdBy != null) {
        final canCreate = await _permissionService.canCreateNotification(createdBy);
        if (!canCreate) {
          session.log(
            '❌ Permission denied: User $createdBy cannot create notifications',
            level: LogLevel.warning,
          );
          return {
            'success': false,
            'error': 'Permission denied. Only developers and authorities can create notifications.',
          };
        }

        // Rate limiting check
        final rateLimitError = await _rateLimitingService.checkNotificationRateLimit(
          createdBy,
          isBroadcast: false,
        );

        if (rateLimitError != null) {
          session.log(
            '❌ Rate limit exceeded for user: $createdBy',
            level: LogLevel.warning,
          );
          
          // Log the violation
          await _rateLimitingService.logRateLimitViolation(
            createdBy,
            'notification_creation',
          );

          return {
            'success': false,
            'error': rateLimitError,
          };
        }
      }

      // Input validation
      final validationErrors = _validationService.validateNotification(
        title: title,
        message: message,
        type: type,
        targetType: 'custom',
        targetUserIds: userIds,
        data: data,
      );

      if (validationErrors.isNotEmpty) {
        session.log(
          '❌ Validation failed: ${validationErrors.join(", ")}',
          level: LogLevel.warning,
        );
        return {
          'success': false,
          'error': 'Validation failed',
          'validation_errors': validationErrors,
        };
      }

      // Sanitize input
      final sanitized = _validationService.sanitizeNotificationData(
        title: title,
        message: message,
        data: data,
      );

      final oneSignal = _getOneSignalService(session);

      // 1. Create single notification record with target_user_ids array
      final notificationData = {
        'title': sanitized['title'],
        'message': sanitized['message'],
        'type': type,
        'related_action': relatedAction,
        'data': sanitized['data'],
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
  /// Requires admin or developer role
  Future<Map<String, dynamic>> sendToAll(
    Session session, {
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? data,
    String? createdBy,
  }) async {
    try {
      // Permission check: Only admins and developers can broadcast to all users
      if (createdBy != null) {
        final hasPermission = await _permissionService.hasElevatedPermissions(createdBy);
        if (!hasPermission) {
          session.log(
            '❌ Permission denied: User $createdBy cannot broadcast to all users',
            level: LogLevel.warning,
          );
          return {
            'success': false,
            'error': 'Permission denied. Only admins and developers can broadcast to all users.',
          };
        }

        // Rate limiting check (stricter for broadcasts)
        final rateLimitError = await _rateLimitingService.checkNotificationRateLimit(
          createdBy,
          isBroadcast: true,
        );

        if (rateLimitError != null) {
          session.log(
            '❌ Rate limit exceeded for broadcast by user: $createdBy',
            level: LogLevel.warning,
          );
          
          // Log the violation
          await _rateLimitingService.logRateLimitViolation(
            createdBy,
            'broadcast_notification',
          );

          return {
            'success': false,
            'error': rateLimitError,
          };
        }
      }

      // Input validation
      final validationErrors = _validationService.validateNotification(
        title: title,
        message: message,
        type: type,
        targetType: 'all',
        data: data,
      );

      if (validationErrors.isNotEmpty) {
        session.log(
          '❌ Validation failed: ${validationErrors.join(", ")}',
          level: LogLevel.warning,
        );
        return {
          'success': false,
          'error': 'Validation failed',
          'validation_errors': validationErrors,
        };
      }

      // Sanitize input
      final sanitized = _validationService.sanitizeNotificationData(
        title: title,
        message: message,
        data: data,
      );

      final oneSignal = _getOneSignalService(session);

      // Send push notification via OneSignal
      final result = await oneSignal.sendToAll(
        title: sanitized['title'] as String,
        message: sanitized['message'] as String,
        data: {
          'type': type,
          ...?sanitized['data'] as Map<String, dynamic>?,
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

  /// Schedule an existing notification by ID
  ///
  /// This is called from Flutter client after notification is created
  /// Schedules the notification via QStash for processing and stores job ID for cancellation
  Future<Map<String, dynamic>> scheduleNotificationById(
    Session session, {
    required String notificationId,
    required DateTime scheduledAt,
  }) async {
    try {
      // 1. Verify notification exists and has 'scheduled' status
      final notifications = await _supabase.select(
        'notifications',
        filters: {'id': notificationId},
      );

      if (notifications.isEmpty) {
        throw Exception('Notification not found: $notificationId');
      }

      final notification = notifications.first;
      final status = notification['status'] as String;

      if (status != 'scheduled') {
        throw Exception(
          'Notification must have status "scheduled" to be scheduled (current: $status)',
        );
      }

      // 2. Build callback URL
      final publicHost = Platform.environment['PUBLIC_HOST'] ??
          session.serverpod.getPassword('publicHost') ??
          'localhost:8080';
      final apiPort = Platform.environment['API_PORT'] ?? '443';
      final useHttps = apiPort == '443' || apiPort == '8443';
      final protocol = useHttps ? 'https' : 'http';

      // QStash webhook endpoint
      final callbackUrl =
          '$protocol://$publicHost/qstashWebhook/processScheduledNotification';

      session.log(
        '📤 Scheduling notification via QStash: $notificationId',
        level: LogLevel.info,
      );
      session.log(
        '   Callback URL: $callbackUrl',
        level: LogLevel.info,
      );
      session.log(
        '   Scheduled for: ${scheduledAt.toIso8601String()}',
        level: LogLevel.info,
      );

      // 3. Schedule via QStash
      final qstashResult = await ScheduledNotificationTask.scheduleNotification(
        notificationId: notificationId,
        scheduledAt: scheduledAt,
        callbackUrl: callbackUrl,
      );

      final qstashMessageId = qstashResult['messageId'] as String?;

      // 4. Store QStash job ID in notification data for cancellation
      final currentData = notification['data'] as Map<String, dynamic>? ?? {};
      final updatedData = {
        ...currentData,
        'qstash_message_id': qstashMessageId,
      };

      await _supabase.update(
        'notifications',
        {
          'data': updatedData,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': notificationId},
      );

      session.log(
        '✓ Notification scheduled for ${scheduledAt.toIso8601String()} (QStash ID: $qstashMessageId)',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'notification_id': notificationId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'qstash_message_id': qstashMessageId,
      };
    } catch (e, stackTrace) {
      // 5. Handle scheduling errors
      session.log('❌ Error scheduling notification: $e', level: LogLevel.error);
      session.log(stackTrace.toString(), level: LogLevel.error);

      // Update notification status to failed
      try {
        await _supabase.update(
          'notifications',
          {
            'status': 'failed',
            'error_message': 'Failed to schedule: ${e.toString()}',
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'id': notificationId},
        );
      } catch (updateError) {
        session.log(
          '❌ Failed to update notification status: $updateError',
          level: LogLevel.error,
        );
      }

      // Alert on QStash scheduling failure
      await _alertingService.alertQStashError(
        notificationId: notificationId,
        errorMessage: e.toString(),
        scheduledAt: scheduledAt,
      );

      return {
        'success': false,
        'error': e.toString(),
        'notification_id': notificationId,
      };
    }
  }

  /// Schedule a notification to be sent at a specific time
  ///
  /// Creates notification record in Supabase with 'scheduled' status
  /// and schedules via QStash for processing
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
      // Permission check: Only developers and authorities can create notifications
      if (createdBy != null) {
        final canCreate = await _permissionService.canCreateNotification(createdBy);
        if (!canCreate) {
          session.log(
            '❌ Permission denied: User $createdBy cannot create notifications',
            level: LogLevel.warning,
          );
          return {
            'success': false,
            'error': 'Permission denied. Only developers and authorities can create notifications.',
          };
        }

        // Rate limiting check
        final rateLimitError = await _rateLimitingService.checkNotificationRateLimit(
          createdBy,
          isBroadcast: targetType == 'all',
        );

        if (rateLimitError != null) {
          session.log(
            '❌ Rate limit exceeded for user: $createdBy',
            level: LogLevel.warning,
          );
          
          // Log the violation
          await _rateLimitingService.logRateLimitViolation(
            createdBy,
            'scheduled_notification',
          );

          return {
            'success': false,
            'error': rateLimitError,
          };
        }
      }

      // Input validation
      final validationErrors = _validationService.validateNotification(
        title: title,
        message: message,
        type: type,
        status: 'scheduled',
        scheduledAt: scheduledAt,
        targetType: targetType,
        targetUserIds: targetUserIds,
        targetRoles: targetRoles,
        data: data,
      );

      if (validationErrors.isNotEmpty) {
        session.log(
          '❌ Validation failed: ${validationErrors.join(", ")}',
          level: LogLevel.warning,
        );
        return {
          'success': false,
          'error': 'Validation failed',
          'validation_errors': validationErrors,
        };
      }

      // Sanitize input
      final sanitized = _validationService.sanitizeNotificationData(
        title: title,
        message: message,
        data: data,
      );

      // 1. Create notification record in Supabase with 'scheduled' status
      final notificationData = {
        'title': sanitized['title'],
        'message': sanitized['message'],
        'type': type,
        'related_action': relatedAction,
        'data': sanitized['data'],
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
      final notificationId = notification['id'] as String;

      // 2. Schedule via QStash
      // 构建回调 URL（使用 PUBLIC_HOST）
      final publicHost = Platform.environment['PUBLIC_HOST'] ??
          session.serverpod.getPassword('publicHost') ??
          'localhost:8080';
      final apiPort = Platform.environment['API_PORT'] ?? '443';
      final useHttps = apiPort == '443' || apiPort == '8443';
      final protocol = useHttps ? 'https' : 'http';

      // QStash webhook endpoint
      final callbackUrl =
          '$protocol://$publicHost/qstashWebhook/processScheduledNotification';

      session.log(
        '📤 Scheduling notification via QStash: $notificationId',
        level: LogLevel.info,
      );
      session.log(
        '   Callback URL: $callbackUrl',
        level: LogLevel.info,
      );

      final qstashResult = await ScheduledNotificationTask.scheduleNotification(
        notificationId: notificationId,
        scheduledAt: scheduledAt,
        callbackUrl: callbackUrl,
      );

      session.log(
        '✓ Notification scheduled for ${scheduledAt.toIso8601String()}',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'notification': notification,
        'scheduled_at': scheduledAt.toIso8601String(),
        'qstash_message_id': qstashResult['messageId'],
      };
    } catch (e, stackTrace) {
      session.log('❌ Error scheduling notification: $e', level: LogLevel.error);
      session.log(stackTrace.toString(), level: LogLevel.error);

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
      // Permission check: Only developers and authorities can create notifications
      if (createdBy != null) {
        final canCreate = await _permissionService.canCreateNotification(createdBy);
        if (!canCreate) {
          session.log(
            '❌ Permission denied: User $createdBy cannot create notifications',
            level: LogLevel.warning,
          );
          return {
            'success': false,
            'error': 'Permission denied. Only developers and authorities can create notifications.',
          };
        }
      }

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
    required String userId,
  }) async {
    try {
      // Permission check: Only the creator can cancel their scheduled notification
      final canDelete = await _permissionService.canDeleteNotification(userId, notificationId);
      if (!canDelete) {
        session.log(
          '❌ Permission denied: User $userId cannot cancel notification $notificationId',
          level: LogLevel.warning,
        );
        return {
          'success': false,
          'error': 'Permission denied. Only the creator can cancel their scheduled notifications.',
        };
      }

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
  /// It sends the push notification based on target_type with enhanced OneSignal fields
  Future<Map<String, dynamic>> handleNotificationCreated(
    Session session, {
    required String notificationId,
  }) async {
    try {
      // 1. Get notification from Supabase with new OneSignal fields
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
      
      // Extract new OneSignal fields
      final sound = notification['sound'] as String?;
      final category = notification['category'] as String?;
      final priority = notification['priority'] as int? ?? 5;

      Map<String, dynamic>? oneSignalResult;

      // 3. Resolve target users and send based on target_type
      try {
        switch (targetType) {
          case 'single':
            // Send to single user (get from target_user_ids array)
            final targetUserIds = notification['target_user_ids'] as List?;
            if (targetUserIds != null && targetUserIds.isNotEmpty) {
              final userId = targetUserIds.first as String;
              oneSignalResult = await oneSignal.sendToUser(
                userId: userId,
                title: title,
                message: message,
                data: {
                  'notification_id': notificationId,
                  'type': type,
                  ...?data,
                },
                sound: sound,
                category: category,
                priority: priority,
              );
            }
            break;

          case 'all':
            // Send to all users
            oneSignalResult = await oneSignal.sendToAll(
              title: title,
              message: message,
              data: {
                'notification_id': notificationId,
                'type': type,
                ...?data,
              },
              sound: sound,
              category: category,
              priority: priority,
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

                oneSignalResult = await oneSignal.sendToUsers(
                  userIds: userIds,
                  title: title,
                  message: message,
                  data: {
                    'notification_id': notificationId,
                    'type': type,
                    ...?data,
                  },
                  sound: sound,
                  category: category,
                  priority: priority,
                );
              }
            }
            break;

          case 'custom':
            // Send to custom list of users
            final targetUserIds = notification['target_user_ids'] as List?;
            if (targetUserIds != null && targetUserIds.isNotEmpty) {
              final userIds = targetUserIds.cast<String>();
              oneSignalResult = await oneSignal.sendToUsers(
                userIds: userIds,
                title: title,
                message: message,
                data: {
                  'notification_id': notificationId,
                  'type': type,
                  ...?data,
                },
                sound: sound,
                category: category,
                priority: priority,
              );
            }
            break;
        }

        // 4. Store OneSignal notification ID and delivery statistics in database
        if (oneSignalResult != null) {
          final oneSignalNotificationId = oneSignalResult['id'] as String?;
          final recipients = oneSignalResult['recipients'] as int? ?? 0;
          
          await _supabase.update(
            'notifications',
            {
              'onesignal_notification_id': oneSignalNotificationId,
              'recipients_count': recipients,
              'updated_at': DateTime.now().toIso8601String(),
            },
            filters: {'id': notificationId},
          );

          session.log(
            '✓ Push notification sent for: $notificationId (OneSignal ID: $oneSignalNotificationId, Recipients: $recipients)',
            level: LogLevel.info,
          );

          // 5. Track delivery metrics
          await _metricsService.trackDeliveryMetrics(
            notificationId: notificationId,
            totalSent: recipients,
            successfulDeliveries: recipients, // Will be updated later with actual delivery stats
            failedDeliveries: 0,
            firstDeliveryAt: DateTime.now(),
          );

          // 6. Fetch actual delivery stats from OneSignal after a short delay
          // This allows OneSignal to process the notification
          Future.delayed(Duration(seconds: 5), () async {
            try {
              final stats = await oneSignal.getDeliveryStats(oneSignalNotificationId!);
              
              // Update notification with actual delivery stats
              await _supabase.update(
                'notifications',
                {
                  'successful_deliveries': stats['successful_deliveries'],
                  'failed_deliveries': stats['failed_deliveries'],
                  'updated_at': DateTime.now().toIso8601String(),
                },
                filters: {'id': notificationId},
              );

              // Update metrics with actual delivery stats
              await _metricsService.trackDeliveryMetrics(
                notificationId: notificationId,
                totalSent: stats['recipients_count'] as int,
                successfulDeliveries: stats['successful_deliveries'] as int,
                failedDeliveries: stats['failed_deliveries'] as int,
                firstDeliveryAt: DateTime.now(),
              );

              session.log(
                '✓ Updated delivery stats from OneSignal: $notificationId',
                level: LogLevel.info,
              );
            } catch (e) {
              session.log(
                '⚠️ Failed to fetch delivery stats from OneSignal: $e',
                level: LogLevel.warning,
              );
            }
          });
        }

        return {
          'success': true,
          'notification_id': notificationId,
          'target_type': targetType,
          'onesignal_notification_id': oneSignalResult?['id'],
          'recipients_count': oneSignalResult?['recipients'],
        };
      } catch (e) {
        // 5. Update status to 'failed' on error
        session.log('❌ Error sending notification: $e', level: LogLevel.error);
        
        await _supabase.update(
          'notifications',
          {
            'status': 'failed',
            'error_message': e.toString(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'id': notificationId},
        );

        // Alert on OneSignal error
        await _alertingService.alertOneSignalError(
          notificationId: notificationId,
          errorMessage: e.toString(),
        );

        return {
          'success': false,
          'error': e.toString(),
          'notification_id': notificationId,
        };
      }
    } catch (e) {
      session.log('❌ Error handling notification: $e', level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Handle scheduled notification webhook from QStash
  ///
  /// This is called by QStash when a scheduled notification is due
  /// Processes the notification by updating status and sending via OneSignal
  Future<Map<String, dynamic>> handleScheduledNotification(
    Session session, {
    required String notificationId,
  }) async {
    try {
      session.log(
        '🔔 Processing scheduled notification webhook: $notificationId',
        level: LogLevel.info,
      );

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

      // Check if already sent
      if (status == 'sent') {
        session.log(
          '⚠️ Notification already sent: $notificationId',
          level: LogLevel.warning,
        );
        return {
          'success': true,
          'message': 'Already sent',
          'notification_id': notificationId,
        };
      }

      // 2. Update notification status from 'scheduled' to 'sent'
      final now = DateTime.now();
      await _supabase.update(
        'notifications',
        {
          'status': 'sent',
          'sent_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        filters: {'id': notificationId},
      );

      // 3. Trigger database function to create user_notifications
      // This is handled automatically by the database trigger when status changes to 'sent'
      session.log(
        '✓ Updated notification status to sent, database trigger will create user_notifications',
        level: LogLevel.info,
      );

      // 4. Send push notification via OneSignal
      final oneSignal = _getOneSignalService(session);
      final targetType = notification['target_type'] as String? ?? 'single';
      final title = notification['title'] as String;
      final message = notification['message'] as String;
      final type = notification['type'] as String;
      final data = notification['data'] as Map<String, dynamic>?;
      final sound = notification['sound'] as String?;
      final category = notification['category'] as String?;
      final priority = notification['priority'] as int? ?? 5;

      Map<String, dynamic>? oneSignalResult;

      try {
        switch (targetType) {
          case 'single':
            final targetUserIds = notification['target_user_ids'] as List?;
            if (targetUserIds != null && targetUserIds.isNotEmpty) {
              final userId = targetUserIds.first as String;
              oneSignalResult = await oneSignal.sendToUser(
                userId: userId,
                title: title,
                message: message,
                data: {
                  'notification_id': notificationId,
                  'type': type,
                  ...?data,
                },
                sound: sound,
                category: category,
                priority: priority,
              );
            }
            break;

          case 'custom':
            final targetUserIds = notification['target_user_ids'] as List?;
            if (targetUserIds != null && targetUserIds.isNotEmpty) {
              final userIds = targetUserIds.cast<String>();
              oneSignalResult = await oneSignal.sendToUsers(
                userIds: userIds,
                title: title,
                message: message,
                data: {
                  'notification_id': notificationId,
                  'type': type,
                  ...?data,
                },
                sound: sound,
                category: category,
                priority: priority,
              );
            }
            break;

          case 'role':
            final targetRoles = notification['target_roles'] as List?;
            if (targetRoles != null && targetRoles.isNotEmpty) {
              final users = await _supabase.select('profiles');
              final filteredUsers = users.where((user) {
                final role = user['role'] as String?;
                return role != null && targetRoles.contains(role);
              }).toList();

              final userIds =
                  filteredUsers.map((user) => user['id'] as String).toList();

              if (userIds.isNotEmpty) {
                // Update target_user_ids for RLS policy
                await _supabase.update(
                  'notifications',
                  {'target_user_ids': userIds},
                  filters: {'id': notificationId},
                );

                oneSignalResult = await oneSignal.sendToUsers(
                  userIds: userIds,
                  title: title,
                  message: message,
                  data: {
                    'notification_id': notificationId,
                    'type': type,
                    ...?data,
                  },
                  sound: sound,
                  category: category,
                  priority: priority,
                );
              }
            }
            break;

          case 'all':
            oneSignalResult = await oneSignal.sendToAll(
              title: title,
              message: message,
              data: {
                'notification_id': notificationId,
                'type': type,
                ...?data,
              },
              sound: sound,
              category: category,
              priority: priority,
            );
            break;
        }

        // Store OneSignal notification ID and delivery statistics
        if (oneSignalResult != null) {
          final oneSignalNotificationId = oneSignalResult['id'] as String?;
          final recipients = oneSignalResult['recipients'] as int? ?? 0;

          await _supabase.update(
            'notifications',
            {
              'onesignal_notification_id': oneSignalNotificationId,
              'recipients_count': recipients,
              'updated_at': DateTime.now().toIso8601String(),
            },
            filters: {'id': notificationId},
          );

          session.log(
            '✓ Scheduled notification sent: $notificationId (OneSignal ID: $oneSignalNotificationId)',
            level: LogLevel.info,
          );

          // Track delivery metrics
          await _metricsService.trackDeliveryMetrics(
            notificationId: notificationId,
            totalSent: recipients,
            successfulDeliveries: recipients,
            failedDeliveries: 0,
            firstDeliveryAt: DateTime.now(),
          );

          // Fetch actual delivery stats from OneSignal after a short delay
          Future.delayed(Duration(seconds: 5), () async {
            try {
              final stats = await oneSignal.getDeliveryStats(oneSignalNotificationId!);
              
              // Update notification with actual delivery stats
              await _supabase.update(
                'notifications',
                {
                  'successful_deliveries': stats['successful_deliveries'],
                  'failed_deliveries': stats['failed_deliveries'],
                  'updated_at': DateTime.now().toIso8601String(),
                },
                filters: {'id': notificationId},
              );

              // Update metrics with actual delivery stats
              await _metricsService.trackDeliveryMetrics(
                notificationId: notificationId,
                totalSent: stats['recipients_count'] as int,
                successfulDeliveries: stats['successful_deliveries'] as int,
                failedDeliveries: stats['failed_deliveries'] as int,
                firstDeliveryAt: DateTime.now(),
              );

              session.log(
                '✓ Updated delivery stats from OneSignal for scheduled notification: $notificationId',
                level: LogLevel.info,
              );
            } catch (e) {
              session.log(
                '⚠️ Failed to fetch delivery stats from OneSignal: $e',
                level: LogLevel.warning,
              );
            }
          });
        }

        return {
          'success': true,
          'notification_id': notificationId,
          'onesignal_notification_id': oneSignalResult?['id'],
          'recipients_count': oneSignalResult?['recipients'],
        };
      } catch (e) {
        // Mark as failed if OneSignal send fails
        session.log(
          '❌ Error sending scheduled notification: $e',
          level: LogLevel.error,
        );

        await _supabase.update(
          'notifications',
          {
            'status': 'failed',
            'error_message': e.toString(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'id': notificationId},
        );

        return {
          'success': false,
          'error': e.toString(),
          'notification_id': notificationId,
        };
      }
    } catch (e, stackTrace) {
      session.log(
        '❌ Error processing scheduled notification: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Update notification status with OneSignal ID and delivery statistics
  ///
  /// This endpoint allows updating notification status, OneSignal notification ID,
  /// error messages, and delivery statistics
  /// This is typically called by system processes, not directly by users
  Future<Map<String, dynamic>> updateNotificationStatus(
    Session session, {
    required String notificationId,
    String? status,
    String? oneSignalNotificationId,
    String? errorMessage,
    int? recipientsCount,
    int? successfulDeliveries,
    int? failedDeliveries,
    String? userId,
  }) async {
    try {
      session.log(
        '📝 Updating notification status: $notificationId',
        level: LogLevel.info,
      );

      // Permission check: Only system or elevated users can update notification status
      // If userId is provided, check permissions
      if (userId != null) {
        final hasPermission = await _permissionService.hasElevatedPermissions(userId);
        if (!hasPermission) {
          session.log(
            '❌ Permission denied: User $userId cannot update notification status',
            level: LogLevel.warning,
          );
          return {
            'success': false,
            'error': 'Permission denied. Only admins and developers can update notification status.',
          };
        }
      }

      // 1. Verify notification exists
      final notifications = await _supabase.select(
        'notifications',
        filters: {'id': notificationId},
      );

      if (notifications.isEmpty) {
        throw Exception('Notification not found: $notificationId');
      }

      // 2. Build update data
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status != null) {
        // Validate status
        const validStatuses = ['draft', 'scheduled', 'sent', 'failed'];
        if (!validStatuses.contains(status)) {
          throw Exception(
            'Invalid status: $status. Must be one of: ${validStatuses.join(", ")}',
          );
        }
        updateData['status'] = status;

        // Set sent_at timestamp if status is 'sent'
        if (status == 'sent') {
          updateData['sent_at'] = DateTime.now().toIso8601String();
        }
      }

      if (oneSignalNotificationId != null) {
        updateData['onesignal_notification_id'] = oneSignalNotificationId;
      }

      if (errorMessage != null) {
        updateData['error_message'] = errorMessage;
      }

      if (recipientsCount != null) {
        updateData['recipients_count'] = recipientsCount;
      }

      if (successfulDeliveries != null) {
        updateData['successful_deliveries'] = successfulDeliveries;
      }

      if (failedDeliveries != null) {
        updateData['failed_deliveries'] = failedDeliveries;
      }

      // 3. Update notification record
      final updatedNotifications = await _supabase.update(
        'notifications',
        updateData,
        filters: {'id': notificationId},
      );

      if (updatedNotifications.isEmpty) {
        throw Exception('Failed to update notification: $notificationId');
      }

      final updatedNotification = updatedNotifications.first;

      session.log(
        '✓ Notification status updated: $notificationId',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'notification': updatedNotification,
      };
    } catch (e, stackTrace) {
      session.log(
        '❌ Error updating notification status: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get notification status and delivery statistics
  ///
  /// Retrieves current notification status from database and optionally
  /// fetches latest delivery statistics from OneSignal
  Future<Map<String, dynamic>> getNotificationStatus(
    Session session, {
    required String notificationId,
    bool fetchFromOneSignal = false,
  }) async {
    try {
      session.log(
        '📊 Getting notification status: $notificationId',
        level: LogLevel.info,
      );

      // 1. Get notification from database
      final notifications = await _supabase.select(
        'notifications',
        filters: {'id': notificationId},
      );

      if (notifications.isEmpty) {
        throw Exception('Notification not found: $notificationId');
      }

      final notification = notifications.first;
      final oneSignalNotificationId =
          notification['onesignal_notification_id'] as String?;

      // 2. Optionally fetch latest stats from OneSignal
      Map<String, dynamic>? oneSignalStats;
      if (fetchFromOneSignal && oneSignalNotificationId != null) {
        try {
          final oneSignal = _getOneSignalService(session);
          oneSignalStats =
              await oneSignal.getDeliveryStats(oneSignalNotificationId);

          // Update database with latest stats
          await _supabase.update(
            'notifications',
            {
              'recipients_count': oneSignalStats['recipients_count'],
              'successful_deliveries': oneSignalStats['successful_deliveries'],
              'failed_deliveries': oneSignalStats['failed_deliveries'],
              'updated_at': DateTime.now().toIso8601String(),
            },
            filters: {'id': notificationId},
          );
        } catch (e) {
          session.log(
            '⚠️ Failed to fetch OneSignal stats: $e',
            level: LogLevel.warning,
          );
          // Continue with database values
        }
      }

      return {
        'success': true,
        'notification_id': notificationId,
        'status': notification['status'],
        'onesignal_notification_id': oneSignalNotificationId,
        'error_message': notification['error_message'],
        'recipients_count': notification['recipients_count'],
        'successful_deliveries': notification['successful_deliveries'],
        'failed_deliveries': notification['failed_deliveries'],
        'sent_at': notification['sent_at'],
        'scheduled_at': notification['scheduled_at'],
        'created_at': notification['created_at'],
        'updated_at': notification['updated_at'],
        if (oneSignalStats != null) 'onesignal_stats': oneSignalStats,
      };
    } catch (e, stackTrace) {
      session.log(
        '❌ Error getting notification status: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🧪 手动触发 scheduled notification 处理（仅用于开发测试）
  ///
  /// 这个方法模拟 QStash webhook 的行为，用于本地测试
  /// 可以手动触发任何 scheduled notification 的处理
  Future<Map<String, dynamic>> testProcessScheduledNotification(
    Session session, {
    required String notificationId,
  }) async {
    try {
      session.log(
          '🧪 [TEST] Manually processing scheduled notification: $notificationId');

      // 调用相同的处理逻辑
      final result = await handleScheduledNotification(
        session,
        notificationId: notificationId,
      );

      session.log('✓ [TEST] Processing completed', level: LogLevel.info);
      return result;
    } catch (e, stackTrace) {
      session.log('❌ [TEST] Error: $e', level: LogLevel.error);
      session.log(stackTrace.toString(), level: LogLevel.error);
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

  /// Cancel a QStash scheduled job
  ///
  /// This is called from Flutter client when updating a scheduled notification
  /// to cancel the previous QStash job before creating a new one
  Future<Map<String, dynamic>> cancelQStashJob(
    Session session, {
    required String qstashMessageId,
  }) async {
    try {
      session.log(
        '🗑️ Cancelling QStash job: $qstashMessageId',
        level: LogLevel.info,
      );

      final success = await ScheduledNotificationTask.cancelScheduledNotification(
        qstashMessageId,
      );

      if (success) {
        session.log(
          '✓ QStash job cancelled: $qstashMessageId',
          level: LogLevel.info,
        );
        return {
          'success': true,
          'qstash_message_id': qstashMessageId,
        };
      } else {
        throw Exception('Failed to cancel QStash job');
      }
    } catch (e, stackTrace) {
      session.log(
        '❌ Error cancelling QStash job: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Hard delete a notification (permanent deletion with cascade)
  ///
  /// This permanently deletes the notification and all associated user_notification records.
  /// Requires admin permission check.
  /// Use with extreme caution - this action cannot be undone.
  Future<Map<String, dynamic>> hardDeleteNotification(
    Session session, {
    required String notificationId,
    required String userId,
  }) async {
    try {
      session.log(
        '🗑️ Hard delete request for notification: $notificationId by user: $userId',
        level: LogLevel.info,
      );

      // 1. Check user permissions (must be admin or developer)
      final hasPermission = await _permissionService.canHardDeleteNotification(userId);

      if (!hasPermission) {
        session.log(
          '❌ Permission denied for user: $userId',
          level: LogLevel.warning,
        );
        throw Exception(
          'Permission denied. Only admin or developer can hard delete notifications.',
        );
      }

      // 2. Get notification to check if it has a QStash job
      final notifications = await _supabase.select(
        'notifications',
        filters: {'id': notificationId},
      );

      if (notifications.isEmpty) {
        throw Exception('Notification not found: $notificationId');
      }

      final notification = notifications.first;
      final status = notification['status'] as String;
      final data = notification['data'] as Map<String, dynamic>?;
      final qstashMessageId = data?['qstash_message_id'] as String?;

      // 3. If scheduled, cancel the QStash job first
      if (status == 'scheduled' && qstashMessageId != null) {
        try {
          await ScheduledNotificationTask.cancelScheduledNotification(
            qstashMessageId,
          );
          session.log(
            '✓ Cancelled QStash job before deletion: $qstashMessageId',
            level: LogLevel.info,
          );
        } catch (e) {
          session.log(
            '⚠️ Failed to cancel QStash job: $e',
            level: LogLevel.warning,
          );
          // Continue with deletion even if cancellation fails
        }
      }

      // 4. Delete all user_notification records (cascade delete)
      await _supabase.delete(
        'user_notifications',
        filters: {'notification_id': notificationId},
      );

      session.log(
        '✓ Deleted user_notification records for: $notificationId',
        level: LogLevel.info,
      );

      // 5. Delete the notification record
      await _supabase.delete(
        'notifications',
        filters: {'id': notificationId},
      );

      session.log(
        '✓ Hard deleted notification: $notificationId',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'notification_id': notificationId,
        'message': 'Notification permanently deleted',
      };
    } catch (e, stackTrace) {
      session.log(
        '❌ Error hard deleting notification: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check notification system health
  ///
  /// Performs comprehensive health check and returns status
  /// Also triggers alerts if issues are detected
  Future<Map<String, dynamic>> checkSystemHealth(Session session) async {
    try {
      session.log(
        '🏥 Performing system health check',
        level: LogLevel.info,
      );

      final healthStatus = await _alertingService.checkSystemHealth();

      return {
        'success': true,
        'health': healthStatus,
      };
    } catch (e, stackTrace) {
      session.log(
        '❌ Error checking system health: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get recent alerts for dashboard
  ///
  /// Returns list of recent alert notifications
  Future<Map<String, dynamic>> getRecentAlerts(
    Session session, {
    int limit = 50,
  }) async {
    try {
      session.log(
        '📊 Fetching recent alerts',
        level: LogLevel.info,
      );

      final alerts = await _alertingService.getRecentAlerts(limit: limit);

      return {
        'success': true,
        'alerts': alerts,
        'count': alerts.length,
      };
    } catch (e, stackTrace) {
      session.log(
        '❌ Error fetching recent alerts: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get API usage statistics for a user
  ///
  /// Returns rate limit information and usage statistics
  Future<Map<String, dynamic>> getApiUsageStats(
    Session session, {
    required String userId,
  }) async {
    try {
      session.log(
        '📊 Fetching API usage stats for user: $userId',
        level: LogLevel.info,
      );

      final stats = await _rateLimitingService.getUsageStats(userId);

      return {
        'success': true,
        'usage_stats': stats,
      };
    } catch (e, stackTrace) {
      session.log(
        '❌ Error fetching API usage stats: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get notification metrics summary for dashboard
  ///
  /// Returns aggregated metrics including success rates, delivery times,
  /// and user engagement metrics for the specified time period
  Future<Map<String, dynamic>> getMetricsSummary(
    Session session, {
    int daysBack = 30,
  }) async {
    try {
      session.log(
        '📊 Fetching metrics summary for last $daysBack days',
        level: LogLevel.info,
      );

      final summary = await _metricsService.getMetricsSummary(
        daysBack: daysBack,
      );

      return {
        'success': true,
        'metrics': summary,
      };
    } catch (e, stackTrace) {
      session.log(
        '❌ Error fetching metrics summary: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get metrics for a specific notification
  ///
  /// Returns detailed metrics including delivery stats and engagement metrics
  Future<Map<String, dynamic>> getNotificationMetrics(
    Session session, {
    required String notificationId,
  }) async {
    try {
      session.log(
        '📊 Fetching metrics for notification: $notificationId',
        level: LogLevel.info,
      );

      final metrics = await _metricsService.getMetrics(notificationId);

      if (metrics == null) {
        return {
          'success': false,
          'error': 'Metrics not found for notification: $notificationId',
        };
      }

      return {
        'success': true,
        'metrics': metrics,
      };
    } catch (e, stackTrace) {
      session.log(
        '❌ Error fetching notification metrics: $e',
        level: LogLevel.error,
      );
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send system maintenance notification to all users
  ///
  /// Creates a notification for system maintenance events
  /// Sends to all users with target_type='all'
  /// Requires admin permission
  Future<Map<String, dynamic>> sendMaintenanceNotification(
    Session session, {
    required String title,
    required String message,
    DateTime? scheduledAt,
    String? createdBy,
  }) async {
    try {
      // Permission check: Only admins can send maintenance notifications
      if (createdBy != null) {
        final isAdmin = await _permissionService.isAdmin(createdBy);
        if (!isAdmin) {
          session.log(
            '❌ Permission denied: User $createdBy cannot send maintenance notifications',
            level: LogLevel.warning,
          );
          return {
            'success': false,
            'error': 'Permission denied. Only admins can send maintenance notifications.',
          };
        }
      }

      final oneSignal = _getOneSignalService(session);

      // Create notification record in Supabase
      final notificationData = {
        'title': title,
        'message': message,
        'type': 'system',
        'status': scheduledAt != null ? 'scheduled' : 'sent',
        'scheduled_at': scheduledAt?.toIso8601String(),
        'target_type': 'all',
        'sound': 'default',
        'category': 'info',
        'priority': 7,
        'created_by': createdBy,
        'data': {
          'notification_type': 'maintenance',
        },
      };

      final notifications =
          await _supabase.insert('notifications', [notificationData]);
      final notification = notifications.first;
      final notificationId = notification['id'] as String;

      // If scheduled, schedule via QStash
      if (scheduledAt != null) {
        final scheduleResult = await scheduleNotificationById(
          session,
          notificationId: notificationId,
          scheduledAt: scheduledAt,
        );

        return {
          'success': scheduleResult['success'],
          'notification': notification,
          'scheduled_at': scheduledAt.toIso8601String(),
          'qstash_message_id': scheduleResult['qstash_message_id'],
        };
      }

      // Otherwise, send immediately via OneSignal
      try {
        final oneSignalResult = await oneSignal.sendToAll(
          title: title,
          message: message,
          data: {
            'notification_id': notificationId,
            'type': 'system',
            'notification_type': 'maintenance',
          },
          sound: 'default',
          category: 'info',
          priority: 7,
        );

        // Store OneSignal notification ID
        final oneSignalNotificationId = oneSignalResult['id'] as String?;
        final recipients = oneSignalResult['recipients'] as int? ?? 0;

        await _supabase.update(
          'notifications',
          {
            'onesignal_notification_id': oneSignalNotificationId,
            'recipients_count': recipients,
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'id': notificationId},
        );

        session.log(
          '✓ Maintenance notification sent to all users (OneSignal ID: $oneSignalNotificationId, Recipients: $recipients)',
          level: LogLevel.info,
        );

        return {
          'success': true,
          'notification': notification,
          'onesignal_notification_id': oneSignalNotificationId,
          'recipients_count': recipients,
        };
      } catch (e) {
        session.log(
          '⚠️ Failed to send maintenance notification via OneSignal: $e',
          level: LogLevel.warning,
        );

        // Update status to failed
        await _supabase.update(
          'notifications',
          {
            'status': 'failed',
            'error_message': e.toString(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'id': notificationId},
        );

        return {
          'success': false,
          'error': e.toString(),
          'notification': notification,
        };
      }
    } catch (e) {
      session.log(
        '❌ Error sending maintenance notification: $e',
        level: LogLevel.error,
      );
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
