import 'package:logger/logger.dart';
import '../../core/api/notification/notification_api.dart';
import '../../core/api/notification/notification_backend_api.dart';
import '../../core/models/notification_model.dart';
import '../../core/supabase/supabase_client.dart';

/// Repository for notification data operations
///
/// Handles CRUD operations for notifications using NotificationApi
/// and backend operations via NotificationBackendApi
class NotificationRepository {
  final _api = NotificationApi();
  final _backendApi = NotificationBackendApi();
  final _logger = Logger();

  /// Get all notifications for a user
  ///
  /// [userId] - User ID to fetch notifications for
  /// [isRead] - Filter by read status (null = all)
  /// [limit] - Maximum number of notifications to fetch
  Future<List<NotificationModel>> getUserNotifications({
    required String userId,
    bool? isRead,
    int limit = 50,
  }) async {
    try {
      return await _api.getNotifications(
        userId: userId,
        isRead: isRead,
        limit: limit,
      );
    } catch (e) {
      _logger.e('Error fetching notifications', error: e);
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      return await _api.getUnreadCount(userId);
    } catch (e) {
      _logger.e('Error fetching unread count', error: e);
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.markAsRead(notificationId);
    } catch (e) {
      _logger.e('Error marking notification as read', error: e);
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      await _api.markAllAsRead(userId);
    } catch (e) {
      _logger.e('Error marking all as read', error: e);
      rethrow;
    }
  }

  /// Soft delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _api.deleteNotification(notificationId);
    } catch (e) {
      _logger.e('Error deleting notification', error: e);
      rethrow;
    }
  }

  /// Delete all notifications for a user (soft delete)
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _api.deleteAllNotifications(userId);
    } catch (e) {
      _logger.e('Error deleting all notifications', error: e);
      rethrow;
    }
  }

  /// Create a new notification
  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
    String? status,
    DateTime? scheduledAt,
    String? targetType,
    List<String>? targetRoles,
    List<String>? targetUserIds,
    String? createdBy,
  }) async {
    try {
      return await _api.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedAction: relatedAction,
        data: data,
        status: status,
        scheduledAt: scheduledAt,
        targetType: targetType,
        targetRoles: targetRoles,
        targetUserIds: targetUserIds,
        createdBy: createdBy,
      );
    } catch (e) {
      _logger.e('Error creating notification', error: e);
      rethrow;
    }
  }

  /// Update an existing notification
  Future<NotificationModel> updateNotification({
    required String notificationId,
    String? title,
    String? message,
    String? type,
    String? relatedAction,
    Map<String, dynamic>? data,
    String? status,
    DateTime? scheduledAt,
    String? targetType,
    List<String>? targetRoles,
    List<String>? targetUserIds,
  }) async {
    try {
      return await _api.updateNotification(
        notificationId: notificationId,
        title: title,
        message: message,
        type: type,
        relatedAction: relatedAction,
        data: data,
        status: status,
        scheduledAt: scheduledAt,
        targetType: targetType,
        targetRoles: targetRoles,
        targetUserIds: targetUserIds,
      );
    } catch (e) {
      _logger.e('Error updating notification', error: e);
      rethrow;
    }
  }

  /// Get scheduled notifications (for admin)
  Future<List<NotificationModel>> getScheduledNotifications() async {
    try {
      return await _api.getScheduledNotifications();
    } catch (e) {
      _logger.e('Error fetching scheduled notifications', error: e);
      rethrow;
    }
  }

  /// Get draft notifications (for admin)
  Future<List<NotificationModel>> getDraftNotifications(
    String createdBy,
  ) async {
    try {
      return await _api.getDraftNotifications(createdBy);
    } catch (e) {
      _logger.e('Error fetching draft notifications', error: e);
      rethrow;
    }
  }

  /// Subscribe to real-time notification updates
  Stream<List<NotificationModel>> subscribeToNotifications(String userId) {
    try {
      return supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .order('created_at')
          .map((data) {
            // Filter in memory since stream doesn't support eq
            final filtered = data.where((json) {
              return json['user_id'] == userId && json['is_deleted'] == false;
            }).toList();
            return filtered
                .map((json) => NotificationModel.fromJson(json))
                .toList();
          });
    } catch (e) {
      _logger.e('Error subscribing to notifications', error: e);
      rethrow;
    }
  }

  // ========== Backend API Methods ==========

  /// Send notification via backend (includes push notification)
  Future<Map<String, dynamic>> sendNotificationViaBackend({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _backendApi.sendToUser(
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedAction: relatedAction,
        data: data,
      );
    } catch (e) {
      _logger.e('Error sending notification via backend', error: e);
      rethrow;
    }
  }

  /// Send notification to multiple users via backend
  Future<Map<String, dynamic>> sendNotificationToUsersViaBackend({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _backendApi.sendToUsers(
        userIds: userIds,
        title: title,
        message: message,
        type: type,
        relatedAction: relatedAction,
        data: data,
      );
    } catch (e) {
      _logger.e('Error sending notifications via backend', error: e);
      rethrow;
    }
  }

  /// Send broadcast notification via backend
  Future<Map<String, dynamic>> sendBroadcastViaBackend({
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _backendApi.sendToAll(
        title: title,
        message: message,
        type: type,
        data: data,
      );
    } catch (e) {
      _logger.e('Error sending broadcast via backend', error: e);
      rethrow;
    }
  }

  /// Schedule notification via backend
  Future<Map<String, dynamic>> scheduleNotificationViaBackend({
    required String userId,
    required String title,
    required String message,
    required DateTime scheduledAt,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
    String? targetType,
    List<String>? targetRoles,
    List<String>? targetUserIds,
    String? createdBy,
  }) async {
    try {
      return await _backendApi.scheduleNotification(
        userId: userId,
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        type: type,
        relatedAction: relatedAction,
        data: data,
        targetType: targetType,
        targetRoles: targetRoles,
        targetUserIds: targetUserIds,
        createdBy: createdBy,
      );
    } catch (e) {
      _logger.e('Error scheduling notification via backend', error: e);
      rethrow;
    }
  }

  /// Schedule notification for multiple users via backend
  Future<Map<String, dynamic>> scheduleNotificationForUsersViaBackend({
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
      return await _backendApi.scheduleNotificationForUsers(
        userIds: userIds,
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        type: type,
        relatedAction: relatedAction,
        data: data,
        createdBy: createdBy,
      );
    } catch (e) {
      _logger.e('Error scheduling notifications via backend', error: e);
      rethrow;
    }
  }

  /// Cancel scheduled notification via backend
  Future<Map<String, dynamic>> cancelScheduledNotificationViaBackend({
    required String notificationId,
  }) async {
    try {
      return await _backendApi.cancelScheduledNotification(
        notificationId: notificationId,
      );
    } catch (e) {
      _logger.e('Error cancelling notification via backend', error: e);
      rethrow;
    }
  }
}
