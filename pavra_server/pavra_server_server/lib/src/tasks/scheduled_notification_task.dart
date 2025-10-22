import 'package:serverpod/serverpod.dart';
import '../endpoints/notification_endpoint.dart';
import '../../server.dart';

/// FutureCall that processes scheduled notifications
///
/// This task runs periodically (every minute) to check for and send scheduled notifications
class ScheduledNotificationTask extends FutureCall {
  static const Duration _checkInterval = Duration(minutes: 1);

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      PLog.info('🔔 Running scheduled notification task...');

      final endpoint = NotificationEndpoint();
      final result = await endpoint.processScheduledNotifications(session);

      if (result['success'] == true) {
        PLog.info(
          '✓ Scheduled notification task completed: ${result['processed']} notifications processed',
        );
      } else {
        PLog.error('❌ Scheduled notification task failed: ${result['error']}');
      }
    } catch (e, stackTrace) {
      PLog.error('❌ Error in scheduled notification task', e, stackTrace);
    } finally {
      // Schedule next check
      _scheduleNextCheck(session);
    }
  }

  /// Schedules the next notification check
  void _scheduleNextCheck(Session session) {
    if (!session.serverpod.config.futureCallExecutionEnabled) {
      session.log(
        'Skipping scheduling next notification check: future calls not enabled',
        level: LogLevel.warning,
      );
      return;
    }

    session.serverpod.futureCallAtTime(
      'scheduledNotificationCheck',
      null,
      DateTime.now().add(_checkInterval),
    );
  }
}

/// Initialize the scheduled notification task
Future<void> initializeScheduledNotificationTask(Serverpod pod) async {
  // Check if future calls are enabled
  if (!pod.config.futureCallExecutionEnabled) {
    PLog.warn(
      '⚠️ Future calls disabled in config, skipping scheduled notification task.',
    );
    return;
  }

  try {
    await pod.futureCallWithDelay(
      'scheduledNotificationCheck',
      null,
      Duration(minutes: 1),
    );

    PLog.info('✓ Scheduled notification task registered.');
  } catch (e) {
    PLog.warn('⚠️ Failed to register scheduled notification task: $e');
    PLog.warn(
      '   Scheduled notifications will not be automatically sent.',
    );
  }
}
