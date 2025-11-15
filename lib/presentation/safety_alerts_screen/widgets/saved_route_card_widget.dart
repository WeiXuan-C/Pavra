import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/saved_route_model.dart';
import '../../../l10n/app_localizations.dart';

class SavedRouteCardWidget extends StatelessWidget {
  final SavedRouteModel route;
  final Function(bool) onMonitoringToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const SavedRouteCardWidget({
    super.key,
    required this.route,
    required this.onMonitoringToggle,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: route.isMonitoring
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: route.isMonitoring ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Monitoring Toggle
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: route.isMonitoring
                                ? Colors.green.withValues(alpha: 0.15)
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.route,
                            color: route.isMonitoring
                                ? Colors.green.shade700
                                : theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            route.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  // Monitoring Toggle
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: route.isMonitoring,
                      onChanged: onMonitoringToggle,
                      activeTrackColor: Colors.green.shade300,
                      activeThumbColor: Colors.green.shade700,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // From Location
              _buildLocationRow(
                context,
                icon: Icons.trip_origin,
                label: l10n.savedRoute_from,
                location: route.fromLocationName,
                address: route.fromAddress,
                color: Colors.blue,
              ),

              SizedBox(height: 1.5.h),

              // Connector Line
              Padding(
                padding: EdgeInsets.only(left: 2.w),
                child: Container(
                  width: 2,
                  height: 3.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.withValues(alpha: 0.5),
                        Colors.orange.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 1.5.h),

              // To Location
              _buildLocationRow(
                context,
                icon: Icons.location_on,
                label: l10n.savedRoute_to,
                location: route.toLocationName,
                address: route.toAddress,
                color: Colors.orange,
              ),

              SizedBox(height: 2.h),

              // Footer: Distance and Actions
              Row(
                children: [
                  // Distance Badge
                  if (route.distanceKm != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            route.distanceDisplay,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Edit Button
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: onEdit,
                    tooltip: l10n.savedRoute_editRoute,
                  ),

                  // Delete Button
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: l10n.savedRoute_deleteRoute,
                  ),
                ],
              ),

              // Monitoring Status Indicator
              if (route.isMonitoring) ...[
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        l10n.savedRoute_monitoringDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String location,
    String? address,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                location,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (address != null && address.isNotEmpty) ...[
                SizedBox(height: 0.3.h),
                Text(
                  address,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
