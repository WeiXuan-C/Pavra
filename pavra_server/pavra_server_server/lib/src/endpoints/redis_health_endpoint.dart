import 'package:serverpod/serverpod.dart';
import '../services/redis_service.dart';

/// Health check endpoint for Redis connectivity.
/// Use this to verify Redis is working correctly.
class RedisHealthEndpoint extends Endpoint {
  /// Check if Redis is connected and working.
  ///
  /// Returns a map with connection status and test results.
  ///
  /// Example call:
  /// ```dart
  /// final health = await client.redisHealth.check();
  /// print('Redis connected: ${health['connected']}');
  /// ```
  Future<Map<String, dynamic>> check(Session session) async {
    final result = <String, dynamic>{
      'connected': false,
      'writeTest': false,
      'readTest': false,
      'error': null,
    };

    try {
      // Check connection status
      result['connected'] = RedisService.instance.isConnected;

      if (!result['connected']) {
        result['error'] = 'Redis service not connected';
        return result;
      }

      // Test write operation
      final testKey = 'health_check:${DateTime.now().millisecondsSinceEpoch}';
      final testValue = 'test_value';

      await RedisService.instance.set(testKey, testValue, expireSeconds: 10);
      result['writeTest'] = true;

      // Test read operation
      final readValue = await RedisService.instance.get(testKey);
      result['readTest'] = readValue == testValue;

      // Clean up
      await RedisService.instance.delete(testKey);

      session.log('Redis health check passed');
    } catch (e) {
      result['error'] = e.toString();
      session.log('Redis health check failed: $e', level: LogLevel.error);
    }

    return result;
  }

  /// Get Redis connection info (without sensitive data).
  Future<Map<String, dynamic>> info(Session session) async {
    return {
      'connected': RedisService.instance.isConnected,
      'host': RedisService.instance.host,
      'port': RedisService.instance.port,
      'hasPassword': RedisService.instance.password != null &&
          RedisService.instance.password!.isNotEmpty,
    };
  }
}
