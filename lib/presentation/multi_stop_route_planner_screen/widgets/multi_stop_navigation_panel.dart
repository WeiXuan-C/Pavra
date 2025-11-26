import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/multi_stop_navigation_service.dart';

/// Navigation panel for multi-stop routes
/// Displays current waypoint, remaining stops, and progress
class MultiStopNavigationPanel extends StatelessWidget {
  final MultiStopNavigationService navigationService;
  final VoidCallback onCancel;

  const MultiStopNavigationPanel({
    super.key,
    required this.navigationService,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!navigationService.isNavigating) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          _buildProgressBar(theme),
          
          SizedBox(height: 2.h),
          
          // Current waypoint info
          Row(
            children: [
              // Waypoint icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${navigationService.currentWaypointIndex + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 3.w),
              
              // Waypoint details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      navigationService.isComplete
                          ? 'Destination Reached'
                          : 'Waypoint ${navigationService.currentWaypointIndex + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${navigationService.remainingStops} ${navigationService.remainingStops == 1 ? 'stop' : 'stops'} remaining',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cancel button
              IconButton(
                icon: Icon(Icons.close),
                onPressed: onCancel,
                tooltip: 'Cancel Navigation',
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Current instruction (if available)
          if (navigationService.currentInstruction != null)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.navigation,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      navigationService.currentInstruction!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 2.h),
          
          // Next waypoint button (if not complete)
          if (!navigationService.isComplete)
            ElevatedButton.icon(
              onPressed: () {
                navigationService.advanceToNextWaypoint();
              },
              icon: Icon(Icons.arrow_forward),
              label: Text('Next Waypoint'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = navigationService.progress;
    final totalStops = navigationService.allStops.length;
    final currentStop = navigationService.currentWaypointIndex;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$currentStop / $totalStops stops',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
