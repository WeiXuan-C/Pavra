import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AlertToggleWidget extends StatelessWidget {
  final String title;
  final String iconName;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const AlertToggleWidget({
    super.key,
    required this.title,
    required this.iconName,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    )
                  : AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.1,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: isEnabled
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.5,
                    ),
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              title,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: isEnabled
                    ? AppTheme.lightTheme.colorScheme.onSurface
                    : AppTheme.lightTheme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeThumbColor: AppTheme.lightTheme.colorScheme.primary,
            inactiveThumbColor: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.5),
            inactiveTrackColor: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
