import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
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
              color: AppTheme.lightTheme.dividerColor,
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
                    'Detection Analytics',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
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
                      color: AppTheme.lightTheme.colorScheme.surface,
                      border: Border.all(
                        color: AppTheme.lightTheme.dividerColor,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
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
                  _buildStatsCards(),

                  SizedBox(height: 3.h),

                  // Detection Chart
                  _buildDetectionChart(),

                  SizedBox(height: 3.h),

                  // Confidence Metrics
                  _buildConfidenceMetrics(),

                  SizedBox(height: 3.h),

                  // Recent Activity
                  _buildRecentActivity(),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalDetections = detectionStats.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Detections',
            totalDetections.toString(),
            Icons.search,
            AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            'Potholes',
            (detectionStats['pothole'] ?? 0).toString(),
            Icons.warning,
            AppTheme.lightTheme.colorScheme.error,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            'Cracks',
            (detectionStats['crack'] ?? 0).toString(),
            Icons.linear_scale,
            AppTheme.lightTheme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionChart() {
    if (detectionStats.isEmpty) {
      return SizedBox(
        height: 30.h,
        child: Center(
          child: Text(
            'No detection data available',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.5,
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
          'Detection Distribution',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 30.h,
          child: PieChart(
            PieChartData(
              sections: _buildPieChartSections(),
              centerSpaceRadius: 15.w,
              sectionsSpace: 2,
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = detectionStats.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return [];

    final colors = {
      'pothole': AppTheme.lightTheme.colorScheme.error,
      'crack': AppTheme.lightTheme.colorScheme.tertiary,
      'obstacle': AppTheme.lightTheme.colorScheme.secondary,
    };

    return detectionStats.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toInt()}%',
        color: colors[entry.key] ?? AppTheme.lightTheme.colorScheme.primary,
        radius: 12.w,
        titleStyle: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildConfidenceMetrics() {
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
          'Confidence Metrics',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                'Average',
                '${(avgConfidence * 100).toInt()}%',
              ),
            ),
            Expanded(
              child: _buildMetricItem(
                'Highest',
                '${(maxConfidence * 100).toInt()}%',
              ),
            ),
            Expanded(
              child: _buildMetricItem(
                'Lowest',
                '${(minConfidence * 100).toInt()}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(3.w),
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightTheme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentDetections = detectionHistory.take(3).toList();

    if (recentDetections.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...recentDetections.map((detection) => _buildActivityItem(detection)),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> detection) {
    final String type = detection['type'] as String;
    final double confidence = detection['confidence'] as double;
    final DateTime timestamp = detection['timestamp'] as DateTime;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getTypeColor(type).withValues(alpha: 0.2),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: _getTypeIcon(type),
                color: _getTypeColor(type),
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
                  '${type.toUpperCase()} detected',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(confidence * 100).toInt()}% confidence • ${_formatTime(timestamp)}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return AppTheme.lightTheme.colorScheme.error;
      case 'crack':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'obstacle':
        return AppTheme.lightTheme.colorScheme.secondary;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
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
