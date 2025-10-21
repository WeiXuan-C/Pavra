import '../../core/models/notification_model.dart';
import '../../core/supabase/supabase_client.dart';

/// Repository for notification data operations
///
/// Handles CRUD operations for notifications table in Supabase
class NotificationRepository {
  final _supabase = supabase;

  /// Get all notifications for a user
  ///
  /// [userId] - User ID to fetch notifications for
  /// [includeDeleted] - Whether to include deleted notifications
  /// [limit] - Maximum number of notifications to fetch
  Future<List<NotificationModel>> getUserNotifications({
    required String userId,
    bool includeDeleted = false,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (!includeDeleted) {
        query = query.eq('is_deleted', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .eq('is_deleted', false)
          .count();

      return response.count;
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('❌ Error marking all as read: $e');
      rethrow;
    }
  }

  /// Soft delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      print('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  /// Delete all notifications for a user (soft delete)
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_deleted', false);
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
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
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'message': message,
            'type': type,
            'related_action': relatedAction,
            'data': data,
          })
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating notification: $e');
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
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (message != null) updateData['message'] = message;
      if (type != null) updateData['type'] = type;
      if (relatedAction != null) updateData['related_action'] = relatedAction;
      if (data != null) updateData['data'] = data;

      final response = await _supabase
          .from('notifications')
          .update(updateData)
          .eq('id', notificationId)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      print('❌ Error updating notification: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time notification updates
  Stream<List<NotificationModel>> subscribeToNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => NotificationModel.fromJson(json)).toList(),
        );
  }
}
