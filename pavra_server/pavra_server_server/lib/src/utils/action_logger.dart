import 'dart:convert';
import 'package:serverpod/serverpod.dart';

class ActionLogger {
  /// Logs user actions to the database
  static Future<void> log(
    Session session, {
    required String userId,
    required String actionType,
    String? targetId,
    String? targetTable,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    // Escape single quotes to prevent SQL injection
    final safeActionType = actionType.replaceAll("'", "''");
    final safeTargetTable = targetTable?.replaceAll("'", "''");
    final safeDescription = description?.replaceAll("'", "''");
    final metadataJson = jsonEncode(metadata ?? {}).replaceAll("'", "''");

    await session.db.unsafeQuery(
      "INSERT INTO action_log (user_id, action_type, target_id, target_table, description, metadata) "
      "VALUES ('$userId'::uuid, '$safeActionType', ${targetId != null ? "'$targetId'::uuid" : 'NULL'}, "
      "${safeTargetTable != null ? "'$safeTargetTable'" : 'NULL'}, ${safeDescription != null ? "'$safeDescription'" : 'NULL'}, "
      "'$metadataJson'::jsonb)",
    );

    // Optional: Log to Serverpod's built-in logging
    session.log('Action: $actionType by user $userId', level: LogLevel.info);
  }

  /// Retrieves action logs from database
  static Future<List<Map<String, dynamic>>> getRecentActions(
    Session session,
    String userId, {
    int limit = 20,
  }) async {
    final result = await session.db.unsafeQuery(
      "SELECT action_type, target_id, target_table, description, metadata, created_at "
      "FROM action_log "
      "WHERE user_id = '$userId'::uuid "
      "ORDER BY created_at DESC "
      "LIMIT $limit",
    );

    return result
        .map((row) => {
              'actionType': row[0],
              'targetId': row[1],
              'targetTable': row[2],
              'description': row[3],
              'metadata': row[4],
              'createdAt': row[5],
            })
        .toList();
  }
}
