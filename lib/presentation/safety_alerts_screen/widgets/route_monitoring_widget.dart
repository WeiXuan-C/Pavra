import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class RouteMonitoringWidget extends StatelessWidget {
  final List<Map<String, dynamic>> savedRoutes;
  final Function(int, bool) onRouteToggle;

  const RouteMonitoringWidget({
    super.key,
    required this.savedRoutes,
    required this.onRouteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'route',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                l10n.alerts_routeMonitoringTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (savedRoutes.isEmpty)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      l10n.alerts_noSavedRoutes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: savedRoutes.length,
              separatorBuilder: (context, index) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final route = savedRoutes[index];
                final isMonitoring = route['isMonitoring'] as bool;

                return Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isMonitoring
                        ? theme.colorScheme.primary.withValues(alpha: 0.05)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMonitoring
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: isMonitoring
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomIconWidget(
                          iconName: 'directions',
                          color: isMonitoring
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                          size: 4.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route['name'] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isMonitoring
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '${route['from']} → ${route['to']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (route['distance'] != null) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                route['distance'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Switch(
                        value: isMonitoring,
                        onChanged: (value) => onRouteToggle(index, value),
                        activeThumbColor: theme.colorScheme.primary,
                        inactiveThumbColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        inactiveTrackColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
