import 'package:serverpod/serverpod.dart';
import '../services/redis_service.dart';

/// Example endpoint demonstrating Redis action logging.
///
/// Endpoints:
/// - logAction: Log a user action
/// - getUserActions: Retrieve user action logs
class UserActionsEndpoint extends Endpoint {
  /// Log a user action to Redis.
  ///
  /// Example call:
  /// ```dart
  /// await client.userActions.logAction(
  ///   userId: 123,
  ///   action: 'viewed_profile',
  ///   metadata: {'profileId': '456'},
  /// );
  /// ```
  Future<bool> logAction(
    Session session,
    int userId,
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await RedisService.instance.addAction(
        userId: userId,
        action: action,
        metadata: metadata,
      );

      session.log('Action logged: $action for user $userId');
      return true;
    } catch (e) {
      session.log('Failed to log action: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Retrieve action logs for a user.
  ///
  /// Example call:
  /// ```dart
  /// final logs = await client.userActions.getUserActions(userId: 123, limit: 50);
  /// ```
  Future<List<String>> getUserActions(
    Session session,
    int userId, {
    int limit = 100,
  }) async {
    try {
      final logs = await RedisService.instance.getActions(
        userId: userId,
        limit: limit,
      );

      session.log('Retrieved ${logs.length} actions for user $userId');
      return logs;
    } catch (e) {
      session.log('Failed to retrieve actions: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Example: Log multiple actions at once (batch operation).
  Future<int> logBatchActions(
    Session session,
    int userId,
    List<String> actions,
  ) async {
    int successCount = 0;

    for (final action in actions) {
      try {
        await RedisService.instance.addAction(
          userId: userId,
          action: action,
        );
        successCount++;
      } catch (e) {
        session.log('Failed to log action $action: $e', level: LogLevel.error);
      }
    }

    return successCount;
  }

  /// Clear all action logs for a user.
  Future<bool> clearUserActions(Session session, int userId) async {
    try {
      final key = 'user:$userId:actions';
      await RedisService.instance.delete(key);
      session.log('Cleared actions for user $userId');
      return true;
    } catch (e) {
      session.log('Failed to clear actions: $e', level: LogLevel.error);
      return false;
    }
  }
}
