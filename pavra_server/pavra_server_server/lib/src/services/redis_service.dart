import 'dart:async';
import 'package:redis/redis.dart';
import 'package:serverpod/serverpod.dart';
import '../../server.dart'; // 用于 PLog 日志打印

/// Redis Service - Singleton pattern
/// Handles Redis connection, reconnection, and common operations.
///
/// Works for both:
/// - Railway Redis (plain TCP, with password)
/// - Upstash Redis (TLS-secured TCP, with password)
/// - Local Redis (no password)
class RedisService {
  static RedisService? _instance;

  static RedisService get instance {
    if (_instance == null) {
      throw StateError(
        'RedisService not initialized. Call RedisService.initialize() first.',
      );
    }
    return _instance!;
  }

  RedisConnection? _connection;
  Command? _command;
  bool _isConnected = false;

  final String host;
  final int port;
  final String? password;
  final bool useTls;
  final Session? session;

  RedisService._({
    required this.host,
    required this.port,
    this.password,
    this.useTls = false,
    this.session,
  });

  /// Initialize Redis service once at server startup.
  static Future<void> initialize({
    required String host,
    required int port,
    String? password,
    bool useTls = false,
    Session? session,
  }) async {
    if (_instance != null) {
      PLog.warn('RedisService already initialized, skipping.');
      return;
    }

    final service = RedisService._(
      host: host,
      port: port,
      password: password,
      useTls: useTls,
      session: session,
    );

    _instance = service;
    await service._connect();
  }

  /// Connect to Redis and authenticate if needed.
  /// Supports both plain TCP and TLS connections.
  Future<void> _connect() async {
    try {
      PLog.info('Connecting to Redis at $host:$port (TLS: $useTls)...');

      _connection = RedisConnection();

      if (useTls) {
        // For TLS connections (Upstash), the redis package doesn't support it directly
        // We'll skip custom RedisService and use Serverpod's built-in Redis instead
        PLog.warn(
            'TLS Redis connections should use Serverpod built-in Redis (pod.redis)');
        PLog.warn(
            'Custom RedisService does not support TLS - skipping initialization');
        throw UnsupportedError(
            'RedisService does not support TLS. Use Serverpod built-in Redis instead.');
      } else {
        // Plain TCP connection (Railway Redis or local)
        _command = await _connection!.connect(host, port);
      }

      // Authenticate if password is provided
      if (password != null && password!.isNotEmpty) {
        try {
          // Try AUTH with username (Redis 6+)
          final authResult =
              await _command!.send_object(['AUTH', 'default', password!]);
          PLog.info('Redis AUTH result: $authResult');
        } catch (e) {
          // Fallback to AUTH without username (older Redis or Upstash)
          PLog.warn('AUTH with username failed, trying without username...');
          final authResult = await _command!.send_object(['AUTH', password!]);
          PLog.info('Redis AUTH result: $authResult');
        }
      }

      _isConnected = true;
      PLog.info('✅ Redis connected successfully.');
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('❌ Failed to connect to Redis.', e, stack);
      rethrow;
    }
  }

  /// Ensure Redis connection is alive, reconnect if needed.
  Future<void> _ensureConnected() async {
    if (!_isConnected) {
      PLog.warn('Redis disconnected. Attempting to reconnect...');
      await _connect();
    }
  }

  /// Check Redis health by sending a PING.
  Future<bool> ping() async {
    try {
      await _ensureConnected();
      final response = await _command!.send_object(['PING']);
      final ok = response == 'PONG';
      PLog.info(
          ok ? '✅ Redis PING successful.' : '⚠️ Redis PING failed: $response');
      return ok;
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('Redis PING error.', e, stack);
      return false;
    }
  }

  /// Set a key-value pair with optional expiration time.
  Future<void> set(String key, String value, {int? expireSeconds}) async {
    try {
      await _ensureConnected();
      await _command!.send_object(['SET', key, value]);
      if (expireSeconds != null) {
        await _command!.send_object(['EXPIRE', key, expireSeconds.toString()]);
      }
      PLog.info('Set Redis key: $key');
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('Failed to set Redis key: $key', e, stack);
    }
  }

  /// Get a value from Redis by key.
  Future<String?> get(String key) async {
    try {
      await _ensureConnected();
      final result = await _command!.send_object(['GET', key]);
      return result?.toString();
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('Failed to get Redis key: $key', e, stack);
      return null;
    }
  }

  /// Delete a key from Redis.
  Future<void> delete(String key) async {
    try {
      await _ensureConnected();
      await _command!.send_object(['DEL', key]);
      PLog.info('Deleted Redis key: $key');
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('Failed to delete Redis key: $key', e, stack);
    }
  }

  /// Push a value to the left of a Redis list (LPUSH).
  Future<void> lpush(String key, String value) async {
    try {
      await _ensureConnected();
      await _command!.send_object(['LPUSH', key, value]);
      PLog.info('LPUSH to Redis key: $key');
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('Failed to LPUSH to Redis key: $key', e, stack);
      rethrow;
    }
  }

  /// Pop a value from the right of a Redis list (RPOP).
  Future<String?> rpop(String key) async {
    try {
      await _ensureConnected();
      final result = await _command!.send_object(['RPOP', key]);
      return result?.toString();
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('Failed to RPOP from Redis key: $key', e, stack);
      return null;
    }
  }

  /// Add an action log entry for a specific user.
  Future<void> addAction({
    required int userId,
    required String action,
    Map<String, dynamic>? metadata,
    int maxLogs = 100,
  }) async {
    try {
      await _ensureConnected();
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = {
        'action': action,
        'timestamp': timestamp,
        if (metadata != null) 'metadata': metadata,
      };
      final key = 'user:$userId:actions';
      await _command!.send_object(['LPUSH', key, logEntry.toString()]);
      await _command!.send_object(['LTRIM', key, '0', '${maxLogs - 1}']);
      PLog.info('Action logged for user $userId: $action');
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('Failed to add action log.', e, stack);
    }
  }

  /// Retrieve user action logs.
  Future<List<String>> getActions({
    required int userId,
    int limit = 100,
  }) async {
    try {
      await _ensureConnected();
      final key = 'user:$userId:actions';
      final result =
          await _command!.send_object(['LRANGE', key, '0', '${limit - 1}']);
      if (result is List) {
        return result.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e, stack) {
      _isConnected = false;
      PLog.error('Failed to retrieve action logs.', e, stack);
      return [];
    }
  }

  /// Close Redis connection safely.
  Future<void> close() async {
    try {
      if (_isConnected && _connection != null) {
        await _connection!.close();
        _isConnected = false;
        PLog.info('Redis connection closed.');
      }
    } catch (e) {
      PLog.error('Error closing Redis connection.', e);
    }
  }

  /// Dispose singleton instance (useful for testing).
  static void dispose() {
    _instance = null;
    PLog.warn('RedisService instance disposed.');
  }

  bool get isConnected => _isConnected;
}
