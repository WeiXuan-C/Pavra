import 'package:pavra_server_server/server.dart';
import 'package:serverpod/serverpod.dart';
import '../services/action_log_service.dart';

/// FutureCall that syncs action logs from local PostgreSQL to Supabase
class ActionLogSyncTask extends FutureCall {
  static const Duration _syncInterval = Duration(minutes: 1);
  static ActionLogService? _actionLogService;

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      PLog.info('Starting action log sync...');

      // Initialize service if needed (uses singleton instances)
      _actionLogService ??= ActionLogService();

      // Fetch unsynced logs from PostgreSQL
      final unsyncedLogs = await _fetchUnsyncedLogs(session);

      if (unsyncedLogs.isEmpty) {
        PLog.info('No unsynced logs found in PostgreSQL');
        _scheduleNextSync(session);
        return;
      }

      PLog.info('Found ${unsyncedLogs.length} unsynced logs');

      // Push to Supabase using ActionLogService
      final syncedIds = await _pushToSupabase(session, unsyncedLogs);

      // Mark as synced in local DB
      if (syncedIds.isNotEmpty) {
        await _markAsSynced(session, syncedIds);
        PLog.info('Successfully synced ${syncedIds.length} action logs');
      }
    } catch (e, stackTrace) {
      PLog.error('Error during action log sync', e, stackTrace);
    } finally {
      // Schedule next sync
      _scheduleNextSync(session);
    }
  }

  /// Fetches unsynced logs from local database
  Future<List<Map<String, dynamic>>> _fetchUnsyncedLogs(
    Session session,
  ) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
        SELECT id, user_id, action_type, target_id, target_table, 
               description, metadata, created_at
        FROM action_log
        WHERE is_synced = FALSE
        ORDER BY created_at ASC
        LIMIT 100
        ''',
      );

      return result.map((row) {
        return {
          'id': row[0],
          'user_id': row[1],
          'action_type': row[2],
          'target_id': row[3],
          'target_table': row[4],
          'description': row[5],
          'metadata': row[6],
          'created_at': row[7]?.toString(),
        };
      }).toList();
    } catch (e) {
      session.log(
        'Error fetching unsynced logs: $e',
        level: LogLevel.error,
      );
      rethrow;
    }
  }

  /// Pushes logs to Supabase using ActionLogService
  Future<List<int>> _pushToSupabase(
    Session session,
    List<Map<String, dynamic>> logs,
  ) async {
    final syncedIds = <int>[];

    try {
      // Use ActionLogService to insert logs
      final service = _actionLogService!;

      // Remove 'id' field before inserting to Supabase (it will generate its own)
      final logsForSupabase = logs.map((log) {
        final logCopy = Map<String, dynamic>.from(log);
        final localId = logCopy.remove('id'); // Store local DB id
        return {'localId': localId, 'data': logCopy};
      }).toList();

      for (final entry in logsForSupabase) {
        try {
          await service.supabase
              .insert('action_log', [entry['data'] as Map<String, dynamic>]);
          syncedIds.add(entry['localId'] as int);
        } catch (e) {
          PLog.error('Failed to sync log ${entry['localId']}', e);
        }
      }

      PLog.info(
          'Successfully pushed ${syncedIds.length}/${logs.length} logs to Supabase');
    } catch (e, stack) {
      PLog.error('Error pushing to Supabase', e, stack);
    }

    return syncedIds;
  }

  /// Marks logs as synced in local database
  Future<void> _markAsSynced(
    Session session,
    List<int> logIds,
  ) async {
    try {
      final idsString = logIds.join(',');
      await session.db.unsafeQuery(
        '''
        UPDATE action_log
        SET is_synced = TRUE
        WHERE id IN ($idsString)
        ''',
      );
    } catch (e) {
      session.log(
        'Error marking logs as synced: $e',
        level: LogLevel.error,
      );
      rethrow;
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
  if (!pod.config.futureCallExecutionEnabled ||
      pod.config.redis?.enabled != true) {
    print(
        '⚠️ Future calls disabled or Redis not enabled, skipping action log sync.');
    return;
  }

  await pod.futureCallWithDelay(
    FutureCallNames.actionLogSync.name,
    null,
    Duration(minutes: 1),
  );

  print('✓ Action log sync task registered.');
}
