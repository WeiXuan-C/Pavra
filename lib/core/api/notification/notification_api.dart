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

    // 4. 调度通知会由 pg_cron 自动处理，无需手动取消

    // 5. Perform soft delete
    await supabase
        .from('notifications')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);
  }



  /// 管理员硬删除通知（永久删除，谨慎使用）
  /// 
  /// This permanently deletes the notification and all associated user_notification records.
  /// Use with extreme caution - this action cannot be undone.
  Future<void> hardDeleteNotification({
    required String notificationId,
    required String userId,
  }) async {
    // Verify user has permission
    final hasPermission = await _canHardDeleteNotification(userId);
    if (!hasPermission) {
      throw Exception(
        'Permission denied. Only admin or developer can hard delete notifications.',
      );
    }

    // 直接删除通知记录（会级联删除 user_notifications）
    await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);
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

  /// 创建通知（简化版 - 直接写入 Supabase）
  /// 
  /// 通知会通过 Supabase Database Trigger 自动触发发送
  /// - status='sent': 立即通过 Edge Function 发送
  /// - status='scheduled': 通过 pg_cron 定时任务在指定时间发送
  /// - status='draft': 不发送，仅保存
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

    // 直接创建通知记录，Supabase Trigger 会自动处理发送逻辑
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

    return result;
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
    // 1. Fetch current notification to check status and creator
    final currentNotification = await supabase
        .from('notifications')
        .select('status, created_by')
        .eq('id', notificationId)
        .single();

    final currentStatus = currentNotification['status'] as String;
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

    // 4. 如果更新调度通知，旧的调度会被 pg_cron 自动处理
    // 不需要手动取消，因为我们不再使用 QStash

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

    // 4. 状态变更会由 Supabase Trigger 自动处理
    // - draft -> sent: Trigger 会自动发送
    // - draft -> scheduled: pg_cron 会在指定时间处理
    // - scheduled -> sent: pg_cron 会自动更新并发送

    return result;
  }


}
