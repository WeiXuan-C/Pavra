import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/app_export.dart';

class CameraControlsWidget extends StatelessWidget {
  final VoidCallback onCapturePressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback onFlashToggle;
  final bool isFlashOn;
  final bool isCapturing;
  final bool isBurstMode;
  final VoidCallback onBurstModeToggle;

  const CameraControlsWidget({
    super.key,
    required this.onCapturePressed,
    required this.onGalleryPressed,
    required this.onFlashToggle,
    required this.isFlashOn,
    required this.isCapturing,
    required this.isBurstMode,
    required this.onBurstModeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Burst Mode Toggle
            if (isBurstMode) _buildBurstModeIndicator(),

            SizedBox(height: 1.h),

            // Main Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery Button
                _buildControlButton(
                  icon: 'photo_library',
                  onPressed: onGalleryPressed,
                  size: 12.w,
                ),

                // Capture Button
                GestureDetector(
                  onTap: onCapturePressed,
                  onLongPress: onBurstModeToggle,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCapturing
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.shadow,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 16.w,
                            height: 16.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        if (isCapturing)
                          Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.lightTheme.colorScheme.onError,
                              strokeWidth: 3,
                            ),
                          ),
                        if (isBurstMode && !isCapturing)
                          Positioned(
                            top: 1.w,
                            right: 1.w,
                            child: Container(
                              width: 4.w,
                              height: 4.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    AppTheme.lightTheme.colorScheme.secondary,
                              ),
                              child: Center(
                                child: Text(
                                  'B',
                                  style: AppTheme
                                      .lightTheme
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppTheme
                                            .lightTheme
                                            .colorScheme
                                            .onSecondary,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Flash Button
                _buildControlButton(
                  icon: isFlashOn ? 'flash_on' : 'flash_off',
                  onPressed: onFlashToggle,
                  size: 12.w,
                  isActive: isFlashOn,
                ),
              ],
            ),

            SizedBox(height: 1.h),

            // Instructions
            Text(
              isBurstMode
                  ? '${l10n.camera_burstMode} • Tap to capture • Long press to exit'
                  : 'Tap to capture • Long press for burst mode',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String icon,
    required VoidCallback onPressed,
    required double size,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppTheme.lightTheme.colorScheme.secondary
              : AppTheme.lightTheme.colorScheme.surface,
          border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: isActive
                ? AppTheme.lightTheme.colorScheme.onSecondary
                : AppTheme.lightTheme.colorScheme.onSurface,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBurstModeIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.secondary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'burst_mode',
            color: AppTheme.lightTheme.colorScheme.secondary,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            'Burst Mode Active',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
