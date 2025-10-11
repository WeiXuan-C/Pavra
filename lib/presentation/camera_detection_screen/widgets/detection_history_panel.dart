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
    
    return Container(
      width: 80.w,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
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
              color: AppTheme.lightTheme.colorScheme.primary,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.camera_recentDetections,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
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
                      color: AppTheme.lightTheme.colorScheme.onPrimary
                          .withValues(alpha: 0.2),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
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
                ? _buildEmptyState(l10n)
                : ListView.separated(
                    padding: EdgeInsets.all(4.w),
                    itemCount: recentDetections.length,
                    separatorBuilder: (context, index) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) {
                      final detection = recentDetections[index];
                      return _buildDetectionCard(detection);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.3,
            ),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.camera_noDetectionsYet,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.camera_startScanning,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.5,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard(Map<String, dynamic> detection) {
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
        typeColor = AppTheme.lightTheme.colorScheme.error;
        typeIcon = Icons.warning;
        break;
      case 'crack':
        typeColor = AppTheme.lightTheme.colorScheme.tertiary;
        typeIcon = Icons.linear_scale;
        break;
      case 'obstacle':
        typeColor = AppTheme.lightTheme.colorScheme.secondary;
        typeIcon = Icons.block;
        break;
      default:
        typeColor = AppTheme.lightTheme.colorScheme.primary;
        typeIcon = Icons.info;
    }

    return GestureDetector(
      onTap: () => onDetectionTap(detection),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
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
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${(confidence * 100).toInt()}%',
                        style: AppTheme.lightTheme.textTheme.labelSmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    location,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _formatTimestamp(timestamp),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
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
