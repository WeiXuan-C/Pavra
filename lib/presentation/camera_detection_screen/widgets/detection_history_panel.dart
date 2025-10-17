import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class DetectionHistoryPanel extends StatelessWidget {
  final List<Map<String, dynamic>> recentDetections;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onDetectionTap;

  const DetectionHistoryPanel({
    super.key,
    required this.recentDetections,
    required this.onClose,
    required this.onDetectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: 80.w,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 16,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.camera_recentDetections,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: recentDetections.isEmpty
                ? _buildEmptyState(context, l10n)
                : ListView.separated(
                    padding: EdgeInsets.all(4.w),
                    itemCount: recentDetections.length,
                    separatorBuilder: (context, index) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) {
                      final detection = recentDetections[index];
                      return _buildDetectionCard(context, detection);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.camera_noDetectionsYet,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.camera_startScanning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard(
    BuildContext context,
    Map<String, dynamic> detection,
  ) {
    final theme = Theme.of(context);
    final String type = detection['type'] as String;
    final double confidence = detection['confidence'] as double;
    final DateTime timestamp = detection['timestamp'] as DateTime;
    final String? imageUrl = detection['imageUrl'] as String?;
    final String location =
        detection['location'] as String? ?? 'Unknown Location';

    Color typeColor;
    IconData typeIcon;

    switch (type.toLowerCase()) {
      case 'pothole':
        typeColor = theme.colorScheme.error;
        typeIcon = Icons.warning;
        break;
      case 'crack':
        typeColor = theme.colorScheme.tertiary;
        typeIcon = Icons.linear_scale;
        break;
      case 'obstacle':
        typeColor = theme.colorScheme.secondary;
        typeIcon = Icons.block;
        break;
      default:
        typeColor = theme.colorScheme.primary;
        typeIcon = Icons.info;
    }

    return GestureDetector(
      onTap: () => onDetectionTap(detection),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: typeColor.withValues(alpha: 0.1),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomImageWidget(
                        imageUrl: imageUrl,
                        width: 15.w,
                        height: 15.w,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Icon(typeIcon, color: typeColor, size: 6.w),
                    ),
            ),

            SizedBox(width: 3.w),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${(confidence * 100).toInt()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _formatTimestamp(timestamp, context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return l10n.time_justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.time_minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.time_hoursAgo(difference.inHours);
    } else {
      return l10n.time_daysAgo(difference.inDays);
    }
  }
}
