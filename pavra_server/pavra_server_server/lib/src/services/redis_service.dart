import 'dart:async';
import 'package:redis/redis.dart';
import 'package:serverpod/serverpod.dart';
import '../../server.dart'; // 用于 PLog 日志打印

/// Redis Service - Singleton pattern
/// Handles Redis connection, reconnection, and common operations.
///
/// Works for both:
/// - Railway Redis (with password)
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

  late RedisConnection _connection;
  late Command _command;
  bool _isConnected = false;

  final String host;
  final int port;
  final String? password;
  final Session? session;

  RedisService._({
    required this.host,
    required this.port,
    this.password,
    this.session,
  });

  /// Initialize Redis service once at server startup.
  static Future<void> initialize({
    required String host,
    required int port,
    String? password,
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
      session: session,
    );

    _instance = service;
    await service._connect();
  }

  /// Connect to Redis and authenticate if needed.
  Future<void> _connect() async {
    try {
      PLog.info('Connecting to Redis at $host:$port...');
      _connection = RedisConnection();
      _command = await _connection.connect(host, port);

      if (password != null && password!.isNotEmpty) {
        final authResult = await _command.send_object(['AUTH', password!]);
        PLog.info('Redis AUTH result: $authResult');
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
      final response = await _command.send_object(['PING']);
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
      await _command.send_object(['SET', key, value]);
      if (expireSeconds != null) {
        await _command.send_object(['EXPIRE', key, expireSeconds.toString()]);
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
      final result = await _command.send_object(['GET', key]);
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
      await _command.send_object(['DEL', key]);
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
      await _command.send_object(['LPUSH', key, value]);
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
      final result = await _command.send_object(['RPOP', key]);
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
      await _command.send_object(['LPUSH', key, logEntry.toString()]);
      await _command.send_object(['LTRIM', key, '0', '${maxLogs - 1}']);
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
          await _command.send_object(['LRANGE', key, '0', '${limit - 1}']);
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
      if (_isConnected) {
        await _connection.close();
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
