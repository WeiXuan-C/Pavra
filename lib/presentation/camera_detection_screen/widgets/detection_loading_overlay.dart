import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Detection Loading Overlay
/// Shows a processing indicator during AI detection API calls
///
/// Displays:
/// - Circular progress indicator
/// - "Analyzing..." text
/// - Semi-transparent backdrop
class DetectionLoadingOverlay extends StatelessWidget {
  final bool isVisible;

  const DetectionLoadingOverlay({
    super.key,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular progress indicator
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              
              SizedBox(height: 2.h),
              
              // Analyzing text
              Text(
                'Analyzing...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              SizedBox(height: 0.5.h),
              
              // Subtitle
              Text(
                'Detecting road conditions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
