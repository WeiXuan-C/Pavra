import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/directions_service.dart';

class DirectionsPanel extends StatelessWidget {
  final DirectionsResult directions;
  final VoidCallback onClose;

  const DirectionsPanel({
    super.key,
    required this.directions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      constraints: BoxConstraints(maxHeight: 40.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h, bottom: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Icon(Icons.directions, color: theme.colorScheme.primary, size: 24),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directions.distance,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        directions.duration,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Steps list
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              itemCount: directions.steps.length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 16.w),
              itemBuilder: (context, index) {
                final step = directions.steps[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    step.instruction,
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    '${step.distance} • ${step.duration}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
