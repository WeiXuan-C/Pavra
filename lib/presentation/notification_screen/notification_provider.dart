import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../core/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

/// Provider for notification screen state management
class NotificationProvider extends ChangeNotifier {
  final _repository = NotificationRepository();
  final _logger = Logger();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  /// Load notifications for a user
  /// 所有用户都通过 user_notifications 表查询
  Future<void> loadNotifications(String userId, {String? userRole}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 所有用户都使用相同的查询（通过 user_notifications）
      _notifications = await _repository.getUserNotifications(userId: userId);
      _unreadCount = await _repository.getUnreadCount(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _logger.e('Error loading notifications', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _repository.markAsRead(
        notificationId: notificationId,
        userId: userId,
      );

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error marking notification as read', error: e);
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _repository.markAllAsRead(userId);

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _logger.e('Error marking all notifications as read', error: e);
      rethrow;
    }
  }

  /// Delete notification for user (soft delete)
  Future<void> deleteNotificationForUser(
    String notificationId,
    String userId,
  ) async {
    try {
      await _repository.deleteNotificationForUser(
        notificationId: notificationId,
        userId: userId,
      );

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting notification', error: e);
      rethrow;
    }
  }

  /// Delete notification (admin - hard delete)
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId: notificationId);

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting notification', error: e);
      rethrow;
    }
  }

  /// Refresh notifications
  Future<void> refresh(String userId, {String? userRole}) async {
    await loadNotifications(userId, userRole: userRole);
  }

  /// Create a new notification
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
      final notification = await _repository.createNotification(
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

      // Add to local state
      _notifications.insert(0, notification);
      if (!notification.isRead) {
        _unreadCount++;
      }
      notifyListeners();

      return notification;
    } catch (e) {
      _logger.e('Error creating notification', error: e);
      rethrow;
    }
  }

  /// Update an existing notification
  Future<NotificationModel> updateNotification({
    required String notificationId,
    required String title,
    required String message,
    required String type,
    String? relatedAction,
    Map<String, dynamic>? data,
  }) async {
    try {
      final updatedNotification = await _repository.updateNotification(
        notificationId: notificationId,
        title: title,
        message: message,
        type: type,
        relatedAction: relatedAction,
        data: data,
      );

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updatedNotification;
        notifyListeners();
      }

      return updatedNotification;
    } catch (e) {
      _logger.e('Error updating notification', error: e);
      rethrow;
    }
  }
}
