import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class StatusBarWidget extends StatelessWidget {
  final bool isGpsActive;
  final String gpsAccuracy;
  final bool isDetectionActive;
  final VoidCallback onDetectionToggle;

  const StatusBarWidget({
    super.key,
    required this.isGpsActive,
    required this.gpsAccuracy,
    required this.isDetectionActive,
    required this.onDetectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // GPS Status
          Expanded(flex: 2, child: _buildGpsStatus(l10n)),

          // Divider
          Container(
            width: 1,
            height: 4.h,
            color: AppTheme.lightTheme.dividerColor,
          ),

          // Detection Toggle
          Expanded(flex: 2, child: _buildDetectionToggle(l10n)),
        ],
      ),
    );
  }

  Widget _buildGpsStatus(AppLocalizations l10n) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: isGpsActive ? 'gps_fixed' : 'gps_off',
          color: isGpsActive
              ? AppTheme.lightTheme.colorScheme.secondary
              : AppTheme.lightTheme.colorScheme.error,
          size: 20,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.camera_gpsStatus,
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              Text(
                isGpsActive ? gpsAccuracy : l10n.camera_disabled,
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionToggle(AppLocalizations l10n) {
    return GestureDetector(
      onTap: onDetectionToggle,
      child: Row(
        children: [
          CustomIconWidget(
            iconName: isDetectionActive ? 'smart_toy' : 'smart_toy_outlined',
            color: isDetectionActive
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.camera_aiDetection,
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                Text(
                  isDetectionActive ? l10n.camera_active : l10n.camera_inactive,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDetectionActive,
            onChanged: (_) => onDetectionToggle(),
            activeThumbColor: AppTheme.lightTheme.colorScheme.primary,
            inactiveThumbColor: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
