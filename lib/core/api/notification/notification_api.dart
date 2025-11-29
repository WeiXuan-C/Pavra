import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../supabase/database_service.dart';
import '../../supabase/supabase_client.dart';

/// Notification API - 通知相关的业务逻辑
class NotificationApi {
  final DatabaseService _db = DatabaseService();

  /// 获取所有用户列表
  Future<List<Map<String, dynamic>>> getUsers() async {
    return await _db.selectAdvanced(
      table: 'profiles',
      columns: 'id, username, email, role',
      orderBy: 'username',
      ascending: true,
    );
  }

  /// 获取 Action Logs 列表（带用户信息）
  Future<List<Map<String, dynamic>>> getActionLogs({int limit = 50}) async {
    // 先获取 action logs
    final logs = await _db.selectAdvanced(
      table: 'action_log',
      columns: 'id, action_type, description, created_at, user_id',
      orderBy: 'created_at',
      ascending: false,
      limit: limit,
    );

    // 如果没有 logs，直接返回
    if (logs.isEmpty) return logs;

    // 获取所有相关的 user_ids
    final userIds = logs
        .map((log) => log['user_id'] as String?)
        .where((id) => id != null)
        .toSet()
        .toList();

    // 如果没有 user_ids，返回原始 logs
    if (userIds.isEmpty) return logs;

    // 批量获取用户信息
    final users = await _db.selectAll(
      table: 'profiles',
      columns: 'id, username, email',
    );

    // 创建 user_id -> user 的映射
    final userMap = <String, Map<String, dynamic>>{};
    for (final user in users) {
      final userId = user['id'] as String?;
      if (userId != null && userIds.contains(userId)) {
        userMap[userId] = user;
      }
    }

    // 将用户信息附加到 logs
    return logs.map((log) {
      final userId = log['user_id'] as String?;
      final user = userId != null ? userMap[userId] : null;

      return {
        ...log,
        'profiles': user ?? {'username': 'Unknown User', 'email': ''},
      };
    }).toList();
  }

  /// 获取用户的通知列表（JOIN user_notifications）
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    String? type,
    bool? isRead,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = supabase
        .from('user_notifications')
        .select('''
          id,
          is_read,
          is_deleted,
          read_at,
          notifications!inner(
            id,
            title,
            message,
            type,
            related_action,
            data,
            status,
            scheduled_at,
            sent_at,
            target_type,
            target_roles,
            target_user_ids,
            created_by,
            created_at,
            updated_at
          )
        ''')
        .eq('user_id', userId)
        .eq('is_deleted', false);

    // Apply filters
    if (isRead != null) {
      query = query.eq('is_read', isRead);
    }

    final data = await query.order('created_at', ascending: false);

    // 扁平化数据结构
    var results = data.map((row) {
      final notification = row['notifications'] as Map<String, dynamic>;
      return {
        ...notification,
        'is_read': row['is_read'],
        'is_deleted': row['is_deleted'],
        'read_at': row['read_at'],
      };
    }).toList();

    // Apply client-side filters (for fields in the notifications table)
    if (type != null) {
      results = results.where((n) => n['type'] == type).toList();
    }

    if (startDate != null) {
      results = results.where((n) {
        final createdAt = DateTime.parse(n['created_at'] as String);
        return createdAt.isAfter(startDate) || createdAt.isAtSameMomentAs(startDate);
      }).toList();
    }

    if (endDate != null) {
      results = results.where((n) {
        final createdAt = DateTime.parse(n['created_at'] as String);
        return createdAt.isBefore(endDate) || createdAt.isAtSameMomentAs(endDate);
      }).toList();
    }

    return results;
  }

  /// 获取所有通知（Developer 专用）
  Future<List<Map<String, dynamic>>> getAllNotifications({
    bool includeDeleted = false,
  }) async {
    if (includeDeleted) {
      return await _db.selectAdvanced(
        table: 'notifications',
        columns: '*',
        orderBy: 'created_at',
        ascending: false,
      );
    } else {
      return await _db.selectAdvanced(
        table: 'notifications',
        columns: '*',
        filters: {'is_deleted': false},
        orderBy: 'created_at',
        ascending: false,
      );
    }
  }

  /// 获取未读数量
  Future<int> getUnreadCount(String userId) async {
    final result = await supabase
        .from('user_notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false)
        .eq('is_deleted', false);

    return result.length;
  }

  /// 标记为已读
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    await supabase
        .from('user_notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .match({'notification_id': notificationId, 'user_id': userId});
  }

  /// 标记所有为已读
  Future<void> markAllAsRead(String userId) async {
    // Update all unread notifications for the user
    await supabase
        .from('user_notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .eq('is_read', false);

    // Verify unread count becomes zero
    final unreadCount = await getUnreadCount(userId);
    if (unreadCount != 0) {
      throw Exception(
        'Failed to mark all notifications as read. Unread count: $unreadCount',
      );
    }
  }

  /// 用户删除通知（软删除）
  Future<void> deleteNotificationForUser({
    required String notificationId,
    required String userId,
  }) async {
    // Verify user is deleting their own notification
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (currentUserId != userId) {
      throw Exception(
        'Permission denied. Users can only delete their own notifications.',
      );
    }

    await supabase
        .from('user_notifications')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .match({'notification_id': notificationId, 'user_id': userId});
  }

  /// 管理员删除通知（软删除，用于 draft/scheduled）
  Future<void> deleteNotification({required String notificationId}) async {
    // 1. Fetch current notification to check status and creator
    final notification = await supabase
        .from('notifications')
        .select('status, onesignal_notification_id, created_by')
        .eq('id', notificationId)
        .single();

    final status = notification['status'] as String;
    final oneSignalId = notification['onesignal_notification_id'] as String?;
    final createdBy = notification['created_by'] as String?;

    // 2. Verify user has permission to delete (must be creator)
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (createdBy != currentUserId) {
      throw Exception(
        'Permission denied. Only the creator can delete this notification.',
      );
    }

    // 3. Validation: Prevent deleting sent notifications
    if (status == 'sent') {
      throw Exception(
        'Cannot delete notification with status "sent". Sent notifications cannot be deleted.',
      );
    }

    // 4. If scheduled, cancel the OneSignal notification
    if (status == 'scheduled' && oneSignalId != null) {
      try {
        await _cancelScheduledNotificationViaServerpod(oneSignalId);
      } catch (e) {
        print('⚠️ Failed to cancel scheduled notification: $e');
        // Continue with soft delete even if cancellation fails
      }
    }

    // 5. Perform soft delete
    await supabase
        .from('notifications')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);
  }

  /// 通过 Serverpod 取消已调度的通知
  Future<void> _cancelScheduledNotificationViaServerpod(
    String oneSignalNotificationId,
  ) async {
    final serverpodUrl = ApiConfig.serverpodUrl;

    try {
      final response = await http.post(
        Uri.parse('$serverpodUrl/notification/cancelScheduledNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'oneSignalNotificationId': oneSignalNotificationId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Serverpod API error: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 管理员硬删除通知（永久删除，谨慎使用）
  /// 
  /// This permanently deletes the notification and all associated user_notification records.
  /// Requires admin permission check on the server side.
  /// Use with extreme caution - this action cannot be undone.
  Future<void> hardDeleteNotification({
    required String notificationId,
    required String userId,
  }) async {
    // Verify user has permission before making the request
    final hasPermission = await _canHardDeleteNotification(userId);
    if (!hasPermission) {
      throw Exception(
        'Permission denied. Only admin or developer can hard delete notifications.',
      );
    }

    // Call Serverpod endpoint to perform hard delete with permission check
    final serverpodUrl = ApiConfig.serverpodUrl;

    try {
      final response = await http.post(
        Uri.parse('$serverpodUrl/notification/hardDeleteNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'notificationId': notificationId,
          'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorBody['error'] ?? 'Failed to delete notification');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has permission to hard delete notifications
  Future<bool> _canHardDeleteNotification(String userId) async {
    try {
      final users = await _db.selectAdvanced(
        table: 'profiles',
        filters: {'id': userId},
        columns: 'role',
      );

      if (users.isEmpty) {
        return false;
      }

      final role = users.first['role'] as String?;
      return role == 'admin' || role == 'developer';
    } catch (e) {
      return false;
    }
  }

  /// Check if user has permission to create notifications
  Future<bool> _canCreateNotification(String userId) async {
    try {
      final users = await _db.selectAdvanced(
        table: 'profiles',
        filters: {'id': userId},
        columns: 'role',
      );

      if (users.isEmpty) {
        return false;
      }

      final role = users.first['role'] as String?;
      return role == 'developer' || role == 'authority';
    } catch (e) {
      return false;
    }
  }

  /// 创建通知并通过 OneSignal 发送推送或通过 QStash 调度
  Future<Map<String, dynamic>> createNotification({
    required String createdBy,
    required String title,
    required String message,
    required String type,
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
    String? oneSignalNotificationId,
  }) async {
    // Verify user has permission to create notifications
    // Skip permission check for 'system' user (used for automated notifications)
    if (createdBy != 'system') {
      final hasPermission = await _canCreateNotification(createdBy);
      if (!hasPermission) {
        throw Exception(
          'Permission denied. Only developers and authorities can create notifications.',
        );
      }
    }

    final now = DateTime.now();

    // 1. 创建通知记录
    final result = await supabase
        .from('notifications')
        .insert({
          'created_by': createdBy,
          'title': title,
          'message': message,
          'type': type,
          'status': status,
          'scheduled_at': scheduledAt?.toIso8601String(),
          'sent_at': status == 'sent' ? now.toIso8601String() : null,
          'related_action': relatedAction,
          'data': data,
          'target_type': targetType,
          'target_roles': targetRoles,
          'target_user_ids': targetUserIds,
          'sound': sound,
          'category': category,
          'priority': priority,
          'onesignal_notification_id': oneSignalNotificationId,
        })
        .select()
        .single();

    final notificationId = result['id'] as String;

    // 2. 根据状态处理
    if (status == 'sent') {
      // 立即发送：调用 Serverpod endpoint 来发送推送
      try {
        await _triggerNotificationSend(notificationId);
      } catch (e) {
        print('⚠️ Failed to trigger notification send: $e');
      }
    } else if (status == 'scheduled' && scheduledAt != null) {
      // 调度发送：调用 Serverpod endpoint 来通过 QStash 调度
      try {
        await _scheduleNotificationViaServerpod(
          notificationId: notificationId,
          scheduledAt: scheduledAt,
        );
      } catch (e) {
        // 如果调度失败，更新状态为 failed
        await supabase
            .from('notifications')
            .update({'status': 'failed'})
            .eq('id', notificationId);
      }
    }
    // status == 'draft' 不做任何操作

    return result;
  }

  /// 触发通知发送（通过 Serverpod endpoint）
  Future<void> _triggerNotificationSend(String notificationId) async {
    final serverpodUrl = ApiConfig.serverpodUrl;

    try {
      final response = await http.post(
        Uri.parse('$serverpodUrl/notification/handleNotificationCreated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'notificationId': notificationId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Serverpod API error: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 通过 Serverpod 调度通知（使用 QStash）
  Future<void> _scheduleNotificationViaServerpod({
    required String notificationId,
    required DateTime scheduledAt,
  }) async {
    final serverpodUrl = ApiConfig.serverpodUrl;

    try {
      final response = await http.post(
        Uri.parse('$serverpodUrl/notification/scheduleNotificationById'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'notificationId': notificationId,
          'scheduledAt': scheduledAt.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Serverpod API error: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 🧪 测试：手动触发 scheduled notification 处理
  ///
  /// 用于本地开发测试，模拟 QStash webhook 的行为
  ///
  /// 使用方法：
  /// 1. 创建一个 scheduled notification
  /// 2. 复制 notification ID
  /// 3. 调用此方法：await testProcessScheduledNotification('notification-id')
  /// 4. 检查 Supabase 中的状态是否更新为 'sent'
  Future<Map<String, dynamic>> testProcessScheduledNotification(
    String notificationId,
  ) async {
    final serverpodUrl = ApiConfig.serverpodUrl;

    try {
      final response = await http.post(
        Uri.parse(
          '$serverpodUrl/notification/testProcessScheduledNotification',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'notificationId': notificationId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Test failed: ${response.body}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新通知（支持更新所有字段）
  Future<Map<String, dynamic>> updateNotification({
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
    String? sound,
    String? category,
    int? priority,
  }) async {
    // 1. Fetch current notification to check status, creator, and get QStash message ID
    final currentNotification = await supabase
        .from('notifications')
        .select('status, data, created_by')
        .eq('id', notificationId)
        .single();

    final currentStatus = currentNotification['status'] as String;
    final currentData = currentNotification['data'] as Map<String, dynamic>?;
    final qstashMessageId = currentData?['qstash_message_id'] as String?;
    final createdBy = currentNotification['created_by'] as String?;

    // 2. Verify user has permission to update (must be creator and draft status)
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (createdBy != currentUserId) {
      throw Exception(
        'Permission denied. Only the creator can update this notification.',
      );
    }

    // 3. Validation: Prevent updating sent notifications
    if (currentStatus == 'sent') {
      throw Exception(
        'Cannot update notification with status "sent". Sent notifications are immutable.',
      );
    }

    // 4. If updating a scheduled notification, cancel the previous QStash job
    if (currentStatus == 'scheduled' && qstashMessageId != null) {
      try {
        await _cancelQStashJob(qstashMessageId);
        print('✓ Cancelled previous QStash job: $qstashMessageId');
      } catch (e) {
        print('⚠️ Failed to cancel previous QStash job: $e');
        // Continue with update even if cancellation fails
      }
    }

    final updateData = <String, dynamic>{
      'title': title,
      'message': message,
      'type': type,
      'related_action': relatedAction,
      'data': data,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // 只有提供了这些字段才更新
    if (status != null) {
      updateData['status'] = status;
      // 如果状态改为 sent，设置 sent_at
      if (status == 'sent') {
        updateData['sent_at'] = DateTime.now().toIso8601String();
      }
    }
    if (scheduledAt != null) {
      updateData['scheduled_at'] = scheduledAt.toIso8601String();
    }
    if (targetType != null) {
      updateData['target_type'] = targetType;
    }
    if (targetRoles != null) {
      updateData['target_roles'] = targetRoles;
    }
    if (targetUserIds != null) {
      updateData['target_user_ids'] = targetUserIds;
    }
    if (sound != null) {
      updateData['sound'] = sound;
    }
    if (category != null) {
      updateData['category'] = category;
    }
    if (priority != null) {
      updateData['priority'] = priority;
    }

    final result = await supabase
        .from('notifications')
        .update(updateData)
        .eq('id', notificationId)
        .select()
        .single();

    // 4. Handle status transitions
    // If status changed from draft to sent, trigger immediate send
    if (status == 'sent' && currentStatus == 'draft') {
      try {
        await _triggerNotificationSend(notificationId);
      } catch (e) {
        print('⚠️ Failed to trigger notification send after update: $e');
      }
    }
    // If status changed from draft to scheduled, schedule the notification
    else if (status == 'scheduled' && currentStatus == 'draft' && scheduledAt != null) {
      try {
        await _scheduleNotificationViaServerpod(
          notificationId: notificationId,
          scheduledAt: scheduledAt,
        );
      } catch (e) {
        print('⚠️ Failed to schedule notification after update: $e');
      }
    }
    // If updating a scheduled notification with new scheduled time, reschedule
    else if (currentStatus == 'scheduled' && status == 'scheduled' && scheduledAt != null) {
      try {
        await _scheduleNotificationViaServerpod(
          notificationId: notificationId,
          scheduledAt: scheduledAt,
        );
      } catch (e) {
        print('⚠️ Failed to reschedule notification after update: $e');
      }
    }

    return result;
  }

  /// Cancel a QStash scheduled job
  Future<void> _cancelQStashJob(String qstashMessageId) async {
    final serverpodUrl = ApiConfig.serverpodUrl;

    try {
      final response = await http.post(
        Uri.parse('$serverpodUrl/notification/cancelQStashJob'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'qstashMessageId': qstashMessageId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Serverpod API error: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
