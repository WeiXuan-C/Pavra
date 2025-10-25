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
  }) async {
    final data = await supabase
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
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    // 扁平化数据结构
    return data.map((row) {
      final notification = row['notifications'] as Map<String, dynamic>;
      return {
        ...notification,
        'is_read': row['is_read'],
        'is_deleted': row['is_deleted'],
        'read_at': row['read_at'],
      };
    }).toList();
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
    await supabase
        .from('user_notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .match({'user_id': userId, 'is_deleted': false});
  }

  /// 用户删除通知（软删除）
  Future<void> deleteNotificationForUser({
    required String notificationId,
    required String userId,
  }) async {
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
    await supabase
        .from('notifications')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);
  }

  /// 管理员硬删除通知（永久删除，谨慎使用）
  Future<void> hardDeleteNotification({required String notificationId}) async {
    await supabase.from('notifications').delete().eq('id', notificationId);
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
  }) async {
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
        print('⚠️ Failed to schedule notification: $e');
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

      print('✓ Notification send triggered: $notificationId');
    } catch (e) {
      print('❌ Failed to trigger notification send: $e');
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

      print('✓ Notification scheduled via QStash: $notificationId');
    } catch (e) {
      print('❌ Failed to schedule notification: $e');
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
  }) async {
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

    final result = await supabase
        .from('notifications')
        .update(updateData)
        .eq('id', notificationId)
        .select()
        .single();

    // 如果状态从 draft 改为 sent，触发发送
    if (status == 'sent') {
      try {
        await _triggerNotificationSend(notificationId);
      } catch (e) {
        print('⚠️ Failed to trigger notification send after update: $e');
      }
    }
    // 如果状态从 draft 改为 scheduled，调度发送
    else if (status == 'scheduled' && scheduledAt != null) {
      try {
        await _scheduleNotificationViaServerpod(
          notificationId: notificationId,
          scheduledAt: scheduledAt,
        );
      } catch (e) {
        print('⚠️ Failed to schedule notification after update: $e');
      }
    }

    return result;
  }
}
