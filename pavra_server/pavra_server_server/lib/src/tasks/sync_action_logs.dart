import 'dart:io';
import 'package:pavra_server_server/server.dart';
import 'package:serverpod/serverpod.dart';
import '../services/action_log_service.dart';

/// FutureCall that syncs action logs from Redis queue to Supabase
class ActionLogSyncTask extends FutureCall {
  static const Duration _syncInterval = Duration(minutes: 1);
  static ActionLogService? _actionLogService;

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      PLog.info('🔄 Starting action log sync from Redis to Supabase...');

      // Initialize service if needed (uses singleton instances)
      _actionLogService ??= ActionLogService();

      // Flush logs from Redis to Supabase (batch size: 100)
      final syncedCount = await _actionLogService!.flushLogsToSupabase(
        batchSize: 100,
      );

      if (syncedCount > 0) {
        PLog.info('✅ Successfully synced $syncedCount action logs');
      } else {
        PLog.info('ℹ️ No action logs to sync');
      }
    } catch (e, stackTrace) {
      PLog.error('❌ Error during action log sync', e, stackTrace);
    } finally {
      // Schedule next sync
      _scheduleNextSync(session);
    }
  }

  /// Schedules the next sync
  void _scheduleNextSync(Session session) {
    if (!session.serverpod.config.futureCallExecutionEnabled ||
        session.serverpod.config.redis?.enabled != true) {
      session.log(
        'Skipping scheduling next action log sync: future calls or Redis not enabled',
        level: LogLevel.warning,
      );
      return;
    }

    session.serverpod.futureCallAtTime(
      'actionLogSync',
      null,
      DateTime.now().add(_syncInterval),
    );
  }
}

/// Initialize the action log sync task
Future<void> initializeActionLogSync(Serverpod pod) async {
  // Check if we have Redis and Supabase configured
  final hasRedis = Platform.environment['REDIS_URL'] != null;
  final hasSupabase = Platform.environment['SUPABASE_URL'] != null &&
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] != null;

  if (!hasRedis || !hasSupabase) {
    print('⚠️ Redis or Supabase not configured, skipping action log sync.');
    if (!hasRedis) print('   Missing: REDIS_URL');
    if (!hasSupabase)
      print('   Missing: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    return;
  }

  // Check if future calls are enabled
  if (!pod.config.futureCallExecutionEnabled) {
    print('⚠️ Future calls disabled in config, skipping action log sync.');
    return;
  }

  try {
    await pod.futureCallWithDelay(
      FutureCallNames.actionLogSync.name,
      null,
      Duration(minutes: 1),
    );

    print('✓ Action log sync task registered.');
  } catch (e) {
    print('⚠️ Failed to register action log sync task: $e');
    print(
        '   Action logs will still be stored in Redis, but not synced to Supabase.');
  }
}
