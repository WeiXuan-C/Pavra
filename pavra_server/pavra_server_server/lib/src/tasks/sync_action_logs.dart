import 'dart:convert';
import 'package:pavra_server_server/server.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

/// FutureCall that syncs action logs from local PostgreSQL to Supabase
class ActionLogSyncTask extends FutureCall {
  static const Duration _syncInterval = Duration(minutes: 10);

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      session.log('Starting action log sync...', level: LogLevel.info);

      // Get Supabase credentials from environment
      final supabaseUrl = session.serverpod.getPassword('SUPABASE_URL');
      final supabaseKey =
          session.serverpod.getPassword('SUPABASE_SERVICE_ROLE_KEY');

      if (supabaseUrl == null || supabaseKey == null) {
        session.log(
          'Supabase credentials not found in environment',
          level: LogLevel.error,
        );
        _scheduleNextSync(session);
        return;
      }

      // Fetch unsynced logs
      final unsyncedLogs = await _fetchUnsyncedLogs(session);

      if (unsyncedLogs.isEmpty) {
        session.log('No unsynced logs found', level: LogLevel.info);
        _scheduleNextSync(session);
        return;
      }

      session.log('Found ${unsyncedLogs.length} unsynced logs',
          level: LogLevel.info);

      // Push to Supabase
      final syncedIds = await _pushToSupabase(
        session,
        unsyncedLogs,
        supabaseUrl,
        supabaseKey,
      );

      // Mark as synced in local DB
      if (syncedIds.isNotEmpty) {
        await _markAsSynced(session, syncedIds);
        session.log(
          'Successfully synced ${syncedIds.length} action logs',
          level: LogLevel.info,
        );
      }
    } catch (e, stackTrace) {
      session.log(
        'Error during action log sync: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
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

  /// Pushes logs to Supabase
  Future<List<int>> _pushToSupabase(
    Session session,
    List<Map<String, dynamic>> logs,
    String supabaseUrl,
    String supabaseKey,
  ) async {
    final syncedIds = <int>[];

    try {
      final url = Uri.parse('$supabaseUrl/rest/v1/action_log');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(logs),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // All logs synced successfully
        syncedIds.addAll(logs.map((log) => log['id'] as int));
      } else {
        session.log(
          'Supabase sync failed: ${response.statusCode} - ${response.body}',
          level: LogLevel.warning,
        );
      }
    } catch (e) {
      session.log(
        'Error pushing to Supabase: $e',
        level: LogLevel.error,
      );
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
    Duration(minutes: 10),
  );

  print('✓ Action log sync task registered.');
}
