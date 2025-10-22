import '../../models/notification_model.dart';
import '../../supabase/supabase_client.dart';

/// Notification API
/// Handles all notification-related API calls to Supabase
class NotificationApi {
  /// Get notifications for a user
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    bool? isRead,
    int limit = 50,
  }) async {
    try {
      dynamic query = supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;
      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Create a new notification
  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
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
      final notificationData = {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_action': relatedAction,
        'data': data ?? {},
        'status': status ?? 'sent',
        'scheduled_at': scheduledAt?.toIso8601String(),
        'target_type': targetType ?? 'single',
        'target_roles': targetRoles,
        'target_user_ids': targetUserIds,
        'created_by': createdBy,
        'is_read': false,
        'is_deleted': false,
      };

      final response = await supabase
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Update notification
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
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (message != null) updateData['message'] = message;
      if (type != null) updateData['type'] = type;
      if (relatedAction != null) updateData['related_action'] = relatedAction;
      if (data != null) updateData['data'] = data;
      if (status != null) updateData['status'] = status;
      if (scheduledAt != null) {
        updateData['scheduled_at'] = scheduledAt.toIso8601String();
      }
      if (targetType != null) updateData['target_type'] = targetType;
      if (targetRoles != null) updateData['target_roles'] = targetRoles;
      if (targetUserIds != null) updateData['target_user_ids'] = targetUserIds;

      final response = await supabase
          .from('notifications')
          .update(updateData)
          .eq('id', notificationId)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification (soft delete)
  Future<void> deleteNotification(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await supabase
          .from('notifications')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  /// Get scheduled notifications (for admin)
  Future<List<NotificationModel>> getScheduledNotifications() async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('status', 'scheduled')
          .order('scheduled_at', ascending: true);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch scheduled notifications: $e');
    }
  }

  /// Get draft notifications (for admin)
  Future<List<NotificationModel>> getDraftNotifications(
    String createdBy,
  ) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('status', 'draft')
          .eq('created_by', createdBy)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch draft notifications: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .eq('is_deleted', false)
          .count();

      return response.count;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }
}
