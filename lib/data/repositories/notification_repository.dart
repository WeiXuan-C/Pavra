import '../../core/api/notification/notification_api.dart';
import '../../core/models/notification_model.dart';
import '../../core/supabase/database_service.dart';

/// Notification Repository - 数据仓库层
/// 负责调用 API 并转换为 Model
class NotificationRepository {
  final NotificationApi _api = NotificationApi();
  final DatabaseService _db = DatabaseService();

  /// 获取所有用户列表
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      return await _api.getUsers();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  /// 获取 Action Logs 列表
  Future<List<Map<String, dynamic>>> getActionLogs({int limit = 50}) async {
    try {
      return await _api.getActionLogs(limit: limit);
    } catch (e) {
      throw Exception('Failed to load action logs: $e');
    }
  }

  /// 获取所有通知列表（仅供 Developer 使用，RLS 策略会自动控制权限）
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final data = await _db.selectAdvanced(
        table: 'notifications',
        columns: '*',
        filters: {
          'is_deleted': false, // 只显示未删除的通知
        },
        orderBy: 'created_at',
        ascending: false,
      );
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load all notifications: $e');
    }
  }

  /// 获取用户的通知列表（排除已删除的）
  Future<List<NotificationModel>> getUserNotifications({
    required String userId,
  }) async {
    try {
      final data = await _db.selectAdvanced(
        table: 'notifications',
        columns: '*',
        filters: {
          'user_id': userId,
          'is_deleted': false, // 只显示未删除的通知
        },
        orderBy: 'created_at',
        ascending: false,
      );
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// 获取未读通知数量
  Future<int> getUnreadCount(String userId) async {
    try {
      final data = await _db.selectAdvanced(
        table: 'notifications',
        columns: 'id',
        filters: {'user_id': userId, 'is_read': false, 'is_deleted': false},
      );
      return data.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// 标记为已读
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.update(
        table: 'notifications',
        data: {'is_read': true},
        matchColumn: 'id',
        matchValue: notificationId,
      );
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// 标记所有为已读
  Future<void> markAllAsRead(String userId) async {
    try {
      await _db.update(
        table: 'notifications',
        data: {'is_read': true},
        matchColumn: 'user_id',
        matchValue: userId,
      );
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  /// 删除通知
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.update(
        table: 'notifications',
        data: {'is_deleted': true},
        matchColumn: 'id',
        matchValue: notificationId,
      );
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// 删除所有通知
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _db.update(
        table: 'notifications',
        data: {'is_deleted': true},
        matchColumn: 'user_id',
        matchValue: userId,
      );
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  /// 创建通知
  Future<NotificationModel> createNotification({
    required String userId,
    required String createdBy,
    required String title,
    required String message,
    required String type,
    String status = 'sent',
    DateTime? scheduledAt,
    String? relatedAction,
    Map<String, dynamic>? data,
  }) async {
    try {
      final result = await _api.createNotification(
        userId: userId,
        createdBy: createdBy,
        title: title,
        message: message,
        type: type,
        status: status,
        scheduledAt: scheduledAt,
        relatedAction: relatedAction,
        data: data,
      );
      return NotificationModel.fromJson(result);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// 更新通知
  Future<NotificationModel> updateNotification({
    required String notificationId,
    String? title,
    String? message,
    String? type,
    String? relatedAction,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 只更新提供的字段
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (message != null) updateData['message'] = message;
      if (type != null) updateData['type'] = type;
      if (relatedAction != null) updateData['related_action'] = relatedAction;
      if (data != null) updateData['data'] = data;

      final result = await _db.update(
        table: 'notifications',
        data: updateData,
        matchColumn: 'id',
        matchValue: notificationId,
      );
      return NotificationModel.fromJson(result.first);
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }
}
