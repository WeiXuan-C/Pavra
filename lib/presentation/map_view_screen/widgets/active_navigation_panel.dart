import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/directions_service.dart';
import '../../../l10n/app_localizations.dart';

class ActiveNavigationPanel extends StatelessWidget {
  final DirectionsResult directions;
  final VoidCallback onEnd;
  final VoidCallback onViewSteps;

  const ActiveNavigationPanel({
    super.key,
    required this.directions,
    required this.onEnd,
    required this.onViewSteps,
  });

  IconData _getManeuverIcon(String? maneuver) {
    if (maneuver == null) return Icons.arrow_upward;
    
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'merge':
        return Icons.merge;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'ramp-left':
      case 'ramp-right':
        return Icons.ramp_left;
      case 'fork-left':
      case 'fork-right':
        return Icons.fork_left;
      default:
        return Icons.arrow_upward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = directions.steps.first;
    final nextStep = directions.steps.length > 1 ? directions.steps[1] : null;
    
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current instruction
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getManeuverIcon(currentStep.maneuver),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentStep.distance,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentStep.instruction,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ETA and distance info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: directions.duration,
                  theme: theme,
                ),
                Container(
                  height: 4.h,
                  width: 1,
                  color: theme.dividerColor,
                ),
                _buildInfoChip(
                  icon: Icons.straighten,
                  label: directions.distance,
                  theme: theme,
                ),
                Container(
                  height: 4.h,
                  width: 1,
                  color: theme.dividerColor,
                ),
                _buildInfoChip(
                  icon: Icons.place,
                  label: '${directions.steps.length} steps',
                  theme: theme,
                ),
              ],
            ),
          ),

          // Next step preview
          if (nextStep != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Row(
                children: [
                  Icon(
                    _getManeuverIcon(nextStep.maneuver),
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context).navigation_then} ${nextStep.instruction}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(2.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewSteps,
                    icon: Icon(Icons.list, size: 18),
                    label: Text(AppLocalizations.of(context).navigation_steps),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEnd,
                    icon: Icon(Icons.close, size: 18),
                    label: Text(AppLocalizations.of(context).navigation_end),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        SizedBox(width: 1.w),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
