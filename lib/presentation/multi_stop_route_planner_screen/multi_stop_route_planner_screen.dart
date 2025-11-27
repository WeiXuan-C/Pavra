import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:geocoding/geocoding.dart';

import '../../l10n/app_localizations.dart';
import '../../core/services/multi_stop_route_service.dart';
import '../../core/services/directions_service.dart';
import '../../core/services/map_service.dart';
import '../../core/services/route_optimizer.dart';
import '../../core/services/saved_route_service.dart';
import '../../core/services/saved_location_service.dart';
import '../../core/services/multi_stop_navigation_service.dart';
import '../../core/api/saved_route/saved_route_api.dart';
import '../../core/api/notification/notification_api.dart';
import '../../core/services/notification_helper_service.dart';
import '../../data/repositories/saved_route_repository.dart';
import '../../data/models/saved_location_model.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/accessibility_utils.dart';
import 'widgets/multi_stop_navigation_panel.dart';


class MultiStopRoutePlannerScreen extends StatefulWidget {
  const MultiStopRoutePlannerScreen({super.key});

  @override
  State<MultiStopRoutePlannerScreen> createState() => _MultiStopRoutePlannerScreenState();
}

class _MultiStopRoutePlannerScreenState extends State<MultiStopRoutePlannerScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  late final MultiStopRouteService _multiStopRouteService;
  late final RouteOptimizer _routeOptimizer;
  late final SavedRouteService _savedRouteService;
  late final SavedLocationService _savedLocationService;
  late final MultiStopNavigationService _navigationService;

  final List<RoutePoint> _routePoints = [];
  String _selectedTravelMode = 'driving';
  MultiStopRoute? _currentRoute;
  bool _isCalculating = false;
  bool _isOptimizing = false;
  bool _showOptimizeButton = false;
  
  // Route issues
  List<Map<String, dynamic>> _routeIssues = [];
  bool _showCriticalWarning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final currentLocation = args?['currentLocation'] as LatLng?;
    final initialDestination = args?['initialDestination'] as LatLng?;
    final initialDestinationName = args?['initialDestinationName'] as String?;
    final savedRoute = args?['savedRoute'] as SavedRouteWithWaypoints?;
    
    // Only initialize once
    if (_routePoints.isEmpty) {
      // Initialize services
      final directionsService = DirectionsService();
      final mapService = MapService();
      _multiStopRouteService = MultiStopRouteService(
        directionsService: directionsService,
        mapService: mapService,
      );
      _routeOptimizer = RouteOptimizer();
      _navigationService = MultiStopNavigationService();
      
      final notificationHelper = NotificationHelperService(NotificationApi());
      final api = SavedRouteApi(supabase, notificationHelper);
      final repository = SavedRouteRepository(api);
      _savedRouteService = SavedRouteService(repository);
      _savedLocationService = SavedLocationService(repository);
      
      // Listen to navigation service changes
      _navigationService.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      // Load saved route if provided
      if (savedRoute != null) {
        _loadSavedRoute(savedRoute);
      } else {
        // Initialize route points
        if (currentLocation != null) {
          _routePoints.add(RoutePoint(
            location: currentLocation,
            address: 'Current Location',
            type: RoutePointType.start,
          ));
        } else {
          _routePoints.add(RoutePoint(
            location: null,
            address: '',
            type: RoutePointType.start,
          ));
        }

        // Add initial destination if provided
        if (initialDestination != null) {
          _routePoints.add(RoutePoint(
            location: initialDestination,
            address: initialDestinationName ?? 'Destination',
            type: RoutePointType.destination,
          ));
        } else {
          _routePoints.add(RoutePoint(
            location: null,
            address: '',
            type: RoutePointType.destination,
          ));
        }

        _updateMarkers();
      }
    }
  }

  /// Load a saved route into the planner
  void _loadSavedRoute(SavedRouteWithWaypoints savedRoute) {
    setState(() {
      _routePoints.clear();
      
      // Add start point
      _routePoints.add(RoutePoint(
        location: savedRoute.start,
        address: 'Start',
        type: RoutePointType.start,
      ));
      
      // Add waypoints
      for (int i = 0; i < savedRoute.waypoints.length; i++) {
        _routePoints.add(RoutePoint(
          location: savedRoute.waypoints[i],
          address: 'Waypoint ${i + 1}',
          type: RoutePointType.waypoint,
        ));
      }
      
      // Add destination
      _routePoints.add(RoutePoint(
        location: savedRoute.destination,
        address: 'Destination',
        type: RoutePointType.destination,
      ));
      
      // Set travel mode
      _selectedTravelMode = savedRoute.travelMode;
      
      _updateMarkers();
      _updateOptimizeButtonVisibility();
    });
    
    // Calculate the route
    _calculateRoute();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitMapToRoute();
  }

  void _addWaypoint() {
    setState(() {
      // Insert before the last item (destination)
      _routePoints.insert(
        _routePoints.length - 1,
        RoutePoint(
          location: null,
          address: '',
          type: RoutePointType.waypoint,
        ),
      );
      _updateOptimizeButtonVisibility();
    });
  }

  void _removeWaypoint(int index) {
    if (_routePoints.length > 2 && _routePoints[index].type == RoutePointType.waypoint) {
      setState(() {
        _routePoints.removeAt(index);
        _updateMarkers();
        _updateOptimizeButtonVisibility();
      });
      _calculateRoute();
    }
  }



  void _updatePoint(int index, LatLng location, String address) {
    setState(() {
      _routePoints[index] = RoutePoint(
        location: location,
        address: address,
        type: _routePoints[index].type,
      );
      _updateMarkers();
    });
    _calculateRoute();
  }

  void _updateOptimizeButtonVisibility() {
    // Show optimize button when there are 3+ waypoints (excluding start and destination)
    final waypointCount = _routePoints.where((p) => p.type == RoutePointType.waypoint).length;
    setState(() {
      _showOptimizeButton = waypointCount >= 3;
    });
  }

  void _updateMarkers() {
    _markers.clear();
    
    // Add route point markers
    for (int i = 0; i < _routePoints.length; i++) {
      final point = _routePoints[i];
      if (point.location != null) {
        BitmapDescriptor icon;
        String label = '${i + 1}';
        
        // Customize marker based on type
        if (point.type == RoutePointType.start) {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        } else if (point.type == RoutePointType.destination) {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        } else {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        }

        _markers.add(
          Marker(
            markerId: MarkerId('point_$i'),
            position: point.location!,
            icon: icon,
            infoWindow: InfoWindow(
              title: label,
              snippet: point.address,
            ),
          ),
        );
      }
    }
    
    // Add issue markers
    for (final issue in _routeIssues) {
      final lat = issue['latitude'] as double?;
      final lng = issue['longitude'] as double?;
      final id = issue['id'] as String;
      final severity = issue['severity'] as String?;
      
      if (lat != null && lng != null) {
        final markerColor = _getSeverityColor(severity ?? 'moderate');
        
        _markers.add(
          Marker(
            markerId: MarkerId('issue_$id'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            infoWindow: InfoWindow(
              title: issue['title'] as String? ?? 'Road Issue',
              snippet: severity?.toUpperCase() ?? 'MODERATE',
            ),
            onTap: () => _showIssueDetails(issue),
          ),
        );
      }
    }
  }
  
  /// Get marker color based on severity
  double _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return BitmapDescriptor.hueRose; // Dark red/pink
      case 'high':
        return BitmapDescriptor.hueRed;
      case 'moderate':
        return BitmapDescriptor.hueYellow;
      case 'low':
        return BitmapDescriptor.hueAzure; // Light blue
      case 'minor':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueYellow;
    }
  }
  
  /// Show issue details dialog
  void _showIssueDetails(Map<String, dynamic> issue) {
    final theme = Theme.of(context);
    final severity = issue['severity'] as String? ?? 'moderate';
    final title = issue['title'] as String? ?? 'Road Issue';
    final description = issue['description'] as String? ?? 'No description available';
    final address = issue['address'] as String? ?? 'Unknown location';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _getSeverityColorForUI(severity),
              size: 28,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: _getSeverityColorForUI(severity).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                severity.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _getSeverityColorForUI(severity),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            
            // Description
            Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            
            // Address
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    address,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  /// Get UI color for severity
  Color _getSeverityColorForUI(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade900;
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      case 'minor':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Future<void> _calculateRoute() async {
    // Check if we have at least start and destination
    if (_routePoints.first.location == null || _routePoints.last.location == null) {
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final start = _routePoints.first.location!;
      final destination = _routePoints.last.location!;
      final waypoints = _routePoints
          .skip(1)
          .take(_routePoints.length - 2)
          .where((p) => p.location != null)
          .map((p) => p.location!)
          .toList();

      final route = await _multiStopRouteService.calculateRoute(
        start: start,
        waypoints: waypoints,
        destination: destination,
        travelMode: _selectedTravelMode,
      );

      if (route != null && mounted) {
        setState(() {
          _currentRoute = route;
          _polylines.clear();
          
          // Draw route polyline
          Color routeColor = _getTravelModeColor(_selectedTravelMode);
          
          _polylines.add(
            Polyline(
              polylineId: PolylineId('multi_stop_route'),
              points: route.allPolylinePoints,
              color: routeColor,
              width: 6,
              geodesic: true,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        });

        _fitMapToRoute();
        
        // Load issues along the route
        await _loadRouteIssues();
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to calculate route',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }
  
  /// Load issues along the route
  Future<void> _loadRouteIssues() async {
    if (_currentRoute == null) return;
    
    try {
      final issues = await _multiStopRouteService.getIssuesAlongRoute(
        routePoints: _currentRoute!.allPolylinePoints,
        radiusMiles: 1.0,
      );
      
      if (mounted) {
        setState(() {
          _routeIssues = issues;
          _updateMarkers();
          
          // Check for critical issues
          _showCriticalWarning = issues.any((issue) {
            final severity = issue['severity'] as String?;
            return severity?.toLowerCase() == 'critical';
          });
          
          // Show warning if critical issues found
          if (_showCriticalWarning) {
            _showCriticalIssueWarning();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading route issues: $e');
    }
  }
  
  /// Show critical issue warning notification
  void _showCriticalIssueWarning() {
    final criticalCount = _routeIssues.where((issue) {
      final severity = issue['severity'] as String?;
      return severity?.toLowerCase() == 'critical';
    }).length;
    
    FeedbackUtils.showWarning(
      context,
      'Warning: $criticalCount critical ${criticalCount == 1 ? 'issue' : 'issues'} found along route',
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'View',
        textColor: Colors.white,
        onPressed: () {
          _showIssuesSummaryDialog();
        },
      ),
    );
  }
  
  /// Show issues summary dialog
  void _showIssuesSummaryDialog() {
    final theme = Theme.of(context);
    final issuesBySeverity = <String, List<Map<String, dynamic>>>{};
    
    // Group issues by severity
    for (final issue in _routeIssues) {
      final severity = issue['severity'] as String? ?? 'moderate';
      issuesBySeverity.putIfAbsent(severity, () => []).add(issue);
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Route Issues Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${_routeIssues.length} ${_routeIssues.length == 1 ? 'issue' : 'issues'} along your route:',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              
              // Display counts by severity
              ...['critical', 'high', 'moderate', 'low', 'minor'].map((severity) {
                final count = issuesBySeverity[severity]?.length ?? 0;
                if (count == 0) return SizedBox.shrink();
                
                return Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getSeverityColorForUI(severity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${severity.toUpperCase()}: $count',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _optimizeRoute() async {
    if (_routePoints.length < 4) return; // Need at least start + 2 waypoints + destination

    // Save original route points in case optimization fails
    final originalRoutePoints = List<RoutePoint>.from(_routePoints);

    setState(() {
      _isOptimizing = true;
    });

    try {
      final start = _routePoints.first.location!;
      final destination = _routePoints.last.location!;
      final waypoints = _routePoints
          .skip(1)
          .take(_routePoints.length - 2)
          .where((p) => p.location != null)
          .map((p) => p.location!)
          .toList();

      final result = await _routeOptimizer.optimizeNearestNeighbor(
        start: start,
        waypoints: waypoints,
        destination: destination,
      );

      if (mounted) {
        // Reorder waypoints based on optimization
        final optimizedPoints = <RoutePoint>[
          _routePoints.first, // Keep start
        ];

        // Add optimized waypoints
        for (final optimizedLocation in result.optimizedWaypoints) {
          // Find the corresponding route point
          final matchingPoint = _routePoints.firstWhere(
            (p) => p.location == optimizedLocation,
            orElse: () => RoutePoint(
              location: optimizedLocation,
              address: 'Waypoint',
              type: RoutePointType.waypoint,
            ),
          );
          optimizedPoints.add(matchingPoint);
        }

        optimizedPoints.add(_routePoints.last); // Keep destination

        setState(() {
          _routePoints.clear();
          _routePoints.addAll(optimizedPoints);
          _updateMarkers();
        });

        // Recalculate route with optimized order
        await _calculateRoute();

        // Show detailed optimization results dialog
        if (mounted) {
          _showOptimizationResultsDialog(result);
        }
      }
    } catch (e) {
      debugPrint('Error optimizing route: $e');
      
      // Maintain original route if optimization fails
      if (mounted) {
        setState(() {
          _routePoints.clear();
          _routePoints.addAll(originalRoutePoints);
          _updateMarkers();
        });

        FeedbackUtils.showError(
          context,
          'Failed to optimize route. Original route maintained.',
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOptimizing = false;
        });
      }
    }
  }

  void _showOptimizationResultsDialog(OptimizationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 2.w),
            Text('Route Optimized!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your route has been optimized for efficiency.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            _buildOptimizationMetric(
              'Original Distance',
              '${(result.originalDistance / 1000).toStringAsFixed(2)} km',
              Icons.straighten,
            ),
            SizedBox(height: 1.h),
            _buildOptimizationMetric(
              'Optimized Distance',
              '${(result.optimizedDistance / 1000).toStringAsFixed(2)} km',
              Icons.straighten,
            ),
            SizedBox(height: 1.h),
            _buildOptimizationMetric(
              'Distance Savings',
              '${result.savingsPercent.toStringAsFixed(1)}%',
              Icons.trending_down,
              color: Colors.green,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Waypoints have been reordered for optimal routing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationMetric(String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _saveRoute() async {
    if (_currentRoute == null) {
      FeedbackUtils.showInfo(
        context,
        'Please calculate a route first',
      );
      return;
    }

    // Show dialog to enter route name
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Route'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Route Name',
            hintText: 'Enter a name for this route',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        await _savedRouteService.saveRoute(
          name: nameController.text,
          start: _routePoints.first.location!,
          waypoints: _routePoints
              .skip(1)
              .take(_routePoints.length - 2)
              .where((p) => p.location != null)
              .map((p) => p.location!)
              .toList(),
          destination: _routePoints.last.location!,
          travelMode: _selectedTravelMode,
          totalDistance: _currentRoute!.totalDistanceValue / 1000.0, // Convert to km
        );

        if (mounted) {
          FeedbackUtils.showSuccess(
            context,
            'Route saved successfully',
          );
        }
      } catch (e) {
        debugPrint('Error saving route: $e');
        if (mounted) {
          FeedbackUtils.showError(
            context,
            'Failed to save route',
          );
        }
      }
    }
  }

  /// Start navigation for the current route
  void _startNavigation() {
    if (_currentRoute == null) {
      FeedbackUtils.showInfo(
        context,
        'Please calculate a route first',
      );
      return;
    }

    _navigationService.startNavigation(_currentRoute!);
    
    FeedbackUtils.showSuccess(
      context,
      'Navigation started',
      duration: const Duration(seconds: 2),
    );
  }

  /// Cancel navigation
  void _cancelNavigation() {
    _navigationService.cancelNavigation();
    
    FeedbackUtils.showInfo(
      context,
      'Navigation cancelled',
      duration: const Duration(seconds: 2),
    );
  }

  void _fitMapToRoute() {
    if (_mapController == null) return;

    final locations = _routePoints
        .where((p) => p.location != null)
        .map((p) => p.location!)
        .toList();

    if (locations.isEmpty) return;

    if (locations.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(locations.first, 15.0),
      );
      return;
    }

    // Calculate bounds
    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Color _getTravelModeColor(String mode) {
    switch (mode) {
      case 'driving':
        return Colors.blue;
      case 'walking':
        return Colors.orange;
      case 'bicycling':
        return Colors.purple;
      case 'transit':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
  
  /// Build issue count badges by severity
  List<Widget> _buildIssueBadges(ThemeData theme) {
    final issuesBySeverity = <String, int>{};
    
    // Count issues by severity
    for (final issue in _routeIssues) {
      final severity = issue['severity'] as String? ?? 'moderate';
      issuesBySeverity[severity] = (issuesBySeverity[severity] ?? 0) + 1;
    }
    
    final badges = <Widget>[];
    
    // Show badges for severities that have issues (in order of importance)
    for (final severity in ['critical', 'high', 'moderate', 'low', 'minor']) {
      final count = issuesBySeverity[severity];
      if (count != null && count > 0) {
        badges.add(
          Padding(
            padding: EdgeInsets.only(top: 0.5.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getSeverityColorForUI(severity),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  '$count ${severity.substring(0, 1).toUpperCase()}${severity.substring(1)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Plan Multi-Stop Route'),
        actions: [
          if (_currentRoute != null && !_navigationService.isNavigating)
            Semantics(
              label: AccessibilityUtils.navigationButtonLabel(false),
              button: true,
              child: IconButton(
                icon: Icon(Icons.navigation),
                onPressed: () async {
                  await AccessibilityUtils.buttonPressed();
                  _startNavigation();
                },
                tooltip: 'Start Navigation',
              ),
            ),
          if (_currentRoute != null && !_navigationService.isNavigating)
            Semantics(
              label: 'Save route. Tap to save this route for later use.',
              button: true,
              child: IconButton(
                icon: Icon(Icons.save),
                onPressed: () async {
                  await AccessibilityUtils.buttonPressed();
                  _saveRoute();
                },
                tooltip: 'Save Route',
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Map view
              Expanded(
                flex: 3,
                child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _routePoints.isNotEmpty && _routePoints.first.location != null
                        ? _routePoints.first.location!
                        : LatLng(37.7749, -122.4194),
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
                
                // Route info overlay
                if (_currentRoute != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Semantics(
                      label: AccessibilityUtils.routeInfoLabel(
                        _currentRoute!.totalDistance,
                        _currentRoute!.totalDuration,
                        _routePoints.length,
                      ),
                      readOnly: true,
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.straighten, color: theme.colorScheme.primary),
                                SizedBox(height: 0.5.h),
                                Text(
                                  _currentRoute!.totalDistance,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Distance',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.access_time, color: theme.colorScheme.primary),
                                SizedBox(height: 0.5.h),
                                Text(
                                  _currentRoute!.totalDuration,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Duration',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.location_on, color: theme.colorScheme.primary),
                                SizedBox(height: 0.5.h),
                                Text(
                                  '${_routePoints.length}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Stops',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Issue count badges
                if (_routeIssues.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Semantics(
                      label: '${_routeIssues.length} road issues found along route. Tap to view details.',
                      button: true,
                      child: GestureDetector(
                        onTap: () async {
                          await AccessibilityUtils.buttonPressed();
                          _showIssuesSummaryDialog();
                        },
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.primary),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Issues',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              ..._buildIssueBadges(theme),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Loading indicator
                if (_isCalculating || _isOptimizing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 2.h),
                              Text(
                                _isOptimizing ? 'Optimizing route...' : 'Calculating route...',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

              // Route points list
              Expanded(
                flex: 2,
                child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                children: [
                  // Compact header with travel mode
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).route_routeStops,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        // Compact travel mode selector
                        Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCompactTravelModeButton('driving', Icons.directions_car, 'Car'),
                              SizedBox(width: 1.w),
                              _buildCompactTravelModeButton('walking', Icons.directions_walk, 'Walk'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Route points with better visibility
                  Expanded(
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        itemCount: _routePoints.length,
                        itemBuilder: (context, index) {
                          return _buildRoutePointTile(index, key: ValueKey(index));
                        },
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      children: [
                        // Add waypoint button
                        if (_routePoints.length < 10)
                          Semantics(
                            label: 'Add waypoint. Tap to add an intermediate stop to your route.',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await AccessibilityUtils.buttonPressed();
                                _addWaypoint();
                              },
                              icon: Icon(Icons.add_location_alt, size: 20),
                              label: Text('Add Waypoint'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                          ),

                        SizedBox(height: 1.h),

                        // Optimize button
                        if (_showOptimizeButton)
                          Semantics(
                            label: AccessibilityUtils.optimizeRouteLabel(
                              _routePoints.where((p) => p.type == RoutePointType.waypoint).length,
                            ),
                            button: true,
                            enabled: !_isOptimizing,
                            child: ElevatedButton.icon(
                              onPressed: _isOptimizing ? null : () async {
                                await AccessibilityUtils.optimizationStarted();
                                await _optimizeRoute();
                                await AccessibilityUtils.optimizationComplete();
                              },
                              icon: Icon(Icons.route, size: 20),
                              label: Text('Optimize Route'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                                backgroundColor: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
          
          // Navigation panel (overlay at bottom)
          if (_navigationService.isNavigating)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MultiStopNavigationPanel(
                navigationService: _navigationService,
                onCancel: _cancelNavigation,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoutePointTile(int index, {required Key key}) {
    final point = _routePoints[index];
    final theme = Theme.of(context);
    final isLast = index == _routePoints.length - 1;

    Color iconColor;
    String hint;
    String semanticLabel;
    IconData pointIcon;

    switch (point.type) {
      case RoutePointType.start:
        iconColor = Colors.green;
        pointIcon = Icons.trip_origin;
        hint = AppLocalizations.of(context).route_enterStartingPoint;
        semanticLabel = AccessibilityUtils.routePointLabel(index, _routePoints.length, 'start');
        break;
      case RoutePointType.waypoint:
        iconColor = Colors.orange;
        pointIcon = Icons.location_on;
        hint = AppLocalizations.of(context).route_enterStop(index);
        semanticLabel = AccessibilityUtils.routePointLabel(index, _routePoints.length, 'waypoint');
        break;
      case RoutePointType.destination:
        iconColor = Colors.red;
        pointIcon = Icons.place;
        hint = AppLocalizations.of(context).route_enterDestination;
        semanticLabel = AccessibilityUtils.routePointLabel(index, _routePoints.length, 'destination');
        break;
    }

    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        key: key,
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: point.location != null 
                ? iconColor.withValues(alpha: 0.3)
                : theme.dividerColor,
            width: point.location != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon indicator
            Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      pointIcon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 3,
                    height: 20,
                    margin: EdgeInsets.symmetric(vertical: 1.h),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 3.w),

            // Search field
            Expanded(
              child: RoutePointSearchField(
                initialAddress: point.address,
                hint: hint,
                savedLocationService: _savedLocationService,
                onLocationSelected: (location, address) {
                  _updatePoint(index, location, address);
                },
              ),
            ),

            // Remove button (only for waypoints)
            if (point.type == RoutePointType.waypoint)
              Semantics(
                label: 'Remove waypoint $index',
                button: true,
                child: IconButton(
                  icon: Icon(Icons.close, size: 22, color: theme.colorScheme.error),
                  onPressed: () async {
                    await AccessibilityUtils.buttonPressed();
                    _removeWaypoint(index);
                  },
                  padding: EdgeInsets.all(2.w),
                  constraints: BoxConstraints(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTravelModeButton(String mode, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedTravelMode == mode;

    return Semantics(
      label: AccessibilityUtils.travelModeLabel(mode, isSelected),
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () async {
          await AccessibilityUtils.buttonPressed();
          setState(() {
            _selectedTravelMode = mode;
          });
          _calculateRoute();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              SizedBox(width: 1.5.w),
              Text(
                mode == 'driving' 
                    ? AppLocalizations.of(context).route_car 
                    : AppLocalizations.of(context).route_walk,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _navigationService.dispose();
    super.dispose();
  }
}

// Route point search field with autocomplete
class RoutePointSearchField extends StatefulWidget {
  final String initialAddress;
  final String hint;
  final SavedLocationService savedLocationService;
  final Function(LatLng, String) onLocationSelected;

  const RoutePointSearchField({
    super.key,
    required this.initialAddress,
    required this.hint,
    required this.savedLocationService,
    required this.onLocationSelected,
  });

  @override
  State<RoutePointSearchField> createState() => _RoutePointSearchFieldState();
}

class _RoutePointSearchFieldState extends State<RoutePointSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialAddress;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        // Get full address
        String fullAddress = query;
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            fullAddress = [
              place.street,
              place.locality,
              place.administrativeArea,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          }
        } catch (e) {
          debugPrint('Error getting placemark: $e');
        }

        widget.onLocationSelected(latLng, fullAddress);
        _controller.text = fullAddress;
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Location not found',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _showSavedLocationsDialog() async {
    try {
      final savedLocations = await widget.savedLocationService.getSavedLocations();

      if (!mounted) return;

      if (savedLocations.isEmpty) {
        FeedbackUtils.showInfo(
          context,
          'No saved locations found',
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final selectedLocation = await showDialog<SavedLocationModel>(
        context: context,
        builder: (context) => _SavedLocationsDialog(
          savedLocations: savedLocations,
        ),
      );

      if (selectedLocation != null) {
        final latLng = LatLng(selectedLocation.latitude, selectedLocation.longitude);
        final address = selectedLocation.address ?? selectedLocation.locationName;
        
        widget.onLocationSelected(latLng, address);
        _controller.text = selectedLocation.label;
      }
    } catch (e) {
      debugPrint('Error loading saved locations: $e');
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to load saved locations',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.search, size: 20),
                    onPressed: () => _searchLocation(_controller.text),
                  )
                : null,
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _searchLocation(value);
            }
          },
        ),
        SizedBox(height: 0.5.h),
        TextButton.icon(
          onPressed: _showSavedLocationsDialog,
          icon: Icon(Icons.star, size: 16),
          label: Text('Choose from saved locations'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            minimumSize: Size(0, 32),
          ),
        ),
      ],
    );
  }
}

// Data models
enum RoutePointType { start, waypoint, destination }

class RoutePoint {
  final LatLng? location;
  final String address;
  final RoutePointType type;

  RoutePoint({
    required this.location,
    required this.address,
    required this.type,
  });
}

// Saved Locations Dialog
class _SavedLocationsDialog extends StatefulWidget {
  final List<SavedLocationModel> savedLocations;

  const _SavedLocationsDialog({
    required this.savedLocations,
  });

  @override
  State<_SavedLocationsDialog> createState() => _SavedLocationsDialogState();
}

class _SavedLocationsDialogState extends State<_SavedLocationsDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedLocationModel> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _filteredLocations = widget.savedLocations;
    _searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = widget.savedLocations;
      } else {
        _filteredLocations = widget.savedLocations.where((location) {
          return location.label.toLowerCase().contains(query) ||
              location.locationName.toLowerCase().contains(query) ||
              (location.address?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 70.h,
          maxWidth: 90.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Icon(Icons.star, color: theme.colorScheme.primary),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Choose Saved Location',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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

            // Search field
            Padding(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search saved locations...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                ),
              ),
            ),

            // Locations list
            Expanded(
              child: _filteredLocations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No saved locations'
                              : 'No locations match your search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        return _buildLocationTile(location, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(SavedLocationModel location, ThemeData theme) {
    return Semantics(
      label: AccessibilityUtils.savedLocationLabel(location.label, location.locationName),
      button: true,
      child: InkWell(
        onTap: () async {
          await AccessibilityUtils.buttonPressed();
          if (mounted) {
            Navigator.pop(context, location);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          margin: EdgeInsets.only(bottom: 1.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(location.icon),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),

              SizedBox(width: 3.w),

              // Location info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Text(
                      location.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),

                    // Location name
                    Text(
                      location.locationName,
                      style: theme.textTheme.bodyMedium,
                    ),

                    // Address
                    if (location.address != null && location.address!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 0.5.h),
                        child: Text(
                          location.address!,
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

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'hospital':
        return Icons.local_hospital;
      case 'gym':
        return Icons.fitness_center;
      case 'park':
        return Icons.park;
      case 'airport':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }
}
