/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/action_log_endpoint.dart' as _i2;
import '../endpoints/auth_endpoint.dart' as _i3;
import '../endpoints/notification_endpoint.dart' as _i4;
import '../endpoints/openrouter_endpoint.dart' as _i5;
import '../endpoints/qstash_webhook_endpoint.dart' as _i6;
import '../endpoints/redis_health_endpoint.dart' as _i7;
import '../greeting_endpoint.dart' as _i8;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'actionLog': _i2.ActionLogEndpoint()
        ..initialize(
          server,
          'actionLog',
          null,
        ),
      'auth': _i3.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'notification': _i4.NotificationEndpoint()
        ..initialize(
          server,
          'notification',
          null,
        ),
      'openRouter': _i5.OpenRouterEndpoint()
        ..initialize(
          server,
          'openRouter',
          null,
        ),
      'qstashWebhook': _i6.QstashWebhookEndpoint()
        ..initialize(
          server,
          'qstashWebhook',
          null,
        ),
      'redisHealth': _i7.RedisHealthEndpoint()
        ..initialize(
          server,
          'redisHealth',
          null,
        ),
      'greeting': _i8.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['actionLog'] = _i1.EndpointConnector(
      name: 'actionLog',
      endpoint: endpoints['actionLog']!,
      methodConnectors: {
        'log': _i1.MethodConnector(
          name: 'log',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'action': _i1.ParameterDescription(
              name: 'action',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'targetId': _i1.ParameterDescription(
              name: 'targetId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'targetTable': _i1.ParameterDescription(
              name: 'targetTable',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'metadata': _i1.ParameterDescription(
              name: 'metadata',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['actionLog'] as _i2.ActionLogEndpoint).log(
            session,
            userId: params['userId'],
            action: params['action'],
            targetId: params['targetId'],
            targetTable: params['targetTable'],
            description: params['description'],
            metadata: params['metadata'],
          ),
        ),
        'getUserActions': _i1.MethodConnector(
          name: 'getUserActions',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['actionLog'] as _i2.ActionLogEndpoint).getUserActions(
            session,
            params['userId'],
            limit: params['limit'],
          ),
        ),
        'flushLogs': _i1.MethodConnector(
          name: 'flushLogs',
          params: {
            'batchSize': _i1.ParameterDescription(
              name: 'batchSize',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['actionLog'] as _i2.ActionLogEndpoint).flushLogs(
            session,
            batchSize: params['batchSize'],
          ),
        ),
        'healthCheck': _i1.MethodConnector(
          name: 'healthCheck',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['actionLog'] as _i2.ActionLogEndpoint)
                  .healthCheck(session),
        ),
      },
    );
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'signIn': _i1.MethodConnector(
          name: 'signIn',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'metadata': _i1.ParameterDescription(
              name: 'metadata',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i3.AuthEndpoint).signIn(
            session,
            userId: params['userId'],
            email: params['email'],
            metadata: params['metadata'],
          ),
        ),
        'signUp': _i1.MethodConnector(
          name: 'signUp',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'username': _i1.ParameterDescription(
              name: 'username',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'metadata': _i1.ParameterDescription(
              name: 'metadata',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i3.AuthEndpoint).signUp(
            session,
            userId: params['userId'],
            email: params['email'],
            username: params['username'],
            metadata: params['metadata'],
          ),
        ),
        'signOut': _i1.MethodConnector(
          name: 'signOut',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i3.AuthEndpoint).signOut(
            session,
            userId: params['userId'],
            email: params['email'],
          ),
        ),
        'testConnections': _i1.MethodConnector(
          name: 'testConnections',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i3.AuthEndpoint).testConnections(session),
        ),
      },
    );
    connectors['notification'] = _i1.EndpointConnector(
      name: 'notification',
      endpoint: endpoints['notification']!,
      methodConnectors: {
        'sendToUser': _i1.MethodConnector(
          name: 'sendToUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'relatedAction': _i1.ParameterDescription(
              name: 'relatedAction',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
            'createdBy': _i1.ParameterDescription(
              name: 'createdBy',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .sendToUser(
            session,
            userId: params['userId'],
            title: params['title'],
            message: params['message'],
            type: params['type'],
            relatedAction: params['relatedAction'],
            data: params['data'],
            createdBy: params['createdBy'],
          ),
        ),
        'sendToUsers': _i1.MethodConnector(
          name: 'sendToUsers',
          params: {
            'userIds': _i1.ParameterDescription(
              name: 'userIds',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'relatedAction': _i1.ParameterDescription(
              name: 'relatedAction',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
            'createdBy': _i1.ParameterDescription(
              name: 'createdBy',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .sendToUsers(
            session,
            userIds: params['userIds'],
            title: params['title'],
            message: params['message'],
            type: params['type'],
            relatedAction: params['relatedAction'],
            data: params['data'],
            createdBy: params['createdBy'],
          ),
        ),
        'sendToAll': _i1.MethodConnector(
          name: 'sendToAll',
          params: {
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint).sendToAll(
            session,
            title: params['title'],
            message: params['message'],
            type: params['type'],
            data: params['data'],
          ),
        ),
        'sendAppUpdateNotification': _i1.MethodConnector(
          name: 'sendAppUpdateNotification',
          params: {
            'version': _i1.ParameterDescription(
              name: 'version',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'updateMessage': _i1.ParameterDescription(
              name: 'updateMessage',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'isRequired': _i1.ParameterDescription(
              name: 'isRequired',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .sendAppUpdateNotification(
            session,
            version: params['version'],
            updateMessage: params['updateMessage'],
            isRequired: params['isRequired'],
          ),
        ),
        'sendFeatureAnnouncement': _i1.MethodConnector(
          name: 'sendFeatureAnnouncement',
          params: {
            'featureName': _i1.ParameterDescription(
              name: 'featureName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .sendFeatureAnnouncement(
            session,
            featureName: params['featureName'],
            description: params['description'],
          ),
        ),
        'sendActivityNotification': _i1.MethodConnector(
          name: 'sendActivityNotification',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'activityTitle': _i1.ParameterDescription(
              name: 'activityTitle',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'activityMessage': _i1.ParameterDescription(
              name: 'activityMessage',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .sendActivityNotification(
            session,
            userId: params['userId'],
            activityTitle: params['activityTitle'],
            activityMessage: params['activityMessage'],
          ),
        ),
        'scheduleNotificationById': _i1.MethodConnector(
          name: 'scheduleNotificationById',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'scheduledAt': _i1.ParameterDescription(
              name: 'scheduledAt',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .scheduleNotificationById(
            session,
            notificationId: params['notificationId'],
            scheduledAt: params['scheduledAt'],
          ),
        ),
        'scheduleNotification': _i1.MethodConnector(
          name: 'scheduleNotification',
          params: {
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'scheduledAt': _i1.ParameterDescription(
              name: 'scheduledAt',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'relatedAction': _i1.ParameterDescription(
              name: 'relatedAction',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
            'targetType': _i1.ParameterDescription(
              name: 'targetType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'targetRoles': _i1.ParameterDescription(
              name: 'targetRoles',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'targetUserIds': _i1.ParameterDescription(
              name: 'targetUserIds',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'createdBy': _i1.ParameterDescription(
              name: 'createdBy',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .scheduleNotification(
            session,
            title: params['title'],
            message: params['message'],
            scheduledAt: params['scheduledAt'],
            type: params['type'],
            relatedAction: params['relatedAction'],
            data: params['data'],
            targetType: params['targetType'],
            targetRoles: params['targetRoles'],
            targetUserIds: params['targetUserIds'],
            createdBy: params['createdBy'],
          ),
        ),
        'scheduleNotificationForUsers': _i1.MethodConnector(
          name: 'scheduleNotificationForUsers',
          params: {
            'userIds': _i1.ParameterDescription(
              name: 'userIds',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'scheduledAt': _i1.ParameterDescription(
              name: 'scheduledAt',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'relatedAction': _i1.ParameterDescription(
              name: 'relatedAction',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
            'createdBy': _i1.ParameterDescription(
              name: 'createdBy',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .scheduleNotificationForUsers(
            session,
            userIds: params['userIds'],
            title: params['title'],
            message: params['message'],
            scheduledAt: params['scheduledAt'],
            type: params['type'],
            relatedAction: params['relatedAction'],
            data: params['data'],
            createdBy: params['createdBy'],
          ),
        ),
        'cancelScheduledNotification': _i1.MethodConnector(
          name: 'cancelScheduledNotification',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .cancelScheduledNotification(
            session,
            notificationId: params['notificationId'],
          ),
        ),
        'handleNotificationCreated': _i1.MethodConnector(
          name: 'handleNotificationCreated',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .handleNotificationCreated(
            session,
            notificationId: params['notificationId'],
          ),
        ),
        'testProcessScheduledNotification': _i1.MethodConnector(
          name: 'testProcessScheduledNotification',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .testProcessScheduledNotification(
            session,
            notificationId: params['notificationId'],
          ),
        ),
        'processScheduledNotifications': _i1.MethodConnector(
          name: 'processScheduledNotifications',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i4.NotificationEndpoint)
                  .processScheduledNotifications(session),
        ),
      },
    );
    connectors['openRouter'] = _i1.EndpointConnector(
      name: 'openRouter',
      endpoint: endpoints['openRouter']!,
      methodConnectors: {
        'chat': _i1.MethodConnector(
          name: 'chat',
          params: {
            'prompt': _i1.ParameterDescription(
              name: 'prompt',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'model': _i1.ParameterDescription(
              name: 'model',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'maxTokens': _i1.ParameterDescription(
              name: 'maxTokens',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'temperature': _i1.ParameterDescription(
              name: 'temperature',
              type: _i1.getType<double?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['openRouter'] as _i5.OpenRouterEndpoint).chat(
            session,
            params['prompt'],
            model: params['model'],
            maxTokens: params['maxTokens'],
            temperature: params['temperature'],
          ),
        ),
        'chatWithHistory': _i1.MethodConnector(
          name: 'chatWithHistory',
          params: {
            'messages': _i1.ParameterDescription(
              name: 'messages',
              type: _i1.getType<List<Map<String, dynamic>>>(),
              nullable: false,
            ),
            'model': _i1.ParameterDescription(
              name: 'model',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'maxTokens': _i1.ParameterDescription(
              name: 'maxTokens',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'temperature': _i1.ParameterDescription(
              name: 'temperature',
              type: _i1.getType<double?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['openRouter'] as _i5.OpenRouterEndpoint)
                  .chatWithHistory(
            session,
            params['messages'],
            model: params['model'],
            maxTokens: params['maxTokens'],
            temperature: params['temperature'],
          ),
        ),
        'chatWithVision': _i1.MethodConnector(
          name: 'chatWithVision',
          params: {
            'textPrompt': _i1.ParameterDescription(
              name: 'textPrompt',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'imageUrl': _i1.ParameterDescription(
              name: 'imageUrl',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'model': _i1.ParameterDescription(
              name: 'model',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'maxTokens': _i1.ParameterDescription(
              name: 'maxTokens',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'temperature': _i1.ParameterDescription(
              name: 'temperature',
              type: _i1.getType<double?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['openRouter'] as _i5.OpenRouterEndpoint)
                  .chatWithVision(
            session,
            params['textPrompt'],
            params['imageUrl'],
            model: params['model'],
            maxTokens: params['maxTokens'],
            temperature: params['temperature'],
          ),
        ),
        'getModels': _i1.MethodConnector(
          name: 'getModels',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['openRouter'] as _i5.OpenRouterEndpoint)
                  .getModels(session),
        ),
      },
    );
    connectors['qstashWebhook'] = _i1.EndpointConnector(
      name: 'qstashWebhook',
      endpoint: endpoints['qstashWebhook']!,
      methodConnectors: {
        'processScheduledNotification': _i1.MethodConnector(
          name: 'processScheduledNotification',
          params: {
            'payload': _i1.ParameterDescription(
              name: 'payload',
              type: _i1.getType<Map<String, dynamic>>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['qstashWebhook'] as _i6.QstashWebhookEndpoint)
                  .processScheduledNotification(
            session,
            params['payload'],
          ),
        )
      },
    );
    connectors['redisHealth'] = _i1.EndpointConnector(
      name: 'redisHealth',
      endpoint: endpoints['redisHealth']!,
      methodConnectors: {
        'check': _i1.MethodConnector(
          name: 'check',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['redisHealth'] as _i7.RedisHealthEndpoint)
                  .check(session),
        ),
        'info': _i1.MethodConnector(
          name: 'info',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['redisHealth'] as _i7.RedisHealthEndpoint)
                  .info(session),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['greeting'] as _i8.GreetingEndpoint).hello(
            session,
            params['name'],
          ),
        )
      },
    );
  }
}
