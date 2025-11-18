import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/detection_model.dart';
import '../../../data/models/detection_type.dart';

/// Detection Alert Widget
/// Displays color-coded alert cards for AI detection results
///
/// Alert colors:
/// - Red: High severity (severity >= 4 or accident)
/// - Yellow: Medium severity (severity 2-3)
/// - Green: Low severity or normal
class DetectionAlertWidget extends StatelessWidget {
  final DetectionModel detection;
  final Color alertColor;
  final VoidCallback onDismiss;
  final VoidCallback onSubmitReport;

  const DetectionAlertWidget({
    super.key,
    required this.detection,
    required this.alertColor,
    required this.onDismiss,
    required this.onSubmitReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with alert color indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                // Alert icon
                Icon(
                  _getAlertIcon(),
                  color: alertColor,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                // Detection type
                Expanded(
                  child: Text(
                    _formatDetectionType(detection.type),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: alertColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Severity badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: alertColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level ${detection.severity}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence score
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Confidence: ${(detection.confidence * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    // Confidence bar
                    Expanded(
                      child: LinearProgressIndicator(
                        value: detection.confidence,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(alertColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 2.h),
                
                // Description
                Text(
                  'Description',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  detection.description,
                  style: theme.textTheme.bodyMedium,
                ),
                
                SizedBox(height: 2.h),
                
                // Suggested action
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          detection.suggestedAction,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Dismiss button
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                // Submit report button
                ElevatedButton(
                  onPressed: onSubmitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: alertColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 16),
                      SizedBox(width: 1.w),
                      Text('Submit Report'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get appropriate icon based on alert color
  IconData _getAlertIcon() {
    if (alertColor == Colors.red) {
      return Icons.warning;
    } else if (alertColor == Colors.amber) {
      return Icons.info;
    } else {
      return Icons.check_circle;
    }
  }

  /// Format detection type for display
  String _formatDetectionType(DetectionType type) {
    switch (type) {
      case DetectionType.roadCrack:
        return 'Road Crack Detected';
      case DetectionType.pothole:
        return 'Pothole Detected';
      case DetectionType.unevenSurface:
        return 'Uneven Surface Detected';
      case DetectionType.flood:
        return 'Flooding Detected';
      case DetectionType.accident:
        return 'Accident Detected';
      case DetectionType.debris:
        return 'Debris Detected';
      case DetectionType.obstacle:
        return 'Obstacle Detected';
      case DetectionType.normal:
        return 'No Issues Detected';
    }
  }
}
