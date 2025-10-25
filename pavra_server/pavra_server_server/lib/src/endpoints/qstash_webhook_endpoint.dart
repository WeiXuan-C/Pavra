import 'package:serverpod/serverpod.dart';
import '../tasks/scheduled_notification_task.dart';

/// Endpoint for receiving QStash webhook callbacks
class QstashWebhookEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// Handle scheduled notification callback from QStash
  Future<Map<String, dynamic>> processScheduledNotification(
    Session session,
    Map<String, dynamic> payload,
  ) async {
    try {
      // TODO: Implement signature verification when you have access to request headers
      // For now, we'll skip signature verification
      // In production, you should verify the QStash signature

      // Extract notification ID from payload
      final notificationId = payload['notificationId'] as String?;
      if (notificationId == null) {
        throw Exception('Missing notificationId in payload');
      }

      // Process the notification
      final result = await ScheduledNotificationTask.processNotification(
        session: session,
        notificationId: notificationId,
      );

      return result;
    } catch (e, stackTrace) {
      session.log('❌ QStash webhook error', level: LogLevel.error);
      session.log(e.toString(), level: LogLevel.error);
      session.log(stackTrace.toString(), level: LogLevel.error);

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
