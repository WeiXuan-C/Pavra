import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ImagePreviewWidget extends StatelessWidget {
  final String? imageUrl;
  final List<Map<String, dynamic>> detectedIssues;
  final VoidCallback? onRetakePhoto;

  const ImagePreviewWidget({
    super.key,
    this.imageUrl,
    required this.detectedIssues,
    this.onRetakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 45.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Image display
            if (imageUrl != null)
              Positioned.fill(
                child: CustomImageWidget(
                  imageUrl: imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: AppTheme.lightTheme.colorScheme.surface.withValues(
                    alpha: 0.5,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'camera_alt',
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        size: 48,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No image selected',
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            // AI Detection Overlay
            if (imageUrl != null && detectedIssues.isNotEmpty)
              ...detectedIssues.map((issue) => _buildDetectionBox(issue)),

            // Retake button
            if (imageUrl != null)
              Positioned(
                top: 2.h,
                right: 4.w,
                child: GestureDetector(
                  onTap: onRetakePhoto,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CustomIconWidget(
                      iconName: 'camera_alt',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),

            // Detection count badge
            if (detectedIssues.isNotEmpty)
              Positioned(
                top: 2.h,
                left: 4.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'visibility',
                        color: AppTheme.lightTheme.colorScheme.onSecondary,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${detectedIssues.length} detected',
                        style: AppTheme.lightTheme.textTheme.labelSmall
                            ?.copyWith(
                              color:
                                  AppTheme.lightTheme.colorScheme.onSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionBox(Map<String, dynamic> issue) {
    final double left = (issue['x'] as double) * 100;
    final double top = (issue['y'] as double) * 100;
    final double width = (issue['width'] as double) * 100;
    final double height = (issue['height'] as double) * 100;
    final String type = issue['type'] as String;
    final double confidence = issue['confidence'] as double;

    Color boxColor = _getIssueColor(type);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: boxColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Semi-transparent overlay
            Container(
              decoration: BoxDecoration(
                color: boxColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Label
            Positioned(
              top: -6,
              left: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${type.toUpperCase()} ${(confidence * 100).toInt()}%',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIssueColor(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return AppTheme.lightTheme.colorScheme.error;
      case 'crack':
        return const Color(0xFFFF9800);
      case 'obstacle':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }
}
