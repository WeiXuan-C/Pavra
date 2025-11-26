import 'package:logging/logging.dart';
import 'supabase_service.dart';

/// Service for tracking and analyzing notification delivery metrics
///
/// Provides functionality to:
/// - Track notification send success rates
/// - Calculate average delivery times
/// - Monitor user engagement metrics (open rate, click rate)
/// - Store and retrieve metrics for analytics
class NotificationMetricsService {
  static final _log = Logger('NotificationMetricsService');
  final SupabaseService _supabase = SupabaseService.instance;

  /// Track delivery metrics for a notification
  ///
  /// This should be called after a notification is sent to store
  /// delivery statistics and calculate success rates
  Future<void> trackDeliveryMetrics({
    required String notificationId,
    required int totalSent,
    required int successfulDeliveries,
    required int failedDeliveries,
    DateTime? firstDeliveryAt,
    DateTime? lastDeliveryAt,
    int? averageDeliveryTimeMs,
  }) async {
    try {
      _log.info('📊 Tracking delivery metrics for notification: $notificationId');
      _log.fine('   Total sent: $totalSent');
      _log.fine('   Successful: $successfulDeliveries');
      _log.fine('   Failed: $failedDeliveries');

      // Calculate success rate
      final successRate = totalSent > 0
          ? (successfulDeliveries / totalSent * 100).toStringAsFixed(2)
          : '0.00';

      // Prepare metrics data
      final metricsData = {
        'notification_id': notificationId,
        'send_success_rate': double.parse(successRate),
        'total_sent': totalSent,
        'total_delivered': successfulDeliveries,
        'total_failed': failedDeliveries,
        if (firstDeliveryAt != null)
          'first_delivery_at': firstDeliveryAt.toIso8601String(),
        if (lastDeliveryAt != null)
          'last_delivery_at': lastDeliveryAt.toIso8601String(),
        if (averageDeliveryTimeMs != null)
          'average_delivery_time_ms': averageDeliveryTimeMs,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Check if metrics already exist
      final existing = await _supabase.select(
        'notification_metrics',
        filters: {'notification_id': notificationId},
      );

      if (existing.isEmpty) {
        // Insert new metrics
        await _supabase.insert('notification_metrics', [metricsData]);
        _log.info('✅ Delivery metrics created for notification: $notificationId');
      } else {
        // Update existing metrics
        await _supabase.update(
          'notification_metrics',
          metricsData,
          filters: {'notification_id': notificationId},
        );
        _log.info('✅ Delivery metrics updated for notification: $notificationId');
      }

      _log.info('   Success rate: $successRate%');
      if (averageDeliveryTimeMs != null) {
        _log.info('   Avg delivery time: ${averageDeliveryTimeMs}ms');
      }
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to track delivery metrics');
      _log.severe('   Notification ID: $notificationId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      // Don't rethrow - metrics tracking should not break the main flow
    }
  }

  /// Update user engagement metrics (open rate, click rate, dismiss rate)
  ///
  /// This should be called when user interactions are tracked
  Future<void> trackEngagementMetrics({
    required String notificationId,
    int? totalOpened,
    int? totalClicked,
    int? totalDismissed,
  }) async {
    try {
      _log.info('📊 Tracking engagement metrics for notification: $notificationId');

      // Get current metrics to calculate rates
      final existing = await _supabase.select(
        'notification_metrics',
        filters: {'notification_id': notificationId},
      );

      if (existing.isEmpty) {
        _log.warning('⚠️  No metrics found for notification: $notificationId');
        return;
      }

      final currentMetrics = existing.first;
      final totalSent = currentMetrics['total_sent'] as int? ?? 0;

      // Calculate engagement rates
      final openRate = totalSent > 0 && totalOpened != null
          ? (totalOpened / totalSent * 100).toStringAsFixed(2)
          : null;
      final clickRate = totalSent > 0 && totalClicked != null
          ? (totalClicked / totalSent * 100).toStringAsFixed(2)
          : null;
      final dismissRate = totalSent > 0 && totalDismissed != null
          ? (totalDismissed / totalSent * 100).toStringAsFixed(2)
          : null;

      // Prepare update data
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (totalOpened != null) {
        updateData['total_opened'] = totalOpened;
        if (openRate != null) {
          updateData['open_rate'] = double.parse(openRate);
        }
      }

      if (totalClicked != null) {
        updateData['total_clicked'] = totalClicked;
        if (clickRate != null) {
          updateData['click_rate'] = double.parse(clickRate);
        }
      }

      if (totalDismissed != null) {
        updateData['total_dismissed'] = totalDismissed;
        if (dismissRate != null) {
          updateData['dismiss_rate'] = double.parse(dismissRate);
        }
      }

      // Update metrics
      await _supabase.update(
        'notification_metrics',
        updateData,
        filters: {'notification_id': notificationId},
      );

      _log.info('✅ Engagement metrics updated for notification: $notificationId');
      if (openRate != null) _log.info('   Open rate: $openRate%');
      if (clickRate != null) _log.info('   Click rate: $clickRate%');
      if (dismissRate != null) _log.info('   Dismiss rate: $dismissRate%');
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to track engagement metrics');
      _log.severe('   Notification ID: $notificationId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      // Don't rethrow - metrics tracking should not break the main flow
    }
  }

  /// Get metrics for a specific notification
  Future<Map<String, dynamic>?> getMetrics(String notificationId) async {
    try {
      _log.info('📊 Fetching metrics for notification: $notificationId');

      final metrics = await _supabase.select(
        'notification_metrics',
        filters: {'notification_id': notificationId},
      );

      if (metrics.isEmpty) {
        _log.info('ℹ️  No metrics found for notification: $notificationId');
        return null;
      }

      final result = metrics.first;
      _log.info('✅ Metrics retrieved successfully');
      _log.fine('   Success rate: ${result['send_success_rate']}%');
      _log.fine('   Open rate: ${result['open_rate']}%');

      return result;
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to get metrics');
      _log.severe('   Notification ID: $notificationId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get aggregated metrics for multiple notifications
  ///
  /// Useful for dashboard analytics showing overall performance
  Future<Map<String, dynamic>> getAggregatedMetrics({
    DateTime? startDate,
    DateTime? endDate,
    String? notificationType,
  }) async {
    try {
      _log.info('📊 Fetching aggregated metrics');
      if (startDate != null) _log.fine('   Start date: ${startDate.toIso8601String()}');
      if (endDate != null) _log.fine('   End date: ${endDate.toIso8601String()}');
      if (notificationType != null) _log.fine('   Type: $notificationType');

      // Get all metrics (we'll filter in memory for now)
      final allMetrics = await _supabase.select('notification_metrics');

      // Filter by date range if provided
      var filteredMetrics = allMetrics;
      if (startDate != null || endDate != null) {
        filteredMetrics = allMetrics.where((metric) {
          final createdAt = DateTime.parse(metric['created_at'] as String);
          if (startDate != null && createdAt.isBefore(startDate)) return false;
          if (endDate != null && createdAt.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Calculate aggregates
      if (filteredMetrics.isEmpty) {
        return {
          'total_notifications': 0,
          'average_success_rate': 0.0,
          'average_open_rate': 0.0,
          'average_click_rate': 0.0,
          'total_sent': 0,
          'total_delivered': 0,
          'total_failed': 0,
          'total_opened': 0,
          'total_clicked': 0,
        };
      }

      final totalNotifications = filteredMetrics.length;
      final totalSent = filteredMetrics.fold<int>(
        0,
        (sum, m) => sum + (m['total_sent'] as int? ?? 0),
      );
      final totalDelivered = filteredMetrics.fold<int>(
        0,
        (sum, m) => sum + (m['total_delivered'] as int? ?? 0),
      );
      final totalFailed = filteredMetrics.fold<int>(
        0,
        (sum, m) => sum + (m['total_failed'] as int? ?? 0),
      );
      final totalOpened = filteredMetrics.fold<int>(
        0,
        (sum, m) => sum + (m['total_opened'] as int? ?? 0),
      );
      final totalClicked = filteredMetrics.fold<int>(
        0,
        (sum, m) => sum + (m['total_clicked'] as int? ?? 0),
      );

      // Calculate averages
      final avgSuccessRate = filteredMetrics
              .map((m) => m['send_success_rate'] as num? ?? 0)
              .reduce((a, b) => a + b) /
          totalNotifications;

      final metricsWithOpenRate = filteredMetrics
          .where((m) => m['open_rate'] != null)
          .toList();
      final avgOpenRate = metricsWithOpenRate.isNotEmpty
          ? metricsWithOpenRate
                  .map((m) => m['open_rate'] as num)
                  .reduce((a, b) => a + b) /
              metricsWithOpenRate.length
          : 0.0;

      final metricsWithClickRate = filteredMetrics
          .where((m) => m['click_rate'] != null)
          .toList();
      final avgClickRate = metricsWithClickRate.isNotEmpty
          ? metricsWithClickRate
                  .map((m) => m['click_rate'] as num)
                  .reduce((a, b) => a + b) /
              metricsWithClickRate.length
          : 0.0;

      final result = {
        'total_notifications': totalNotifications,
        'average_success_rate': double.parse(avgSuccessRate.toStringAsFixed(2)),
        'average_open_rate': double.parse(avgOpenRate.toStringAsFixed(2)),
        'average_click_rate': double.parse(avgClickRate.toStringAsFixed(2)),
        'total_sent': totalSent,
        'total_delivered': totalDelivered,
        'total_failed': totalFailed,
        'total_opened': totalOpened,
        'total_clicked': totalClicked,
        'period_start': startDate?.toIso8601String(),
        'period_end': endDate?.toIso8601String(),
      };

      _log.info('✅ Aggregated metrics calculated');
      _log.info('   Total notifications: $totalNotifications');
      _log.info('   Avg success rate: ${result['average_success_rate']}%');
      _log.info('   Avg open rate: ${result['average_open_rate']}%');

      return result;
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to get aggregated metrics');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Calculate metrics from OneSignal data and store in database
  ///
  /// This is called after fetching delivery stats from OneSignal
  Future<void> calculateAndStoreMetrics(String notificationId) async {
    try {
      _log.info('📊 Calculating metrics for notification: $notificationId');

      // Call the database function to calculate metrics
      await _supabase.rpc('calculate_notification_metrics', {
        'p_notification_id': notificationId,
      });

      _log.info('✅ Metrics calculated and stored for notification: $notificationId');
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to calculate metrics');
      _log.severe('   Notification ID: $notificationId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      // Don't rethrow - metrics calculation should not break the main flow
    }
  }

  /// Get metrics summary for dashboard
  ///
  /// Returns a summary of key metrics for display in admin dashboard
  Future<Map<String, dynamic>> getMetricsSummary({
    int daysBack = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));

      _log.info('📊 Fetching metrics summary for last $daysBack days');

      final aggregated = await getAggregatedMetrics(
        startDate: startDate,
        endDate: endDate,
      );

      // Add additional summary information
      final summary = {
        ...aggregated,
        'period_days': daysBack,
        'generated_at': DateTime.now().toIso8601String(),
      };

      _log.info('✅ Metrics summary generated');

      return summary;
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to get metrics summary');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}
