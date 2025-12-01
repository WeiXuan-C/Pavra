import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/directions_service.dart';
import '../../../l10n/app_localizations.dart';

class NavigationBottomSheet extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String? destinationTitle;
  final Function(DirectionsResult, String travelMode) onDirectionsReceived;

  const NavigationBottomSheet({
    super.key,
    required this.origin,
    required this.destination,
    this.destinationTitle,
    required this.onDirectionsReceived,
  });

  @override
  State<NavigationBottomSheet> createState() => _NavigationBottomSheetState();
}

class _NavigationBottomSheetState extends State<NavigationBottomSheet> {
  final DirectionsService _directionsService = DirectionsService();
  
  String _selectedMode = 'driving';
  bool _isLoading = true;
  final Map<String, DirectionsResult?> _cachedDirections = {};
  String? _error;

  List<Map<String, dynamic>> get _travelModes => [
    {
      'mode': 'driving',
      'icon': Icons.directions_car,
      'label': AppLocalizations.of(context).navigation_drive,
      'color': Colors.blue,
    },
    {
      'mode': 'walking',
      'icon': Icons.directions_walk,
      'label': AppLocalizations.of(context).navigation_walk,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDirections(_selectedMode);
  }

  Future<void> _loadDirections(String mode) async {
    if (_cachedDirections.containsKey(mode)) {
      setState(() {
        _selectedMode = mode;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final directions = await _directionsService.getDirections(
      origin: widget.origin,
      destination: widget.destination,
      travelMode: mode,
    );

    if (mounted) {
      setState(() {
        _cachedDirections[mode] = directions;
        _selectedMode = mode;
        _isLoading = false;
        if (directions == null) {
          final modeLabel = mode == 'driving' ? AppLocalizations.of(context).navigation_drive : AppLocalizations.of(context).navigation_walk;
          _error = AppLocalizations.of(context).navigation_noRouteAvailable(modeLabel);
        }
      });
    }
  }

  DirectionsResult? get _currentDirections => _cachedDirections[_selectedMode];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: 85.h,
        minHeight: 40.h,
      ),
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

          // Header with destination
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Icon(Icons.place, color: theme.colorScheme.primary, size: 24),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.destinationTitle ?? AppLocalizations.of(context).navigation_destination,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppLocalizations.of(context).navigation_chooseTravelMode,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Travel mode selector
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            child: Row(
              children: _travelModes.map((mode) {
                final isSelected = _selectedMode == mode['mode'];
                final hasData = _cachedDirections.containsKey(mode['mode']);
                
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: _buildTravelModeCard(
                      mode: mode['mode'],
                      icon: mode['icon'],
                      label: mode['label'],
                      color: mode['color'],
                      isSelected: isSelected,
                      hasData: hasData,
                      theme: theme,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Divider(height: 1),

          // Route information
          if (_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 2.h),
                    Text(AppLocalizations.of(context).navigation_findingBestRoute),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.orange),
                    SizedBox(height: 2.h),
                    Text(_error!, textAlign: TextAlign.center),
                    SizedBox(height: 2.h),
                    ElevatedButton(
                      onPressed: () => _loadDirections(_selectedMode),
                      child: Text(AppLocalizations.of(context).navigation_retry),
                    ),
                  ],
                ),
              ),
            )
          else if (_currentDirections != null)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ETA Card
                    _buildETACard(_currentDirections!, theme),
                    
                    SizedBox(height: 2.h),

                    // Start Navigation Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onDirectionsReceived(_currentDirections!, _selectedMode);
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.navigation, size: 24),
                        label: Text(
                          AppLocalizations.of(context).navigation_startNavigation,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Steps Preview Button
                    OutlinedButton.icon(
                      onPressed: () {
                        _showFullDirections(context, _currentDirections!, theme);
                      },
                      icon: Icon(Icons.list),
                      label: Text(AppLocalizations.of(context).navigation_viewSteps(_currentDirections!.steps.length)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Quick steps preview
                    Text(
                      AppLocalizations.of(context).navigation_firstSteps,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ..._currentDirections!.steps.take(3).map((step) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _getManeuverIcon(step.maneuver),
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.instruction,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    step.distance,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTravelModeCard({
    required String mode,
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required bool hasData,
    required ThemeData theme,
  }) {
    final directions = _cachedDirections[mode];
    
    return InkWell(
      onTap: () => _loadDirections(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (hasData && directions != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                directions.duration,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                directions.distance,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? color.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 9.sp,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (_isLoading && mode == _selectedMode) ...[
              SizedBox(height: 0.5.h),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildETACard(DirectionsResult directions, ThemeData theme) {
    final arrivalTime = DateTime.now().add(Duration(seconds: directions.durationValue));
    final timeFormat = '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')}';
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    directions.duration,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).navigation_travelTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Container(
                height: 6.h,
                width: 1,
                color: theme.dividerColor,
              ),
              Column(
                children: [
                  Text(
                    directions.distance,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).navigation_distance,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
                SizedBox(width: 1.w),
                Text(
                  AppLocalizations.of(context).navigation_arriveBy(timeFormat),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullDirections(BuildContext context, DirectionsResult directions, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h, bottom: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Icon(Icons.list, color: theme.colorScheme.primary),
                  SizedBox(width: 2.w),
                  Text(
                    AppLocalizations.of(context).navigation_turnByTurnDirections,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(4.w),
                itemCount: directions.steps.length,
                separatorBuilder: (context, index) => Divider(height: 3.h),
                itemBuilder: (context, index) {
                  final step = directions.steps[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _getManeuverIcon(step.maneuver),
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.instruction,
                              style: theme.textTheme.bodyLarge,
                            ),
                            SizedBox(height: 0.5.h),
                            Row(
                              children: [
                                Icon(Icons.straighten, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                SizedBox(width: 1.w),
                                Text(
                                  step.distance,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                SizedBox(width: 1.w),
                                Text(
                                  step.duration,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
