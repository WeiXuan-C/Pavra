import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'route',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Route Monitoring',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
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
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.05,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'No saved routes. Add frequent routes to monitor for alerts.',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
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
                        ? AppTheme.lightTheme.colorScheme.primary.withValues(
                            alpha: 0.05,
                          )
                        : AppTheme.lightTheme.colorScheme.onSurface.withValues(
                            alpha: 0.02,
                          ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMonitoring
                          ? AppTheme.lightTheme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            )
                          : AppTheme.lightTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: isMonitoring
                              ? AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.1)
                              : AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomIconWidget(
                          iconName: 'directions',
                          color: isMonitoring
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
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
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isMonitoring
                                        ? AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurface
                                        : AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                  ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '${route['from']} → ${route['to']}',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (route['distance'] != null) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                route['distance'] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme
                                          .lightTheme
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Switch(
                        value: isMonitoring,
                        onChanged: (value) => onRouteToggle(index, value),
                        activeThumbColor:
                            AppTheme.lightTheme.colorScheme.primary,
                        inactiveThumbColor: AppTheme
                            .lightTheme
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        inactiveTrackColor: AppTheme
                            .lightTheme
                            .colorScheme
                            .onSurface
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
