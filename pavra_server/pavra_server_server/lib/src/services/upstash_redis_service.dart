import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../server.dart';

/// Upstash Redis REST API Service
/// Uses HTTP REST API instead of TCP connection for better compatibility with serverless/cloud deployments
class UpstashRedisService {
  static UpstashRedisService? _instance;

  static UpstashRedisService? get instance => _instance;

  static bool get isInitialized => _instance != null;

  final String restUrl;
  final String restToken;

  UpstashRedisService._({
    required this.restUrl,
    required this.restToken,
  });

  /// Initialize Upstash Redis service with REST API credentials
  static void initialize({
    required String restUrl,
    required String restToken,
  }) {
    if (_instance != null) {
      PLog.warn('UpstashRedisService already initialized, skipping.');
      return;
    }

    _instance = UpstashRedisService._(
      restUrl: restUrl,
      restToken: restToken,
    );

    PLog.info('✅ UpstashRedisService initialized with REST API');
  }

  /// Execute a Redis command via REST API
  Future<dynamic> _executeCommand(List<dynamic> command) async {
    try {
      final response = await http.post(
        Uri.parse(restUrl),
        headers: {
          'Authorization': 'Bearer $restToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(command),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['result'];
      } else {
        PLog.error(
          'Upstash REST API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e, stack) {
      PLog.error('Failed to execute Upstash command: $command', e, stack);
      return null;
    }
  }

  /// Check Redis health by sending a PING
  Future<bool> ping() async {
    try {
      final result = await _executeCommand(['PING']);
      final ok = result == 'PONG';
      PLog.info(ok
          ? '✅ Upstash Redis PING successful.'
          : '⚠️ Upstash Redis PING failed: $result');
      return ok;
    } catch (e, stack) {
      PLog.error('Upstash Redis PING error.', e, stack);
      return false;
    }
  }

  /// Set a key-value pair with optional expiration time
  Future<void> set(String key, String value, {int? expireSeconds}) async {
    try {
      await _executeCommand(['SET', key, value]);
      if (expireSeconds != null) {
        await _executeCommand(['EXPIRE', key, expireSeconds]);
      }
      PLog.info('Set Upstash Redis key: $key');
    } catch (e, stack) {
      PLog.error('Failed to set Upstash Redis key: $key', e, stack);
    }
  }

  /// Get a value from Redis by key
  Future<String?> get(String key) async {
    try {
      final result = await _executeCommand(['GET', key]);
      return result?.toString();
    } catch (e, stack) {
      PLog.error('Failed to get Upstash Redis key: $key', e, stack);
      return null;
    }
  }

  /// Delete a key from Redis
  Future<void> delete(String key) async {
    try {
      await _executeCommand(['DEL', key]);
      PLog.info('Deleted Upstash Redis key: $key');
    } catch (e, stack) {
      PLog.error('Failed to delete Upstash Redis key: $key', e, stack);
    }
  }

  /// Push a value to the left of a Redis list (LPUSH)
  Future<void> lpush(String key, String value) async {
    try {
      await _executeCommand(['LPUSH', key, value]);
      PLog.info('LPUSH to Upstash Redis key: $key');
    } catch (e, stack) {
      PLog.error('Failed to LPUSH to Upstash Redis key: $key', e, stack);
      rethrow;
    }
  }

  /// Pop a value from the right of a Redis list (RPOP)
  Future<String?> rpop(String key) async {
    try {
      final result = await _executeCommand(['RPOP', key]);
      return result?.toString();
    } catch (e, stack) {
      PLog.error('Failed to RPOP from Upstash Redis key: $key', e, stack);
      return null;
    }
  }

  /// Get the length of a Redis list
  Future<int> llen(String key) async {
    try {
      final result = await _executeCommand(['LLEN', key]);
      return result is int ? result : 0;
    } catch (e, stack) {
      PLog.error('Failed to LLEN from Upstash Redis key: $key', e, stack);
      return 0;
    }
  }

  /// Dispose singleton instance (useful for testing)
  static void dispose() {
    _instance = null;
    PLog.warn('UpstashRedisService instance disposed.');
  }
}
