/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:pavra_server_client/src/protocol/greeting.dart' as _i3;
import 'protocol.dart' as _i4;

/// Endpoint for logging user actions to Upstash Redis → Supabase
///
/// This endpoint handles:
/// - Logging actions to Upstash Redis queue (instant)
/// - Retrieving action history from Supabase
/// - Manual flush of Upstash Redis queue to Supabase
/// - Health checks for Upstash Redis and Supabase
/// {@category Endpoint}
class EndpointActionLog extends _i1.EndpointRef {
  EndpointActionLog(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'actionLog';

  /// Log a user action to Upstash Redis queue
  ///
  /// Actions are queued in Upstash Redis and automatically synced to Supabase every minute.
  ///
  /// Example:
  /// ```dart
  /// await client.actionLog.log(
  ///   userId: 'user-123',
  ///   action: 'profile_viewed',
  ///   targetId: 'profile-456',
  ///   description: 'User viewed another profile',
  /// );
  /// ```
  _i2.Future<bool> log({
    required String userId,
    required String action,
    String? targetId,
    String? targetTable,
    String? description,
    Map<String, dynamic>? metadata,
  }) =>
      caller.callServerEndpoint<bool>(
        'actionLog',
        'log',
        {
          'userId': userId,
          'action': action,
          'targetId': targetId,
          'targetTable': targetTable,
          'description': description,
          'metadata': metadata,
        },
      );

  /// Get recent actions for a user from Supabase
  _i2.Future<List<Map<String, dynamic>>> getUserActions(
    String userId, {
    required int limit,
  }) =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'actionLog',
        'getUserActions',
        {
          'userId': userId,
          'limit': limit,
        },
      );

  /// Manually trigger flush of Upstash Redis logs to Supabase
  _i2.Future<int> flushLogs({required int batchSize}) =>
      caller.callServerEndpoint<int>(
        'actionLog',
        'flushLogs',
        {'batchSize': batchSize},
      );

  /// Health check for Upstash Redis and Supabase
  _i2.Future<Map<String, bool>> healthCheck() =>
      caller.callServerEndpoint<Map<String, bool>>(
        'actionLog',
        'healthCheck',
        {},
      );
}

/// Authentication Endpoint - Handles user sign in/sign up with action logging
///
/// This endpoint demonstrates:
/// - User sign in with action logging
/// - User sign up with action logging
/// - Testing Redis and Supabase connections
/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

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
  _i2.Future<Map<String, dynamic>> signIn({
    required String userId,
    required String email,
    Map<String, dynamic>? metadata,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'signIn',
        {
          'userId': userId,
          'email': email,
          'metadata': metadata,
        },
      );

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
  _i2.Future<Map<String, dynamic>> signUp({
    required String userId,
    required String email,
    String? username,
    Map<String, dynamic>? metadata,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'signUp',
        {
          'userId': userId,
          'email': email,
          'username': username,
          'metadata': metadata,
        },
      );

  /// Test endpoint to simulate user sign out
  _i2.Future<Map<String, dynamic>> signOut({
    required String userId,
    String? email,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'signOut',
        {
          'userId': userId,
          'email': email,
        },
      );

  /// Quick test to verify Redis and Supabase connections
  ///
  /// This will:
  /// 1. Log a test action to Redis
  /// 2. Check Redis health
  /// 3. Check Supabase health
  /// 4. Return connection status
  _i2.Future<Map<String, dynamic>> testConnections() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'testConnections',
        {},
      );
}

/// Endpoint for notification operations
///
/// Handles sending push notifications via OneSignal
/// and managing notification records in Supabase
/// Supports scheduled notifications via Upstash Redis
/// {@category Endpoint}
class EndpointNotification extends _i1.EndpointRef {
  EndpointNotification(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  /// Send notification to a specific user
  ///
  /// Creates notification record in Supabase and sends push via OneSignal
  _i2.Future<Map<String, dynamic>> sendToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedAction,
    Map<String, dynamic>? data,
    String? createdBy,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'sendToUser',
        {
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
          'relatedAction': relatedAction,
          'data': data,
          'createdBy': createdBy,
        },
      );

  /// Send notification to multiple users
  _i2.Future<Map<String, dynamic>> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    String? relatedAction,
    Map<String, dynamic>? data,
    String? createdBy,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'sendToUsers',
        {
          'userIds': userIds,
          'title': title,
          'message': message,
          'type': type,
          'relatedAction': relatedAction,
          'data': data,
          'createdBy': createdBy,
        },
      );

  /// Send notification to all users (broadcast)
  ///
  /// Use with caution - sends to ALL users
  /// Requires admin or developer role
  _i2.Future<Map<String, dynamic>> sendToAll({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    String? createdBy,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'sendToAll',
        {
          'title': title,
          'message': message,
          'type': type,
          'data': data,
          'createdBy': createdBy,
        },
      );

  /// Send app update notification
  ///
  /// Convenience method for sending app update notifications
  _i2.Future<Map<String, dynamic>> sendAppUpdateNotification({
    required String version,
    required String updateMessage,
    required bool isRequired,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'sendAppUpdateNotification',
        {
          'version': version,
          'updateMessage': updateMessage,
          'isRequired': isRequired,
        },
      );

  /// Send new feature announcement
  _i2.Future<Map<String, dynamic>> sendFeatureAnnouncement({
    required String featureName,
    required String description,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'sendFeatureAnnouncement',
        {
          'featureName': featureName,
          'description': description,
        },
      );

  /// Send activity notification
  _i2.Future<Map<String, dynamic>> sendActivityNotification({
    required String userId,
    required String activityTitle,
    required String activityMessage,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'sendActivityNotification',
        {
          'userId': userId,
          'activityTitle': activityTitle,
          'activityMessage': activityMessage,
        },
      );

  /// Schedule an existing notification by ID
  ///
  /// This is called from Flutter client after notification is created
  /// Schedules the notification via QStash for processing and stores job ID for cancellation
  _i2.Future<Map<String, dynamic>> scheduleNotificationById({
    required String notificationId,
    required DateTime scheduledAt,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'scheduleNotificationById',
        {
          'notificationId': notificationId,
          'scheduledAt': scheduledAt,
        },
      );

  /// Schedule a notification to be sent at a specific time
  ///
  /// Creates notification record in Supabase with 'scheduled' status
  /// and schedules via QStash for processing
  _i2.Future<Map<String, dynamic>> scheduleNotification({
    required String title,
    required String message,
    required DateTime scheduledAt,
    required String type,
    String? relatedAction,
    Map<String, dynamic>? data,
    required String targetType,
    List<String>? targetRoles,
    List<String>? targetUserIds,
    String? createdBy,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'scheduleNotification',
        {
          'title': title,
          'message': message,
          'scheduledAt': scheduledAt,
          'type': type,
          'relatedAction': relatedAction,
          'data': data,
          'targetType': targetType,
          'targetRoles': targetRoles,
          'targetUserIds': targetUserIds,
          'createdBy': createdBy,
        },
      );

  /// Schedule notification for multiple users
  _i2.Future<Map<String, dynamic>> scheduleNotificationForUsers({
    required List<String> userIds,
    required String title,
    required String message,
    required DateTime scheduledAt,
    required String type,
    String? relatedAction,
    Map<String, dynamic>? data,
    String? createdBy,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'scheduleNotificationForUsers',
        {
          'userIds': userIds,
          'title': title,
          'message': message,
          'scheduledAt': scheduledAt,
          'type': type,
          'relatedAction': relatedAction,
          'data': data,
          'createdBy': createdBy,
        },
      );

  /// Cancel a scheduled notification
  _i2.Future<Map<String, dynamic>> cancelScheduledNotification({
    required String notificationId,
    required String userId,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'cancelScheduledNotification',
        {
          'notificationId': notificationId,
          'userId': userId,
        },
      );

  /// Handle notification created from Flutter client
  ///
  /// This is called when a notification is created via the Flutter app
  /// It sends the push notification based on target_type with enhanced OneSignal fields
  _i2.Future<Map<String, dynamic>> handleNotificationCreated(
          {required String notificationId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'handleNotificationCreated',
        {'notificationId': notificationId},
      );

  /// Handle scheduled notification webhook from QStash
  ///
  /// This is called by QStash when a scheduled notification is due
  /// Processes the notification by updating status and sending via OneSignal
  _i2.Future<Map<String, dynamic>> handleScheduledNotification(
          {required String notificationId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'handleScheduledNotification',
        {'notificationId': notificationId},
      );

  /// Update notification status with OneSignal ID and delivery statistics
  ///
  /// This endpoint allows updating notification status, OneSignal notification ID,
  /// error messages, and delivery statistics
  /// This is typically called by system processes, not directly by users
  _i2.Future<Map<String, dynamic>> updateNotificationStatus({
    required String notificationId,
    String? status,
    String? oneSignalNotificationId,
    String? errorMessage,
    int? recipientsCount,
    int? successfulDeliveries,
    int? failedDeliveries,
    String? userId,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'updateNotificationStatus',
        {
          'notificationId': notificationId,
          'status': status,
          'oneSignalNotificationId': oneSignalNotificationId,
          'errorMessage': errorMessage,
          'recipientsCount': recipientsCount,
          'successfulDeliveries': successfulDeliveries,
          'failedDeliveries': failedDeliveries,
          'userId': userId,
        },
      );

  /// Get notification status and delivery statistics
  ///
  /// Retrieves current notification status from database and optionally
  /// fetches latest delivery statistics from OneSignal
  _i2.Future<Map<String, dynamic>> getNotificationStatus({
    required String notificationId,
    required bool fetchFromOneSignal,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'getNotificationStatus',
        {
          'notificationId': notificationId,
          'fetchFromOneSignal': fetchFromOneSignal,
        },
      );

  /// 🧪 手动触发 scheduled notification 处理（仅用于开发测试）
  ///
  /// 这个方法模拟 QStash webhook 的行为，用于本地测试
  /// 可以手动触发任何 scheduled notification 的处理
  _i2.Future<Map<String, dynamic>> testProcessScheduledNotification(
          {required String notificationId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'testProcessScheduledNotification',
        {'notificationId': notificationId},
      );

  /// Process scheduled notifications (called by cron job or task)
  ///
  /// This should be called periodically to check for and send scheduled notifications
  _i2.Future<Map<String, dynamic>> processScheduledNotifications() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'processScheduledNotifications',
        {},
      );

  /// Cancel a QStash scheduled job
  ///
  /// This is called from Flutter client when updating a scheduled notification
  /// to cancel the previous QStash job before creating a new one
  _i2.Future<Map<String, dynamic>> cancelQStashJob(
          {required String qstashMessageId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'cancelQStashJob',
        {'qstashMessageId': qstashMessageId},
      );

  /// Hard delete a notification (permanent deletion with cascade)
  ///
  /// This permanently deletes the notification and all associated user_notification records.
  /// Requires admin permission check.
  /// Use with extreme caution - this action cannot be undone.
  _i2.Future<Map<String, dynamic>> hardDeleteNotification({
    required String notificationId,
    required String userId,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'hardDeleteNotification',
        {
          'notificationId': notificationId,
          'userId': userId,
        },
      );

  /// Check notification system health
  ///
  /// Performs comprehensive health check and returns status
  /// Also triggers alerts if issues are detected
  _i2.Future<Map<String, dynamic>> checkSystemHealth() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'checkSystemHealth',
        {},
      );

  /// Get recent alerts for dashboard
  ///
  /// Returns list of recent alert notifications
  _i2.Future<Map<String, dynamic>> getRecentAlerts({required int limit}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'getRecentAlerts',
        {'limit': limit},
      );

  /// Get API usage statistics for a user
  ///
  /// Returns rate limit information and usage statistics
  _i2.Future<Map<String, dynamic>> getApiUsageStats({required String userId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'getApiUsageStats',
        {'userId': userId},
      );

  /// Get notification metrics summary for dashboard
  ///
  /// Returns aggregated metrics including success rates, delivery times,
  /// and user engagement metrics for the specified time period
  _i2.Future<Map<String, dynamic>> getMetricsSummary({required int daysBack}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'getMetricsSummary',
        {'daysBack': daysBack},
      );

  /// Get metrics for a specific notification
  ///
  /// Returns detailed metrics including delivery stats and engagement metrics
  _i2.Future<Map<String, dynamic>> getNotificationMetrics(
          {required String notificationId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'getNotificationMetrics',
        {'notificationId': notificationId},
      );

  /// Send system maintenance notification to all users
  ///
  /// Creates a notification for system maintenance events
  /// Sends to all users with target_type='all'
  /// Requires admin permission
  _i2.Future<Map<String, dynamic>> sendMaintenanceNotification({
    required String title,
    required String message,
    DateTime? scheduledAt,
    String? createdBy,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'notification',
        'sendMaintenanceNotification',
        {
          'title': title,
          'message': message,
          'scheduledAt': scheduledAt,
          'createdBy': createdBy,
        },
      );
}

/// OpenRouter AI endpoint for chat completions
/// {@category Endpoint}
class EndpointOpenRouter extends _i1.EndpointRef {
  EndpointOpenRouter(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'openRouter';

  /// Send a chat completion request to OpenRouter
  ///
  /// [prompt] - The user's message/prompt
  /// [model] - The AI model to use (default: nvidia/nemotron-nano-12b-v2-vl:free)
  /// [maxTokens] - Maximum tokens in response (default: 1000)
  /// [temperature] - Sampling temperature 0-2 (default: 0.7)
  _i2.Future<Map<String, dynamic>> chat(
    String prompt, {
    String? model,
    int? maxTokens,
    double? temperature,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'openRouter',
        'chat',
        {
          'prompt': prompt,
          'model': model,
          'maxTokens': maxTokens,
          'temperature': temperature,
        },
      );

  /// Send a chat completion with conversation history
  ///
  /// [messages] - List of message maps with 'role' and 'content' keys
  /// [model] - The AI model to use
  /// [maxTokens] - Maximum tokens in response
  /// [temperature] - Sampling temperature 0-2
  _i2.Future<Map<String, dynamic>> chatWithHistory(
    List<Map<String, dynamic>> messages, {
    String? model,
    int? maxTokens,
    double? temperature,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'openRouter',
        'chatWithHistory',
        {
          'messages': messages,
          'model': model,
          'maxTokens': maxTokens,
          'temperature': temperature,
        },
      );

  /// Send a chat completion with vision (image analysis)
  ///
  /// [textPrompt] - The text prompt/question about the image
  /// [imageUrl] - Public URL of the image to analyze
  /// [model] - The AI model to use (must support vision)
  /// [maxTokens] - Maximum tokens in response
  /// [temperature] - Sampling temperature 0-2
  _i2.Future<Map<String, dynamic>> chatWithVision(
    String textPrompt,
    String imageUrl, {
    String? model,
    int? maxTokens,
    double? temperature,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'openRouter',
        'chatWithVision',
        {
          'textPrompt': textPrompt,
          'imageUrl': imageUrl,
          'model': model,
          'maxTokens': maxTokens,
          'temperature': temperature,
        },
      );

  /// Get available models from OpenRouter
  _i2.Future<Map<String, dynamic>> getModels() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'openRouter',
        'getModels',
        {},
      );
}

/// Endpoint for receiving QStash webhook callbacks
/// {@category Endpoint}
class EndpointQstashWebhook extends _i1.EndpointRef {
  EndpointQstashWebhook(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'qstashWebhook';

  /// Handle scheduled notification callback from QStash
  _i2.Future<Map<String, dynamic>> processScheduledNotification(
          Map<String, dynamic> payload) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'qstashWebhook',
        'processScheduledNotification',
        {'payload': payload},
      );
}

/// Health check endpoint for Upstash Redis REST API connectivity.
/// Use this to verify Upstash Redis is working correctly.
/// {@category Endpoint}
class EndpointRedisHealth extends _i1.EndpointRef {
  EndpointRedisHealth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'redisHealth';

  /// Check if Upstash Redis is connected and working.
  ///
  /// Returns a map with connection status and test results.
  ///
  /// Example call:
  /// ```dart
  /// final health = await client.redisHealth.check();
  /// print('Redis connected: ${health['connected']}');
  /// ```
  _i2.Future<Map<String, dynamic>> check() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'redisHealth',
        'check',
        {},
      );

  /// Get Upstash Redis connection info (without sensitive data).
  _i2.Future<Map<String, dynamic>> info() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'redisHealth',
        'info',
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i3.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i3.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i4.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    actionLog = EndpointActionLog(this);
    auth = EndpointAuth(this);
    notification = EndpointNotification(this);
    openRouter = EndpointOpenRouter(this);
    qstashWebhook = EndpointQstashWebhook(this);
    redisHealth = EndpointRedisHealth(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointActionLog actionLog;

  late final EndpointAuth auth;

  late final EndpointNotification notification;

  late final EndpointOpenRouter openRouter;

  late final EndpointQstashWebhook qstashWebhook;

  late final EndpointRedisHealth redisHealth;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'actionLog': actionLog,
        'auth': auth,
        'notification': notification,
        'openRouter': openRouter,
        'qstashWebhook': qstashWebhook,
        'redisHealth': redisHealth,
        'greeting': greeting,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
