import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/services/saved_route_service.dart';
import '../../data/repositories/saved_route_repository.dart';
import '../../core/api/saved_route/saved_route_api.dart';
import '../../core/utils/feedback_utils.dart';
import '../../widgets/skeleton_loader.dart';
import '../layouts/header_layout.dart';

/// Saved Routes Screen
/// Displays list of saved routes with preview, load, delete, and share functionality
class SavedRoutesScreen extends StatefulWidget {
  static const String routeName = '/saved-routes';

  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  late SavedRouteService _routeService;
  List<SavedRouteWithWaypoints> _routes = [];
  bool _isLoading = true;
  SavedRouteWithWaypoints? _selectedRoute;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    final api = SavedRouteApi(supabase);
    final repository = SavedRouteRepository(api);
    _routeService = SavedRouteService(repository);
    _loadRoutes();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Load saved routes
  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);

    try {
      final routes = await _routeService.getSavedRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to load routes: $e',
        );
      }
    }
  }

  /// Show route preview on map
  void _showRoutePreview(SavedRouteWithWaypoints route) {
    setState(() {
      _selectedRoute = route;
      _updateMapForRoute(route);
    });
  }

  /// Update map markers and polylines for selected route
  void _updateMapForRoute(SavedRouteWithWaypoints route) {
    _markers.clear();
    _polylines.clear();

    // Add start marker
    _markers.add(
      Marker(
        markerId: MarkerId('start'),
        position: route.start,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '1',
          snippet: 'Start',
        ),
      ),
    );

    // Add waypoint markers
    for (int i = 0; i < route.waypoints.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('waypoint_$i'),
          position: route.waypoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: '${i + 2}',
            snippet: 'Waypoint ${i + 1}',
          ),
        ),
      );
    }

    // Add destination marker
    _markers.add(
      Marker(
        markerId: MarkerId('destination'),
        position: route.destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: '${route.waypoints.length + 2}',
          snippet: 'Destination',
        ),
      ),
    );

    // Create polyline points (simplified - just connecting the points)
    final polylinePoints = <LatLng>[
      route.start,
      ...route.waypoints,
      route.destination,
    ];

    _polylines.add(
      Polyline(
        polylineId: PolylineId('route_preview'),
        points: polylinePoints,
        color: _getTravelModeColor(route.travelMode),
        width: 5,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );

    // Fit map to show all markers
    _fitMapToRoute(polylinePoints);
  }

  /// Fit map camera to show all route points
  void _fitMapToRoute(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15.0),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  /// Get color based on travel mode
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

  /// Load route into route planner
  void _loadRoute(SavedRouteWithWaypoints route) {
    Navigator.pushNamed(
      context,
      '/multi-stop-route-planner',
      arguments: {
        'savedRoute': route,
      },
    );
  }

  /// Delete route with confirmation
  Future<void> _deleteRoute(SavedRouteWithWaypoints route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text(
          'Are you sure you want to delete "${route.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _routeService.deleteRoute(route.id);

        if (mounted) {
          FeedbackUtils.showSuccess(
            context,
            'Route deleted successfully',
          );
          
          // Clear selection if deleted route was selected
          if (_selectedRoute?.id == route.id) {
            setState(() {
              _selectedRoute = null;
              _markers.clear();
              _polylines.clear();
            });
          }
          
          _loadRoutes();
        }
      } catch (e) {
        if (mounted) {
          FeedbackUtils.showError(
            context,
            'Failed to delete route: $e',
          );
        }
      }
    }
  }

  /// Share route as text
  Future<void> _shareRoute(SavedRouteWithWaypoints route) async {
    try {
      final shareText = _routeService.shareRouteAsText(route);
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));
      
      if (mounted) {
        FeedbackUtils.showSuccess(
          context,
          'Route copied to clipboard',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to share route: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderLayout(
        title: 'Saved Routes',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoutes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Row(
              children: [
                // Skeleton loaders for routes list
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    padding: EdgeInsets.all(3.w),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return const RouteSkeletonLoader();
                    },
                  ),
                ),
                // Map placeholder
                Expanded(
                  flex: 3,
                  child: _buildMapPlaceholder(),
                ),
              ],
            )
          : _routes.isEmpty
              ? _buildEmptyState()
              : Row(
                  children: [
                    // Routes list
                    Expanded(
                      flex: 2,
                      child: RefreshIndicator(
                        onRefresh: _loadRoutes,
                        child: ListView.builder(
                          padding: EdgeInsets.all(3.w),
                          itemCount: _routes.length,
                          itemBuilder: (context, index) {
                            final route = _routes[index];
                            final isSelected = _selectedRoute?.id == route.id;
                            return _buildRouteCard(route, isSelected);
                          },
                        ),
                      ),
                    ),

                    // Map preview
                    Expanded(
                      flex: 3,
                      child: _selectedRoute == null
                          ? _buildMapPlaceholder()
                          : _buildMapPreview(),
                    ),
                  ],
                ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved routes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create and save routes from the route planner',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/multi-stop-route-planner');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Route'),
          ),
        ],
      ),
    );
  }

  /// Build map placeholder when no route is selected
  Widget _buildMapPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Select a route to preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build map preview
  Widget _buildMapPreview() {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        if (_selectedRoute != null) {
          _updateMapForRoute(_selectedRoute!);
        }
      },
      initialCameraPosition: CameraPosition(
        target: _selectedRoute?.start ?? LatLng(37.7749, -122.4194),
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  /// Build route card
  Widget _buildRouteCard(SavedRouteWithWaypoints route, bool isSelected) {
    final theme = Theme.of(context);
    final waypointCount = route.waypoints.length;
    final totalStops = waypointCount + 2; // start + waypoints + destination

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showRoutePreview(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route name and travel mode
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _getTravelModeIcon(route.travelMode),
                    color: _getTravelModeColor(route.travelMode),
                    size: 24,
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Route info
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Text(
                    '$totalStops stops',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  if (waypointCount > 0) ...[
                    SizedBox(width: 3.w),
                    Text(
                      '($waypointCount waypoints)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),

              if (route.totalDistance != null) ...[
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 1.w),
                    Text(
                      '${route.totalDistance!.toStringAsFixed(1)} km',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 0.5.h),

              // Created date
              Text(
                'Created: ${_formatDate(route.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),

              SizedBox(height: 1.h),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _loadRoute(route),
                    icon: Icon(Icons.edit_location, size: 18),
                    label: Text('Load'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  TextButton.icon(
                    onPressed: () => _shareRoute(route),
                    icon: Icon(Icons.share, size: 18),
                    label: Text('Share'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteRoute(route),
                    tooltip: 'Delete',
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get icon for travel mode
  IconData _getTravelModeIcon(String mode) {
    switch (mode) {
      case 'driving':
        return Icons.directions_car;
      case 'walking':
        return Icons.directions_walk;
      case 'bicycling':
        return Icons.directions_bike;
      case 'transit':
        return Icons.directions_transit;
      default:
        return Icons.directions_car;
    }
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
