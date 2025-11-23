import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/services/map_service.dart';
import '../../core/services/directions_service.dart';
import '../../l10n/app_localizations.dart';
import './widgets/issue_detail_bottom_sheet.dart';
import './widgets/map_filter_bottom_sheet.dart';
import './widgets/map_search_bar.dart';
import './widgets/map_skeleton.dart';
import './widgets/nearby_issues_bottom_sheet.dart';
import './widgets/navigation_bottom_sheet.dart';
import './widgets/active_navigation_panel.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final Set<Polyline> _polylines = {};
  MapType _currentMapType = MapType.normal;
  bool _isLoading = true;
  bool _showTraffic = false;
  bool _hasLocationPermission = false;
  
  final MapService _mapService = MapService();
  double _alertRadiusMiles = 5.0;
  List<Map<String, dynamic>> _roadIssues = [];
  DirectionsResult? _currentDirections;
  bool _isNavigating = false;

  // Filter state - matching database schema
  Map<String, bool> _filters = {
    // Severity filters
    'critical': true,
    'high': true,
    'moderate': true,
    'low': true,
    'minor': true,
    // Status filters
    'draft': false,
    'submitted': true,
    'reviewed': true,
    'spam': false,
    'discard': false,
  };



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload preferences when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _reloadPreferencesAndIssues();
    }
  }

  /// Reload preferences and nearby issues (called when returning from settings)
  Future<void> _reloadPreferencesAndIssues() async {
    final previousRadius = _alertRadiusMiles;
    
    await _loadUserPreferences();
    
    // Only reload issues if radius changed
    if (_alertRadiusMiles != previousRadius) {
      await _loadNearbyIssues();
      _createMarkers();
      
      if (mounted) {
        setState(() {});
        
        // Show feedback to user
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.map_showingIssuesWithin(_alertRadiusMiles.toStringAsFixed(1)),
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadUserPreferences();
    await _loadNearbyIssues();
    _createMarkers();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final radius = await _mapService.getUserAlertRadius(user.id);
        if (mounted) {
          setState(() {
            _alertRadiusMiles = radius;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  Future<void> _loadNearbyIssues() async {
    if (_currentPosition == null) return;

    try {
      // Get all submitted and reviewed issues
      final issues = await _mapService.getNearbyIssues(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusMiles: _alertRadiusMiles,
        status: 'submitted', // Primary status, will filter more in UI
      );

      if (mounted) {
        setState(() {
          _roadIssues = issues;
        });
      }
    } catch (e) {
      debugPrint('Error loading nearby issues: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.map_failedToLoadIssues),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.map_locationServicesDisabled),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: l10n.alerts_settings,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.map_locationPermissionDenied),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: l10n.alerts_settings,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Update permission state
      if (mounted) {
        setState(() {
          _hasLocationPermission = permission == LocationPermission.whileInUse || 
                                   permission == LocationPermission.always;
        });
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Circle will be created in _buildLocationCircle() during build
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _createMarkers() {
    _markers.clear();

    for (var issue in _roadIssues) {
      if (_shouldShowIssue(issue)) {
        final lat = issue['latitude'];
        final lng = issue['longitude'];
        
        if (lat != null && lng != null) {
          final severity = issue['severity'] as String? ?? 'moderate';
          final title = issue['title'] as String?;
          final address = issue['address'] as String?;
          
          _markers.add(
            Marker(
              markerId: MarkerId(issue['id'] as String),
              position: LatLng(lat as double, lng as double),
              icon: _getMarkerIcon(severity),
              onTap: () => _showIssueDetails(issue),
              infoWindow: InfoWindow(
                title: title ?? 'Road Issue',
                snippet: address ?? 'Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
              ),
            ),
          );
        }
      }
    }
  }

  BitmapDescriptor _getMarkerIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'moderate':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'minor':
      case 'low':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  bool _shouldShowIssue(Map<String, dynamic> issue) {
    // Check if issue is deleted
    if (issue['is_deleted'] == true) return false;
    
    final severity = (issue['severity'] as String?)?.toLowerCase();
    final status = (issue['status'] as String?)?.toLowerCase();

    // Check severity filters
    if (severity != null && _filters.containsKey(severity)) {
      if (!_filters[severity]!) return false;
    }

    // Check status filters
    if (status != null && _filters.containsKey(status)) {
      if (!_filters[status]!) return false;
    }

    return true;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          14.0,
        ),
      );
    }
  }

  void _onMapTap(LatLng position) {
    // Handle map tap for creating new reports
  }

  void _onMapLongPress(LatLng position) {
    _showNewReportDialog(position);
  }

  void _showNewReportDialog(LatLng position) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.map_reportIssue),
        content: Text(l10n.map_reportIssuePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/report-submission-screen');
            },
            child: Text(l10n.report_title),
          ),
        ],
      ),
    );
  }

  void _showIssueDetails(Map<String, dynamic> issue) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IssueDetailBottomSheet(
        issue: issue,
        userLatitude: _currentPosition?.latitude,
        userLongitude: _currentPosition?.longitude,
      ),
    );

    // Handle directions action
    if (result != null && result['action'] == 'navigate') {
      _navigateToIssue(
        result['latitude'] as double,
        result['longitude'] as double,
        result['title'] as String?,
      );
    }
  }

  void _navigateToIssue(double lat, double lng, String? title) {
    if (_mapController == null || _currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current location not available')),
        );
      }
      return;
    }

    final targetLocation = LatLng(lat, lng);
    final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    // Show navigation bottom sheet with travel mode selection
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => NavigationBottomSheet(
        origin: origin,
        destination: targetLocation,
        destinationTitle: title,
        onDirectionsReceived: (directions, travelMode) {
          _startNavigation(directions, travelMode);
        },
      ),
    );
  }

  void _startNavigation(DirectionsResult directions, String travelMode) {
    setState(() {
      _currentDirections = directions;
      _isNavigating = true;
      _polylines.clear();
      
      // Draw the route with color based on travel mode
      Color routeColor;
      switch (travelMode) {
        case 'driving':
          routeColor = Colors.blue;
          break;
        case 'transit':
          routeColor = Colors.green;
          break;
        case 'walking':
          routeColor = Colors.orange;
          break;
        case 'bicycling':
          routeColor = Colors.purple;
          break;
        default:
          routeColor = Colors.blue;
      }
      
      _polylines.add(
        Polyline(
          polylineId: PolylineId('navigation_route'),
          points: directions.polylinePoints,
          color: routeColor,
          width: 6,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    });

    // Fit camera to show entire route
    final bounds = LatLngBounds(
      southwest: LatLng(
        directions.startLocation.latitude < directions.endLocation.latitude 
          ? directions.startLocation.latitude 
          : directions.endLocation.latitude,
        directions.startLocation.longitude < directions.endLocation.longitude 
          ? directions.startLocation.longitude 
          : directions.endLocation.longitude,
      ),
      northeast: LatLng(
        directions.startLocation.latitude > directions.endLocation.latitude 
          ? directions.startLocation.latitude 
          : directions.endLocation.latitude,
        directions.startLocation.longitude > directions.endLocation.longitude 
          ? directions.startLocation.longitude 
          : directions.endLocation.longitude,
      ),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );

    // Show navigation bar
    if (mounted) {
      _showNavigationBar();
    }
  }

  void _showNavigationBar() {
    // Navigation panel is now shown in the UI overlay
  }

  void _showDirectionsSteps() {
    if (_currentDirections == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h, bottom: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 2.w),
                  Text(
                    'Turn-by-Turn Directions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                itemCount: _currentDirections!.steps.length,
                separatorBuilder: (context, index) => Divider(height: 3.h),
                itemBuilder: (context, index) {
                  final step = _currentDirections!.steps[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(step.instruction),
                    subtitle: Text('${step.distance} • ${step.duration}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _endNavigation() {
    setState(() {
      _polylines.clear();
      _currentDirections = null;
      _isNavigating = false;
    });
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }



  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapFilterBottomSheet(
        selectedFilters: _filters,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filters = newFilters;
            _createMarkers();
          });
        },
      ),
    );
  }

  void _showNearbyIssues() {
    final nearbyIssues = _roadIssues
        .where((issue) => _shouldShowIssue(issue))
        .toList();

    // Sort by distance if available
    nearbyIssues.sort((a, b) {
      final distA = (a['distance'] ?? a['distance_miles'] ?? double.infinity) as num;
      final distB = (b['distance'] ?? b['distance_miles'] ?? double.infinity) as num;
      return distA.compareTo(distB);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NearbyIssuesBottomSheet(
        nearbyIssues: nearbyIssues,
        currentUserId: supabase.auth.currentUser?.id,
        onIssueSelected: (issue) {
          Navigator.pop(context);
          _showIssueDetails(issue);
        },
      ),
    );
  }

  Future<void> _refreshIssues() async {
    setState(() {
      _isLoading = true;
    });
    
    // Reload preferences first (in case radius changed)
    await _loadUserPreferences();
    await _loadNearbyIssues();
    _createMarkers();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0,
        ),
      );
      
      // Reload nearby issues when centering on location
      await _loadNearbyIssues();
      _createMarkers();
      setState(() {});
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : _currentMapType == MapType.satellite
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  void _toggleTraffic() {
    setState(() {
      _showTraffic = !_showTraffic;
    });
  }

  Set<Circle> _buildLocationCircle(ThemeData theme) {
    final circles = Set<Circle>.from(_circles);
    if (_currentPosition != null) {
      circles.add(
        Circle(
          circleId: CircleId('current_location'),
          center: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          radius: 50,
          fillColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          strokeColor: theme.colorScheme.primary,
          strokeWidth: 2,
        ),
      );
    }
    return circles;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _isLoading
          ? const MapSkeleton()
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : LatLng(
                            37.7749,
                            -122.4194,
                          ), // Default to San Francisco
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  circles: _buildLocationCircle(theme),
                  polylines: _polylines,
                  mapType: _currentMapType,
                  trafficEnabled: _showTraffic,
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onTap: _onMapTap,
                  onLongPress: _onMapLongPress,
                ),

                // Active navigation panel
                if (_isNavigating && _currentDirections != null)
                  SafeArea(
                    child: ActiveNavigationPanel(
                      directions: _currentDirections!,
                      onEnd: _endNavigation,
                      onViewSteps: _showDirectionsSteps,
                    ),
                  ),

                // Search bar (hide during navigation)
                if (!_isNavigating)
                  SafeArea(
                    child: Column(
                      children: [
                        MapSearchBar(
                          onSearch: (query) {
                            // Handle search
                          },
                          onFilterTap: _showFilterBottomSheet,
                        ),
                        // Alert radius indicator
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'radar',
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                AppLocalizations.of(context).map_showingIssuesWithin(
                                  _alertRadiusMiles.toStringAsFixed(1),
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              InkWell(
                                onTap: _refreshIssues,
                                child: CustomIconWidget(
                                  iconName: 'refresh',
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Floating action buttons (hide some during navigation)
                if (!_isNavigating)
                  Positioned(
                    right: 4.w,
                    bottom: 13.h, // Adjusted to sit above the bottom bar
                    child: Column(
                    children: [
                      // Current location button
                      FloatingActionButton(
                        heroTag: 'location',
                        onPressed: _centerOnCurrentLocation,
                        backgroundColor: theme.cardColor,
                        elevation: 4,
                        child: CustomIconWidget(
                          iconName: 'my_location',
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),

                      SizedBox(height: 1.5.h),

                      // Map type button
                      FloatingActionButton(
                        heroTag: 'map_type',
                        onPressed: _toggleMapType,
                        backgroundColor: theme.cardColor,
                        elevation: 4,
                        child: CustomIconWidget(
                          iconName: 'layers',
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),

                      SizedBox(height: 1.5.h),

                      // Traffic toggle button
                      FloatingActionButton(
                        heroTag: 'traffic',
                        onPressed: _toggleTraffic,
                        backgroundColor: _showTraffic
                            ? theme.colorScheme.primary
                            : theme.cardColor,
                        elevation: 4,
                        child: CustomIconWidget(
                          iconName: 'traffic',
                          color: _showTraffic
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  ),

                // Bottom action buttons (hide during navigation)
                if (!_isNavigating)
                  Positioned(
                    left: 4.w,
                    right: 4.w,
                    bottom: 2.h,
                    child: SafeArea(
                      child: Row(
                        children: [
                          // Nearby Issues Card
                          Expanded(
                            child: Material(
                              elevation: 6,
                              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                onTap: _showNearbyIssues,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 56,
                                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      // Count badge
                                      if (_roadIssues.where((issue) => _shouldShowIssue(issue)).isNotEmpty)
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${_roadIssues.where((issue) => _shouldShowIssue(issue)).length}',
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.warning_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      
                                      SizedBox(width: 2.5.w),
                                      
                                      // Text content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context).map_nearbyIssues,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 0.2.h),
                                            Text(
                                              '${_alertRadiusMiles.toStringAsFixed(1)} mi radius',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.85),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Arrow
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white.withValues(alpha: 0.7),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 3.w),
                          
                          // View Alerts - Icon Button with subtle bottom shadow only
                          Material(
                            elevation: 0,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () async {
                                await Navigator.pushNamed(context, '/safety-alerts-screen');
                                if (mounted) {
                                  await _reloadPreferencesAndIssues();
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CustomIconWidget(
                                    iconName: 'notifications',
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }
}
