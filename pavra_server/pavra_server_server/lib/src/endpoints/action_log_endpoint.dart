import 'package:serverpod/serverpod.dart';
import '../services/action_log_service.dart';

/// Endpoint for logging user actions to Upstash Redis → Supabase
///
/// This endpoint handles:
/// - Logging actions to Upstash Redis queue (instant)
/// - Retrieving action history from Supabase
/// - Manual flush of Upstash Redis queue to Supabase
/// - Health checks for Upstash Redis and Supabase
class ActionLogEndpoint extends Endpoint {
  final ActionLogService _actionLogService = ActionLogService();

  /// Log a user action to Upstash Redis queue
  ///
  /// Actions are queued in Upstash Redis and automatically synced to Supabase every minute.
  ///
  /// Example:
  /// ```dart
  /// await client.actionLog.log(
  ///   userId: 'user-123',
  ///   action: 'profile_viewed',
  ///   targetId: 'profile-456',
  ///   description: 'User viewed another profile',
  /// );
  /// ```
  Future<bool> log(
    Session session, {
    required String userId,
    required String action,
    String? targetId,
    String? targetTable,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _actionLogService.logAction(
        userId: userId,
        action: action,
        targetId: targetId,
        targetTable: targetTable,
        description: description,
        metadata: metadata,
      );

      session.log('Action logged: $action for user $userId');
      return true;
    } catch (e) {
      session.log('Failed to log action: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Get recent actions for a user from Supabase
  Future<List<Map<String, dynamic>>> getUserActions(
    Session session,
    String userId, {
    int limit = 20,
  }) async {
    try {
      return await _actionLogService.getUserActions(
        userId: userId,
        limit: limit,
      );
    } catch (e) {
      session.log('Failed to get user actions: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Manually trigger flush of Upstash Redis logs to Supabase
  Future<int> flushLogs(Session session, {int batchSize = 100}) async {
    try {
      final count = await _actionLogService.flushLogsToSupabase(
        batchSize: batchSize,
      );
      session.log('Flushed $count logs to Supabase');
      return count;
    } catch (e) {
      session.log('Failed to flush logs: $e', level: LogLevel.error);
      return 0;
    }
  }

  /// Health check for Upstash Redis and Supabase
  Future<Map<String, bool>> healthCheck(Session session) async {
    return await _actionLogService.healthCheck();
  }
}
