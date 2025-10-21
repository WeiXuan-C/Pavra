import 'package:serverpod/serverpod.dart';
import '../services/upstash_redis_service.dart';

/// Health check endpoint for Upstash Redis REST API connectivity.
/// Use this to verify Upstash Redis is working correctly.
class RedisHealthEndpoint extends Endpoint {
  /// Check if Upstash Redis is connected and working.
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
      // Test PING
      final pingResult = await UpstashRedisService.instance.ping();
      result['connected'] = pingResult;

      if (!result['connected']) {
        result['error'] = 'Upstash Redis PING failed';
        return result;
      }

      // Test write operation
      final testKey = 'health_check:${DateTime.now().millisecondsSinceEpoch}';
      final testValue = 'test_value';

      await UpstashRedisService.instance
          .set(testKey, testValue, expireSeconds: 10);
      result['writeTest'] = true;

      // Test read operation
      final readValue = await UpstashRedisService.instance.get(testKey);
      result['readTest'] = readValue == testValue;

      // Clean up
      await UpstashRedisService.instance.delete(testKey);

      session.log('Upstash Redis health check passed');
    } catch (e) {
      result['error'] = e.toString();
      session.log('Upstash Redis health check failed: $e',
          level: LogLevel.error);
    }

    return result;
  }

  /// Get Upstash Redis connection info (without sensitive data).
  Future<Map<String, dynamic>> info(Session session) async {
    return {
      'type': 'Upstash Redis REST API',
      'restUrl': UpstashRedisService.instance.restUrl,
      'hasToken': UpstashRedisService.instance.restToken.isNotEmpty,
    };
  }
}
