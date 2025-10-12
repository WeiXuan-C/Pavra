import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class DetectionMetricsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> detectionHistory;
  final Map<String, int> detectionStats;
  final VoidCallback onClose;

  const DetectionMetricsSheet({
    super.key,
    required this.detectionHistory,
    required this.detectionStats,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.camera_detectionAnalytics,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: theme.dividerColor,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  _buildStatsCards(context, l10n),

                  SizedBox(height: 3.h),

                  // Detection Chart
                  _buildDetectionChart(context, l10n),

                  SizedBox(height: 3.h),

                  // Confidence Metrics
                  _buildConfidenceMetrics(context, l10n),

                  SizedBox(height: 3.h),

                  // Recent Activity
                  _buildRecentActivity(context, l10n),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final totalDetections = detectionStats.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            l10n.camera_totalDetections,
            totalDetections.toString(),
            Icons.search,
            theme.colorScheme.primary,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            context,
            l10n.camera_potholes,
            (detectionStats['pothole'] ?? 0).toString(),
            Icons.warning,
            theme.colorScheme.error,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            context,
            l10n.camera_cracks,
            (detectionStats['crack'] ?? 0).toString(),
            Icons.linear_scale,
            theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionChart(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (detectionStats.isEmpty) {
      return SizedBox(
        height: 30.h,
        child: Center(
          child: Text(
            l10n.camera_noDataAvailable,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.camera_detectionDistribution,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 30.h,
          child: PieChart(
            PieChartData(
              sections: _buildPieChartSections(context),
              centerSpaceRadius: 15.w,
              sectionsSpace: 2,
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(BuildContext context) {
    final theme = Theme.of(context);
    final total = detectionStats.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return [];

    final colors = {
      'pothole': theme.colorScheme.error,
      'crack': theme.colorScheme.tertiary,
      'obstacle': theme.colorScheme.secondary,
    };

    return detectionStats.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toInt()}%',
        color: colors[entry.key] ?? theme.colorScheme.primary,
        radius: 12.w,
        titleStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildConfidenceMetrics(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (detectionHistory.isEmpty) {
      return SizedBox.shrink();
    }

    final confidences = detectionHistory
        .map((d) => d['confidence'] as double)
        .toList();

    final avgConfidence =
        confidences.fold(0.0, (sum, conf) => sum + conf) / confidences.length;
    final maxConfidence = confidences.reduce((a, b) => a > b ? a : b);
    final minConfidence = confidences.reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.camera_confidenceMetrics,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                l10n.camera_average,
                '${(avgConfidence * 100).toInt()}%',
              ),
            ),
            Expanded(
              child: _buildMetricItem(
                context,
                l10n.camera_highest,
                '${(maxConfidence * 100).toInt()}%',
              ),
            ),
            Expanded(
              child: _buildMetricItem(
                context,
                l10n.camera_lowest,
                '${(minConfidence * 100).toInt()}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final recentDetections = detectionHistory.take(3).toList();

    if (recentDetections.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.camera_recentActivity,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...recentDetections.map(
          (detection) => _buildActivityItem(context, detection, l10n),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    Map<String, dynamic> detection,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final String type = detection['type'] as String;
    final double confidence = detection['confidence'] as double;
    final DateTime timestamp = detection['timestamp'] as DateTime;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getTypeColor(context, type).withValues(alpha: 0.2),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: _getTypeIcon(type),
                color: _getTypeColor(context, type),
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${type.toUpperCase()} ${l10n.camera_detected}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(confidence * 100).toInt()}% confidence • ${_formatTime(timestamp)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(BuildContext context, String type) {
    final theme = Theme.of(context);
    switch (type.toLowerCase()) {
      case 'pothole':
        return theme.colorScheme.error;
      case 'crack':
        return theme.colorScheme.tertiary;
      case 'obstacle':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return 'warning';
      case 'crack':
        return 'linear_scale';
      case 'obstacle':
        return 'block';
      default:
        return 'info';
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
