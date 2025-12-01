import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/repositories/notification_repository.dart';

/// 通知服务 - 统一管理 OneSignal 和通知逻辑
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final NotificationRepository _repository = NotificationRepository();
  bool _isInitialized = false;

  /// 初始化 OneSignal
  Future<void> initialize() async {
    if (_isInitialized) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    if (appId == null || appId.isEmpty) {
      throw Exception('ONESIGNAL_APP_ID not found in .env');
    }

    OneSignal.initialize(appId);
    OneSignal.Notifications.requestPermission(true);
    
    _isInitialized = true;
  }

  /// 用户登录时设置 External User ID
  Future<void> login(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }
    await OneSignal.login(userId);
  }

  /// 用户登出时移除 External User ID
  Future<void> logout() async {
    await OneSignal.logout();
  }

  /// 设置通知点击处理
  void setupNotificationHandlers({
    required Function(Map<String, dynamic>) onNotificationClick,
    Function(Map<String, dynamic>)? onForegroundNotification,
  }) {
    // 处理通知点击
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData ?? {};
      onNotificationClick(data);
    });

    // 处理前台通知（可选）
    if (onForegroundNotification != null) {
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final data = event.notification.additionalData ?? {};
        onForegroundNotification(data);
      });
    }
  }

  /// 获取 OneSignal Player ID
  String? get playerId => OneSignal.User.pushSubscription.id;

  /// 检查通知权限
  bool get areNotificationsEnabled => 
      OneSignal.Notifications.permission;

  /// 请求通知权限
  Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }

  /// 设置用户标签（用于分组和定向）
  Future<void> setTags(Map<String, String> tags) async {
    await OneSignal.User.addTags(tags);
  }

  /// 移除用户标签
  Future<void> removeTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
  }

  /// 创建并发送通知（简化版 - 直接写入 Supabase）
  /// 
  /// 通知会通过 Supabase Database Trigger 自动触发 Edge Function 发送
  Future<void> createNotification({
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
    String? sound,
    String? category,
    int priority = 5,
  }) async {
    await _repository.createNotification(
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
      sound: sound,
      category: category,
      priority: priority,
    );
  }

  /// 获取用户通知列表
  Future<List<dynamic>> getUserNotifications({
    required String userId,
  }) async {
    return await _repository.getUserNotifications(userId: userId);
  }

  /// 获取未读数量
  Future<int> getUnreadCount(String userId) async {
    return await _repository.getUnreadCount(userId);
  }

  /// 标记为已读
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    await _repository.markAsRead(
      notificationId: notificationId,
      userId: userId,
    );
  }

  /// 标记所有为已读
  Future<void> markAllAsRead(String userId) async {
    await _repository.markAllAsRead(userId);
  }

  /// 删除通知
  Future<void> deleteNotification({
    required String notificationId,
    required String userId,
  }) async {
    await _repository.deleteNotificationForUser(
      notificationId: notificationId,
      userId: userId,
    );
  }
}
