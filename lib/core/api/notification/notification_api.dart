import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// 创建通知并通过 OneSignal 发送推送
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

    // 2. 如果是立即发送，通过 OneSignal 推送
    if (status == 'sent' && targetUserIds != null && targetUserIds.isNotEmpty) {
      try {
        await _sendPushNotification(
          title: title,
          message: message,
          targetUserIds: targetUserIds,
          data: {'notification_id': result['id'], 'type': type, ...?data},
        );
      } catch (e) {
        // 推送失败不影响通知创建
        print('⚠️ OneSignal push failed: $e');
      }
    }

    return result;
  }

  /// 通过 OneSignal 发送推送
  Future<void> _sendPushNotification({
    required String title,
    required String message,
    required List<String> targetUserIds,
    Map<String, dynamic>? data,
  }) async {
    // 使用 OneSignal REST API 直接发送
    final appId = '2eebafba-17aa-49a6-91aa-f9f7f2f72aca';
    final apiKey =
        'os_v2_app_f3v27oqxvje2nenk7h37f5zkzlnemkqsxkuezzffpgs3ug34lfz4gluj5rzlhqysuixzw5yr6lp4t36yxkj3r7camutveielpkqx24i';

    final response = await http.post(
      Uri.parse('https://api.onesignal.com/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $apiKey',
      },
      body: jsonEncode({
        'app_id': appId,
        'include_aliases': {'external_id': targetUserIds},
        'target_channel': 'push',
        'headings': {'en': title},
        'contents': {'en': message},
        if (data != null) 'data': data,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OneSignal API error: ${response.body}');
    }

    print('✓ OneSignal push sent to ${targetUserIds.length} users');
  }

  /// 更新通知
  Future<Map<String, dynamic>> updateNotification({
    required String notificationId,
    required String title,
    required String message,
    required String type,
    String? relatedAction,
    Map<String, dynamic>? data,
  }) async {
    final result = await supabase
        .from('notifications')
        .update({
          'title': title,
          'message': message,
          'type': type,
          'related_action': relatedAction,
          'data': data,
        })
        .eq('id', notificationId)
        .select()
        .single();

    return result;
  }
}
