import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? cameraController;
  final bool isDetectionActive;
  final List<Map<String, dynamic>> detectedIssues;
  final VoidCallback onCrosshairTap;

  const CameraPreviewWidget({
    super.key,
    required this.cameraController,
    required this.isDetectionActive,
    required this.detectedIssues,
    required this.onCrosshairTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 70.h,
        color: AppTheme.lightTheme.colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.lightTheme.primaryColor,
              ),
              SizedBox(height: 2.h),
              Text(
                'Initializing Camera...',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 70.h,
      child: Stack(
        children: [
          // Camera Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CameraPreview(cameraController!),
          ),

          // Detection Overlay
          if (isDetectionActive) _buildDetectionOverlay(),

          // Crosshair
          _buildCrosshair(),

          // Detection Bounding Boxes
          ...detectedIssues.map((issue) => _buildBoundingBox(issue)),
        ],
      ),
    );
  }

  Widget _buildDetectionOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.secondary,
          width: 2,
        ),
      ),
      child: Positioned(
        top: 2.h,
        left: 4.w,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.secondary.withValues(
              alpha: 0.9,
            ),
            borderRadius: BorderRadius.circular(8),
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
                'AI Detection Active',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrosshair() {
    return Center(
      child: GestureDetector(
        onTap: onCrosshairTap,
        child: SizedBox(
          width: 15.w,
          height: 15.w,
          child: Stack(
            children: [
              // Outer circle
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.8,
                    ),
                    width: 2,
                  ),
                ),
              ),
              // Inner crosshair
              Center(
                child: SizedBox(
                  width: 8.w,
                  height: 8.w,
                  child: CustomPaint(
                    painter: CrosshairPainter(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              // Center dot
              Center(
                child: Container(
                  width: 1.w,
                  height: 1.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoundingBox(Map<String, dynamic> issue) {
    final double left = (issue['x'] as double) * 100;
    final double top = (issue['y'] as double) * 100;
    final double width = (issue['width'] as double) * 100;
    final double height = (issue['height'] as double) * 100;
    final String type = issue['type'] as String;
    final double confidence = issue['confidence'] as double;

    Color boxColor;
    switch (type.toLowerCase()) {
      case 'pothole':
        boxColor = AppTheme.lightTheme.colorScheme.error;
        break;
      case 'crack':
        boxColor = AppTheme.lightTheme.colorScheme.tertiary;
        break;
      case 'obstacle':
        boxColor = AppTheme.lightTheme.colorScheme.secondary;
        break;
      default:
        boxColor = AppTheme.lightTheme.colorScheme.primary;
    }

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
            // Label background
            Positioned(
              top: -6.h,
              left: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
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
}

class CrosshairPainter extends CustomPainter {
  final Color color;

  CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final lineLength = size.width * 0.3;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - lineLength, center.dy),
      Offset(center.dx + lineLength, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - lineLength),
      Offset(center.dx, center.dy + lineLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
