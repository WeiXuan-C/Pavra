import '../../core/api/notification/notification_api.dart';
import '../../core/models/notification_model.dart';

/// Notification Repository - 数据仓库层
/// 负责调用 API 并转换为 Model
class NotificationRepository {
  final NotificationApi _api = NotificationApi();

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

  /// 获取用户的通知列表（通过 user_notifications JOIN）
  Future<List<NotificationModel>> getUserNotifications({
    required String userId,
  }) async {
    try {
      final data = await _api.getUserNotifications(userId: userId);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// 获取所有通知（Developer 专用）
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final data = await _api.getAllNotifications();
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load all notifications: $e');
    }
  }

  /// 获取未读通知数量
  Future<int> getUnreadCount(String userId) async {
    try {
      return await _api.getUnreadCount(userId);
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// 标记为已读
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _api.markAsRead(notificationId: notificationId, userId: userId);
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// 标记所有为已读
  Future<void> markAllAsRead(String userId) async {
    try {
      await _api.markAllAsRead(userId);
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  /// 用户删除通知（软删除 - 更新 user_notifications）
  Future<void> deleteNotificationForUser({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _api.deleteNotificationForUser(
        notificationId: notificationId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// 管理员删除通知（软删除 - 更新 notifications 的 is_deleted）
  /// 适用于 draft 或 scheduled 状态的通知
  Future<void> deleteNotification({required String notificationId}) async {
    try {
      await _api.deleteNotification(notificationId: notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// 管理员硬删除通知（永久删除 - 删除 notifications 记录）
  /// 谨慎使用，会级联删除所有 user_notifications
  Future<void> hardDeleteNotification({required String notificationId}) async {
    try {
      await _api.hardDeleteNotification(notificationId: notificationId);
    } catch (e) {
      throw Exception('Failed to hard delete notification: $e');
    }
  }

  /// 创建通知
  Future<NotificationModel> createNotification({
    required String createdBy,
    required String title,
    required String message,
    String type = 'info',
    String status = 'sent',
    DateTime? scheduledAt,
    String? relatedAction,
    Map<String, dynamic>? data,
    String targetType = 'single',
    List<String>? targetRoles,
    List<String>? targetUserIds,
  }) async {
    try {
      final result = await _api.createNotification(
        createdBy: createdBy,
        title: title,
        message: message,
        type: type,
        status: status,
        scheduledAt: scheduledAt,
        relatedAction: relatedAction,
        data: data,
        targetType: targetType,
        targetRoles: targetRoles,
        targetUserIds: targetUserIds,
      );
      return NotificationModel.fromJson(result);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// 更新通知（支持更新所有字段）
  Future<NotificationModel> updateNotification({
    required String notificationId,
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
  }) async {
    try {
      final result = await _api.updateNotification(
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
      return NotificationModel.fromJson(result);
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }
}
