import 'package:pavra_server_server/server.dart';
import 'package:serverpod/serverpod.dart';
import '../services/action_log_service.dart';

/// FutureCall that syncs action logs from Upstash Redis queue to Supabase
class ActionLogSyncTask extends FutureCall {
  static const Duration _syncInterval = Duration(minutes: 1);
  static ActionLogService? _actionLogService;

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      PLog.info(
          '🔄 Starting action log sync from Upstash Redis to Supabase...');

      // Initialize service if needed (uses singleton instances)
      _actionLogService ??= ActionLogService();

      // Flush logs from Upstash Redis to Supabase (batch size: 100)
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
    if (!session.serverpod.config.futureCallExecutionEnabled) {
      session.log(
        'Skipping scheduling next action log sync: future calls not enabled',
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
  // Check if future calls are enabled
  if (!pod.config.futureCallExecutionEnabled) {
    PLog.warn('⚠️ Future calls disabled in config, skipping action log sync.');
    return;
  }

  // Try to initialize the action log service to check if dependencies are available
  try {
    ActionLogService();
    PLog.info('✓ Action log service dependencies available.');
  } catch (e) {
    PLog.warn(
        '⚠️ Action log service dependencies not available, skipping sync task.');
    PLog.warn('   Error: $e');
    return;
  }

  try {
    await pod.futureCallWithDelay(
      FutureCallNames.actionLogSync.name,
      null,
      Duration(minutes: 1),
    );

    PLog.info('✓ Action log sync task registered.');
  } catch (e) {
    PLog.warn('⚠️ Failed to register action log sync task: $e');
    PLog.warn(
        '   Action logs will still be stored in Upstash Redis, but not synced to Supabase.');
  }
}
