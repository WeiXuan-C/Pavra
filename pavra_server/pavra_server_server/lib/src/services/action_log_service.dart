import 'dart:convert';
import '../../server.dart';
import 'redis_service.dart';
import 'supabase_service.dart';

/// Action Log Service - Handles logging user actions to Redis and syncing to Supabase
class ActionLogService {
  final SupabaseService supabase;
  final RedisService redis;

  ActionLogService()
      : supabase = SupabaseService.instance,
        redis = RedisService.instance;

  /// Log a user action to Redis queue
  Future<void> logAction({
    required String userId,
    required String action,
    String? targetId,
    String? targetTable,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final logEntry = {
        'user_id': userId,
        'action': action,
        'target_id': targetId,
        'target_table': targetTable,
        'description': description,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      // Push to Redis queue using LPUSH (list push)
      final queueKey = 'action_logs:queue';
      final logJson = jsonEncode(logEntry);

      await redis.lpush(queueKey, logJson);

      PLog.info('Action logged to Redis: $action by user $userId');
    } catch (e, stack) {
      PLog.error('Failed to log action to Redis', e, stack);
    }
  }

  /// Flush logs from Redis to Supabase
  Future<int> flushLogsToSupabase({int batchSize = 100}) async {
    int syncedCount = 0;

    try {
      PLog.info('Starting flush of action logs to Supabase...');

      final queueKey = 'action_logs:queue';

      for (int i = 0; i < batchSize; i++) {
        // Pop from the right side of the list (FIFO queue)
        final logJson = await redis.rpop(queueKey);
        if (logJson == null) break;

        Map<String, dynamic> log;
        try {
          log = jsonDecode(logJson);
        } catch (e) {
          PLog.warn('Invalid JSON in action log: $logJson');
          continue;
        }

        // Insert to Supabase
        try {
          await supabase.insert('action_log', [log]);
          syncedCount++;
          PLog.info('Log synced to Supabase: ${log['action']}');
        } catch (e) {
          PLog.error('Failed to sync log to Supabase, re-queuing', e);
          // Re-queue the failed log
          await redis.lpush(queueKey, logJson);
          break; // Stop processing to avoid cascading failures
        }
      }

      if (syncedCount > 0) {
        PLog.info('✅ Flushed $syncedCount action logs to Supabase');
      }
    } catch (e, stack) {
      PLog.error('Error flushing logs to Supabase', e, stack);
    }

    return syncedCount;
  }

  /// Get recent actions for a user from Supabase
  Future<List<Map<String, dynamic>>> getUserActions({
    required String userId,
    int limit = 20,
  }) async {
    try {
      return await supabase.select(
        'action_log',
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );
    } catch (e, stack) {
      PLog.error('Failed to fetch user actions from Supabase', e, stack);
      return [];
    }
  }

  /// Health check - verify both Redis and Supabase connections
  Future<Map<String, bool>> healthCheck() async {
    final health = <String, bool>{};

    // Check Redis
    try {
      health['redis'] = await redis.ping();
    } catch (e) {
      health['redis'] = false;
    }

    // Check Supabase
    health['supabase'] = await supabase.healthCheck();

    return health;
  }
}
