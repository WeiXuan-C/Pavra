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
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
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
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
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
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _logger.e('Error marking all notifications as read', error: e);
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting notification', error: e);
      rethrow;
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _repository.deleteAllNotifications(userId);

      // Clear local state
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting all notifications', error: e);
      rethrow;
    }
  }

  /// Refresh notifications
  Future<void> refresh(String userId) async {
    await loadNotifications(userId);
  }
}
