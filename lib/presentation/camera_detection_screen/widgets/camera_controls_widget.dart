import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/app_export.dart';

class CameraControlsWidget extends StatelessWidget {
  final VoidCallback onCapturePressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback onFlashToggle;
  final VoidCallback? onManualDetectionPressed;
  final bool isFlashOn;
  final bool isCapturing;
  final bool isBurstMode;
  final VoidCallback onBurstModeToggle;
  final bool isManualDetecting;

  const CameraControlsWidget({
    super.key,
    required this.onCapturePressed,
    required this.onGalleryPressed,
    required this.onFlashToggle,
    this.onManualDetectionPressed,
    required this.isFlashOn,
    required this.isCapturing,
    required this.isBurstMode,
    required this.onBurstModeToggle,
    this.isManualDetecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
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
            if (isBurstMode) _buildBurstModeIndicator(context),

            SizedBox(height: 1.h),

            // Main Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery Button
                _buildControlButton(
                  context: context,
                  icon: 'photo_library',
                  onPressed: onGalleryPressed,
                  size: 12.w,
                ),

                // Manual AI Detection Button
                if (onManualDetectionPressed != null)
                  _buildControlButton(
                    context: context,
                    icon: 'psychology',
                    onPressed: onManualDetectionPressed!,
                    size: 12.w,
                    isActive: isManualDetecting,
                    tooltip: l10n.camera_manualDetection,
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
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow,
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
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        if (isCapturing)
                          Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onError,
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
                                color: theme.colorScheme.secondary,
                              ),
                              child: Center(
                                child: Text(
                                  'B',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSecondary,
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
                  context: context,
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
                  ? l10n.camera_burstModeInstructions(l10n.camera_burstMode)
                  : l10n.camera_captureInstructions,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required String icon,
    required VoidCallback onPressed,
    required double size,
    bool isActive = false,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    final button = GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? theme.colorScheme.secondary
              : theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: isActive
                ? theme.colorScheme.onSecondary
                : theme.colorScheme.onSurface,
            size: size * 0.4,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }
    return button;
  }

  Widget _buildBurstModeIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'burst_mode',
            color: theme.colorScheme.secondary,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            l10n.camera_burstModeActive,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
