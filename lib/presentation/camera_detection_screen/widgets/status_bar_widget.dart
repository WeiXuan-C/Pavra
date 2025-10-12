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
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // GPS Status
          Expanded(flex: 2, child: _buildGpsStatus(context, l10n)),

          // Divider
          Container(
            width: 1,
            height: 4.h,
            color: theme.dividerColor,
          ),

          // Detection Toggle
          Expanded(flex: 2, child: _buildDetectionToggle(context, l10n)),
        ],
      ),
    );
  }

  Widget _buildGpsStatus(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CustomIconWidget(
          iconName: isGpsActive ? 'gps_fixed' : 'gps_off',
          color: isGpsActive
              ? theme.colorScheme.secondary
              : theme.colorScheme.error,
          size: 20,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.camera_gpsStatus,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              Text(
                isGpsActive ? gpsAccuracy : l10n.camera_disabled,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionToggle(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onDetectionToggle,
      child: Row(
        children: [
          CustomIconWidget(
            iconName: isDetectionActive ? 'smart_toy' : 'smart_toy_outlined',
            color: isDetectionActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                Text(
                  isDetectionActive ? l10n.camera_active : l10n.camera_inactive,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDetectionActive,
            onChanged: (_) => onDetectionToggle(),
          ),
        ],
      ),
    );
  }
}
