import 'dart:async';
import 'package:redis/redis.dart';
import 'package:serverpod/serverpod.dart';

/// Singleton Redis service for managing Redis connections and operations.
///
/// Usage:
/// ```dart
/// await RedisService.instance.addAction(userId: 123, action: 'login');
/// final logs = await RedisService.instance.getActions(userId: 123);
/// ```
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

  /// Initialize the Redis service with connection parameters.
  /// Should be called once during server startup.
  static Future<void> initialize({
    required String host,
    required int port,
    String? password,
    Session? session,
  }) async {
    if (_instance != null) {
      session?.log('RedisService already initialized', level: LogLevel.warning);
      return;
    }

    _instance = RedisService._(
      host: host,
      port: port,
      password: password,
      session: session,
    );

    await _instance!._connect();
  }

  /// Establish connection to Redis server.
  Future<void> _connect() async {
    try {
      session?.log('Connecting to Redis at $host:$port...');

      _connection = RedisConnection();
      _command = await _connection.connect(host, port);

      // Authenticate if password is provided
      if (password != null && password!.isNotEmpty) {
        final authResult = await _command.send_object(['AUTH', password!]);
        session?.log('Redis authentication: $authResult');
      }

      _isConnected = true;
      session?.log('Redis connected successfully', level: LogLevel.info);
    } catch (e, stackTrace) {
      _isConnected = false;
      session?.log(
        'Failed to connect to Redis: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Reconnect to Redis if connection is lost.
  Future<void> _ensureConnected() async {
    if (!_isConnected) {
      session?.log('Redis disconnected, attempting to reconnect...');
      await _connect();
    }
  }

  /// Add an action log for a user.
  /// Uses LPUSH to add to the beginning of the list and LTRIM to keep only the last [maxLogs] entries.
  ///
  /// Example:
  /// ```dart
  /// await RedisService.instance.addAction(
  ///   userId: 123,
  ///   action: 'user_login',
  ///   metadata: {'ip': '192.168.1.1', 'device': 'mobile'},
  /// );
  /// ```
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
      final value = logEntry.toString();

      // Add to the beginning of the list
      await _command.send_object(['LPUSH', key, value]);

      // Trim to keep only the last maxLogs entries
      await _command.send_object(['LTRIM', key, '0', '${maxLogs - 1}']);

      session?.log('Action logged for user $userId: $action');
    } catch (e, stackTrace) {
      _isConnected = false;
      session?.log(
        'Failed to add action log: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - logging failures shouldn't break the app
    }
  }

  /// Retrieve action logs for a user.
  /// Returns a list of action log entries, most recent first.
  ///
  /// Example:
  /// ```dart
  /// final logs = await RedisService.instance.getActions(userId: 123, limit: 50);
  /// ```
  Future<List<String>> getActions({
    required int userId,
    int limit = 100,
  }) async {
    try {
      await _ensureConnected();

      final key = 'user:$userId:actions';

      // Get the range of logs (0 to limit-1)
      final result =
          await _command.send_object(['LRANGE', key, '0', '${limit - 1}']);

      if (result is List) {
        return result.map((e) => e.toString()).toList();
      }

      return [];
    } catch (e, stackTrace) {
      _isConnected = false;
      session?.log(
        'Failed to retrieve action logs: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Set a key-value pair in Redis with optional expiration.
  ///
  /// Example:
  /// ```dart
  /// await RedisService.instance.set('session:abc123', 'user_data', expireSeconds: 3600);
  /// ```
  Future<void> set(String key, String value, {int? expireSeconds}) async {
    try {
      await _ensureConnected();

      await _command.send_object(['SET', key, value]);

      if (expireSeconds != null) {
        await _command.send_object(['EXPIRE', key, expireSeconds.toString()]);
      }
    } catch (e, stackTrace) {
      _isConnected = false;
      session?.log(
        'Failed to set key: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get a value from Redis by key.
  ///
  /// Example:
  /// ```dart
  /// final value = await RedisService.instance.get('session:abc123');
  /// ```
  Future<String?> get(String key) async {
    try {
      await _ensureConnected();

      final result = await _command.send_object(['GET', key]);
      return result?.toString();
    } catch (e, stackTrace) {
      _isConnected = false;
      session?.log(
        'Failed to get key: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Delete a key from Redis.
  Future<void> delete(String key) async {
    try {
      await _ensureConnected();
      await _command.send_object(['DEL', key]);
    } catch (e, stackTrace) {
      _isConnected = false;
      session?.log(
        'Failed to delete key: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if Redis is connected.
  bool get isConnected => _isConnected;

  /// Close the Redis connection.
  /// Should be called during server shutdown.
  Future<void> close() async {
    try {
      if (_isConnected) {
        await _connection.close();
        _isConnected = false;
        session?.log('Redis connection closed');
      }
    } catch (e) {
      session?.log('Error closing Redis connection: $e', level: LogLevel.error);
    }
  }

  /// Dispose the singleton instance (mainly for testing).
  static void dispose() {
    _instance = null;
  }
}
