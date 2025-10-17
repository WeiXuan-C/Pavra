import 'package:serverpod/serverpod.dart';
import '../services/action_log_service.dart';

/// Authentication Endpoint - Handles user sign in/sign up with action logging
///
/// This endpoint demonstrates:
/// - User sign in with action logging
/// - User sign up with action logging
/// - Testing Redis and Supabase connections
class AuthEndpoint extends Endpoint {
  final ActionLogService _actionLogService = ActionLogService();

  /// Test endpoint to simulate user sign in
  ///
  /// This will log the sign-in action to Redis → Supabase
  ///
  /// Example:
  /// ```dart
  /// await client.auth.signIn(
  ///   userId: 'user-123',
  ///   email: 'test@example.com',
  /// );
  /// ```
  Future<Map<String, dynamic>> signIn(
    Session session, {
    required String userId,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Log the sign-in action
      await _actionLogService.logAction(
        userId: userId,
        action: 'user_sign_in',
        description: 'User signed in: $email',
        metadata: {
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );

      session.log('✅ User signed in: $email (userId: $userId)');

      return {
        'success': true,
        'message': 'Sign in successful',
        'userId': userId,
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      session.log('❌ Sign in failed: $e', level: LogLevel.error);
      return {
        'success': false,
        'message': 'Sign in failed: $e',
      };
    }
  }

  /// Test endpoint to simulate user sign up
  ///
  /// This will log the sign-up action to Redis → Supabase
  ///
  /// Example:
  /// ```dart
  /// await client.auth.signUp(
  ///   userId: 'user-456',
  ///   email: 'newuser@example.com',
  ///   username: 'newuser',
  /// );
  /// ```
  Future<Map<String, dynamic>> signUp(
    Session session, {
    required String userId,
    required String email,
    String? username,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Log the sign-up action
      await _actionLogService.logAction(
        userId: userId,
        action: 'user_sign_up',
        description: 'New user registered: $email',
        metadata: {
          'email': email,
          'username': username,
          'registration_source': 'web',
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );

      session.log('✅ User signed up: $email (userId: $userId)');

      return {
        'success': true,
        'message': 'Sign up successful',
        'userId': userId,
        'email': email,
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      session.log('❌ Sign up failed: $e', level: LogLevel.error);
      return {
        'success': false,
        'message': 'Sign up failed: $e',
      };
    }
  }

  /// Test endpoint to simulate user sign out
  Future<Map<String, dynamic>> signOut(
    Session session, {
    required String userId,
    String? email,
  }) async {
    try {
      await _actionLogService.logAction(
        userId: userId,
        action: 'user_sign_out',
        description: 'User signed out${email != null ? ': $email' : ''}',
        metadata: {
          if (email != null) 'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      session.log('✅ User signed out: $userId');

      return {
        'success': true,
        'message': 'Sign out successful',
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      session.log('❌ Sign out failed: $e', level: LogLevel.error);
      return {
        'success': false,
        'message': 'Sign out failed: $e',
      };
    }
  }

  /// Quick test to verify Redis and Supabase connections
  ///
  /// This will:
  /// 1. Log a test action to Redis
  /// 2. Check Redis health
  /// 3. Check Supabase health
  /// 4. Return connection status
  Future<Map<String, dynamic>> testConnections(Session session) async {
    try {
      final health = await _actionLogService.healthCheck();

      // Try to log a test action
      await _actionLogService.logAction(
        userId: 'test-user',
        action: 'connection_test',
        description: 'Testing Redis and Supabase connections',
        metadata: {
          'test_timestamp': DateTime.now().toIso8601String(),
        },
      );

      session.log('✅ Connection test completed');

      return {
        'success': true,
        'redis_connected': health['redis'] ?? false,
        'supabase_connected': health['supabase'] ?? false,
        'test_action_logged': true,
        'message': 'Connection test successful',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      session.log('❌ Connection test failed: $e', level: LogLevel.error);
      return {
        'success': false,
        'message': 'Connection test failed: $e',
      };
    }
  }
}
