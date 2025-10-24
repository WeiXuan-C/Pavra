import '../../supabase/database_service.dart';

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

  /// 创建通知
  Future<Map<String, dynamic>> createNotification({
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
    final now = DateTime.now();

    final result = await _db.insert<Map<String, dynamic>>(
      table: 'notifications',
      data: {
        'user_id': userId,
        'created_by': createdBy,
        'title': title,
        'message': message,
        'type': type,
        'status': status,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'sent_at': status == 'sent' ? now.toIso8601String() : null,
        'related_action': relatedAction,
        'data': data,
        'is_read': false,
        'is_deleted': false,
      },
    );
    return result;
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
    final result = await _db.update(
      table: 'notifications',
      data: {
        'title': title,
        'message': message,
        'type': type,
        'related_action': relatedAction,
        'data': data,
      },
      matchColumn: 'id',
      matchValue: notificationId,
    );
    return result.first;
  }
}
