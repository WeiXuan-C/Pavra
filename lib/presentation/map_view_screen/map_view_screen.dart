import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/services/map_service.dart';
import '../../core/services/directions_service.dart';
import '../../core/services/saved_location_service.dart';
import '../../core/services/voice_search_service.dart';
import '../../core/api/saved_route/saved_route_api.dart';
import '../../core/api/notification/notification_api.dart';
import '../../core/services/notification_helper_service.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/accessibility_utils.dart';
import '../../data/models/saved_location_model.dart';
import '../../data/repositories/saved_route_repository.dart';
import '../../l10n/app_localizations.dart';
import './widgets/issue_detail_bottom_sheet.dart';
import './widgets/map_filter_bottom_sheet.dart';
import './widgets/map_search_bar.dart';
import './widgets/map_skeleton.dart';
import './widgets/nearby_issues_bottom_sheet.dart';
import './widgets/navigation_bottom_sheet.dart';
import './widgets/active_navigation_panel.dart';
import './widgets/voice_search_widget.dart';

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
  late final SavedLocationService _savedLocationService;
  double _alertRadiusMiles = 5.0;
  List<Map<String, dynamic>> _roadIssues = [];
  DirectionsResult? _currentDirections;
  bool _isNavigating = false;
  
  // Saved locations for quick access
  SavedLocationModel? _homeLocation;
  SavedLocationModel? _workLocation;
  List<SavedLocationModel> _savedLocations = [];

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
  
  // UI state for collapsible controls
  bool _isControlsExpanded = false;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final notificationHelper = NotificationHelperService(NotificationApi());
    final api = SavedRouteApi(supabase, notificationHelper);
    final repository = SavedRouteRepository(api);
    _savedLocationService = SavedLocationService(repository);
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
    await _loadSavedLocations(); // Reload saved locations
    
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
    await _loadSavedLocations();
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

  Future<void> _loadSavedLocations() async {
    try {
      final homeLocation = await _savedLocationService.getHomeLocation();
      final workLocation = await _savedLocationService.getWorkLocation();
      final allLocations = await _savedLocationService.getSavedLocations();
      
      if (mounted) {
        setState(() {
          _homeLocation = homeLocation;
          _workLocation = workLocation;
          _savedLocations = allLocations;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved locations: $e');
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

    // Add road issue markers
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
                title: title ?? AppLocalizations.of(context).map_roadIssue,
                snippet: address ?? AppLocalizations.of(context).map_locationCoordinates('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
              ),
            ),
          );
        }
      }
    }
    
    // Add saved location markers
    // Requirements: 9.4, 9.5
    for (var location in _savedLocations) {
      _markers.add(
        Marker(
          markerId: MarkerId('saved_${location.id}'),
          position: LatLng(location.latitude, location.longitude),
          icon: _getSavedLocationMarkerIcon(location.icon),
          onTap: () => _showSavedLocationDetails(location),
          infoWindow: InfoWindow(
            title: '⭐ ${location.label}',
            snippet: location.address ?? location.locationName,
          ),
        ),
      );
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

  /// Get marker icon for saved locations with distinct color
  /// Requirements: 9.4
  BitmapDescriptor _getSavedLocationMarkerIcon(String iconName) {
    // Use distinct colors for different saved location types
    switch (iconName.toLowerCase()) {
      case 'home':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'work':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'school':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case 'shopping':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'hospital':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'gym':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'park':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'star':
      case 'favorite':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      default:
        // Default saved location color (distinct from issues)
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
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

  /// Show saved location details when marker is tapped
  /// Requirements: 9.5
  void _showSavedLocationDetails(SavedLocationModel location) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            ),
            
            // Location icon and title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Icon(
                    IconMapper.getIcon(location.icon),
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              location.label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        location.locationName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location.address != null) ...[
                        SizedBox(height: 0.3.h),
                        Text(
                          location.address!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 3.h),
            
            // Action buttons
            Row(
              children: [
                // Edit button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/saved-locations-screen',
                        arguments: {'editLocationId': location.id},
                      ).then((_) {
                        // Reload saved locations after editing
                        _loadSavedLocations().then((_) {
                          _createMarkers();
                          setState(() {});
                        });
                      });
                    },
                    icon: Icon(Icons.edit, size: 18),
                    label: Text(AppLocalizations.of(context).map_edit),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                // Navigate button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToIssue(
                        location.latitude,
                        location.longitude,
                        location.label,
                      );
                    },
                    icon: Icon(Icons.directions, size: 20),
                    label: Text(AppLocalizations.of(context).map_navigate),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 1.h),
            
            // Plan route button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRoutePlanningSheet(
                  destination: LatLng(location.latitude, location.longitude),
                  destinationName: location.label,
                );
              },
              icon: Icon(Icons.alt_route, size: 18),
              label: Text('Plan Route with Stops'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _navigateToIssue(double lat, double lng, String? title) {
    if (_mapController == null || _currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).map_currentLocationNotAvailable)),
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

  void _navigateToHome() {
    if (_homeLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).map_homeLocationNotSet)),
      );
      return;
    }
    
    _navigateToIssue(
      _homeLocation!.latitude,
      _homeLocation!.longitude,
      _homeLocation!.locationName,
    );
  }

  void _navigateToWork() {
    if (_workLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).map_workLocationNotSet)),
      );
      return;
    }
    
    _navigateToIssue(
      _workLocation!.latitude,
      _workLocation!.longitude,
      _workLocation!.locationName,
    );
  }

  /// Handle voice commands
  /// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
  void _handleVoiceCommand(VoiceCommand command) {
    switch (command.type) {
      case VoiceCommandType.navigateHome:
        // Navigate to home location
        if (_homeLocation != null) {
          _navigateToHome();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).map_navigatingToHome),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).map_homeLocationNotSetLong),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: AppLocalizations.of(context).map_setHome,
                onPressed: () {
                  Navigator.pushNamed(context, '/saved-locations-screen');
                },
              ),
            ),
          );
        }
        break;

      case VoiceCommandType.navigateWork:
        // Navigate to work location
        if (_workLocation != null) {
          _navigateToWork();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).map_navigatingToWork),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).map_workLocationNotSetLong),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: AppLocalizations.of(context).map_setWork,
                onPressed: () {
                  Navigator.pushNamed(context, '/saved-locations-screen');
                },
              ),
            ),
          );
        }
        break;

      case VoiceCommandType.navigateTo:
        // Navigate to specified location
        if (command.location != null && command.location!.isNotEmpty) {
          _searchAndNavigate(command.location!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).map_pleaseSpecifyLocation),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;

      case VoiceCommandType.stopNavigation:
        // Stop current navigation
        if (_isNavigating) {
          _endNavigation();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).map_navigationStopped),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).map_noActiveNavigation),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;

      case VoiceCommandType.showNearbyIssues:
        // Show nearby issues bottom sheet
        _showNearbyIssues();
        break;

      case VoiceCommandType.search:
        // Regular search query
        if (command.location != null && command.location!.isNotEmpty) {
          _searchLocation(command.location!);
        }
        break;

      case VoiceCommandType.unknown:
        // Show clarification dialog for ambiguous commands
        _showClarificationDialog(command.rawText);
        break;
    }
  }

  /// Search for a location and navigate to it
  Future<void> _searchAndNavigate(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (!mounted) return;
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        _navigateToIssue(
          location.latitude,
          location.longitude,
          query,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).map_locationNotFound(query)),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).map_couldNotFindLocation(query)),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Search for a location and display it on the map
  Future<void> _searchLocation(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (!mounted) return;
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        
        // Try to get the full address from coordinates
        String? fullAddress;
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
              place.postalCode,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          }
        } catch (e) {
          debugPrint('Error getting placemark: $e');
        }
        
        if (!mounted) return;
        _handleSearch(query, latLng, fullAddress);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location "$query" not found'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find location "$query"'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show clarification dialog for ambiguous commands
  /// Requirement: 7.6
  void _showClarificationDialog(String rawText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).map_whatWouldYouLikeToDo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).map_iHeard(rawText)),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context).map_pleaseChooseAction),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchLocation(rawText);
            },
            child: Text(AppLocalizations.of(context).map_searchForLocation),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchAndNavigate(rawText);
            },
            child: Text(AppLocalizations.of(context).map_navigateToLocation),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).map_cancel),
          ),
        ],
      ),
    );
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

  /// Activate voice search
  Future<void> _activateVoiceSearch() async {
    final voiceSearchService = VoiceSearchService();
    
    // Request microphone permission first
    final hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).map_microphonePermissionRequired),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Initialize voice search service
    final initialized = await voiceSearchService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).map_voiceSearchNotAvailable),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Show voice search widget as bottom sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VoiceSearchWidget(
          voiceSearchService: voiceSearchService,
          onSearchResult: (recognizedText) async {
            if (recognizedText.isNotEmpty) {
              // Search for the location
              try {
                final locations = await locationFromAddress(recognizedText);
                if (locations.isNotEmpty) {
                  final location = locations.first;
                  final latLng = LatLng(location.latitude, location.longitude);
                  _handleSearch(recognizedText, latLng, null);
                }
              } catch (e) {
                debugPrint('Error searching location: $e');
              }
            }
          },
          onCommandRecognized: (command) {
            _handleVoiceCommand(command);
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
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

  void _handleSearch(String query, LatLng? location, String? address) {
    if (location != null && _mapController != null) {
      // Move camera to searched location
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15.0),
      );
      
      // Check if there are any issues near this location
      final nearbyIssues = _roadIssues.where((issue) {
        if (issue['latitude'] == null || issue['longitude'] == null) return false;
        
        final distance = _calculateDistance(
          location.latitude,
          location.longitude,
          issue['latitude'] as double,
          issue['longitude'] as double,
        );
        
        return distance < 0.5; // Within 0.5 miles
      }).toList();
      
      // Add a distinctive marker for the searched location
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'search_result');
        _markers.add(
          Marker(
            markerId: MarkerId('search_result'),
            position: location,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: query,
              snippet: address ?? 'Tap for options',
            ),
            onTap: () => _showSearchResultActions(location, query, address, nearbyIssuesCount: nearbyIssues.length),
          ),
        );
      });
      
      // Show location card with directions option immediately after search
      _showSearchResultActions(location, query, address, nearbyIssuesCount: nearbyIssues.length);
    }
  }

  void _showSearchResultActions(LatLng location, String title, String? address, {int nearbyIssuesCount = 0}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            ),
            
            // Location icon and title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          address,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 3.h),
            
            // Nearby issues info
            if (nearbyIssuesCount > 0)
              Container(
                padding: EdgeInsets.all(3.w),
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        '$nearbyIssuesCount ${nearbyIssuesCount == 1 ? "road issue" : "road issues"} nearby',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Action buttons
            Row(
              children: [
                // Clear marker button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _markers.removeWhere((marker) => marker.markerId.value == 'search_result');
                    });
                  },
                  icon: Icon(Icons.close, size: 18),
                  label: Text(AppLocalizations.of(context).map_clear),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 3.w),
                  ),
                ),
                SizedBox(width: 2.w),
                // Directions button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToIssue(location.latitude, location.longitude, title);
                    },
                    icon: Icon(Icons.directions, size: 20),
                    label: Text(AppLocalizations.of(context).map_directions),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 1.h),
            
            // Plan route button (advanced)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRoutePlanningSheet(destination: location, destinationName: title);
              },
              icon: Icon(Icons.alt_route, size: 18),
              label: Text('Plan Route with Stops'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showRoutePlanningSheet({LatLng? destination, String? destinationName}) {
    Navigator.pushNamed(
      context,
      '/multi-stop-route-planner',
      arguments: {
        'currentLocation': _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
        'initialDestination': destination,
        'initialDestinationName': destinationName,
      },
    );
  }



  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMiles = 3959; // Earth's radius in miles
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadiusMiles * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  int _getActiveFilterCount() {
    // Count how many filters are disabled (not showing)
    return _filters.values.where((isActive) => !isActive).length;
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

                // Clean search bar with action buttons (hide during navigation)
                if (!_isNavigating)
                  SafeArea(
                    child: Container(
                      margin: EdgeInsets.all(4.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main search bar with action buttons - fixed height row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search bar
                              Expanded(
                                child: MapSearchBar(
                                  issues: _roadIssues,
                                  onSearch: _handleSearch,
                                  onFilterTap: _showFilterBottomSheet,
                                  activeFilterCount: _getActiveFilterCount(),
                                  savedLocationService: _savedLocationService,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              
                              // Fixed height container for buttons
                              Column(
                                children: [
                                  // Voice search button
                                  Material(
                                    elevation: 4,
                                    shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: _activateVoiceSearch,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.all(3.w),
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.mic,
                                          color: theme.colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 2.w),
                                  
                                  // More menu button
                                  Material(
                                    elevation: 4,
                                    shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isControlsExpanded = !_isControlsExpanded;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.all(3.w),
                                        decoration: BoxDecoration(
                                          color: _isControlsExpanded 
                                              ? theme.colorScheme.primary 
                                              : theme.cardColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _isControlsExpanded 
                                              ? Icons.close 
                                              : Icons.more_vert,
                                          color: _isControlsExpanded 
                                              ? Colors.white 
                                              : theme.colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Expandable controls panel with all features
                          AnimatedSize(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _isControlsExpanded
                                ? Container(
                                    margin: EdgeInsets.only(top: 2.h),
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Quick Actions Section
                                        Text(
                                          AppLocalizations.of(context).route_quickActions,
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        SizedBox(height: 1.5.h),
                                        
                                        // Action buttons grid
                                        Row(
                                          children: [
                                            // Filter button
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _isControlsExpanded = false;
                                                  });
                                                  _showFilterBottomSheet();
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                                  decoration: BoxDecoration(
                                                    color: _getActiveFilterCount() > 0
                                                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                          CustomIconWidget(
                                                            iconName: 'tune',
                                                            color: theme.colorScheme.primary,
                                                            size: 28,
                                                          ),
                                                          if (_getActiveFilterCount() > 0)
                                                            Positioned(
                                                              right: -8,
                                                              top: -8,
                                                              child: Container(
                                                                padding: EdgeInsets.all(4),
                                                                decoration: BoxDecoration(
                                                                  color: theme.colorScheme.error,
                                                                  shape: BoxShape.circle,
                                                                  border: Border.all(
                                                                    color: theme.cardColor,
                                                                    width: 1.5,
                                                                  ),
                                                                ),
                                                                constraints: BoxConstraints(
                                                                  minWidth: 18,
                                                                  minHeight: 18,
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    '${_getActiveFilterCount()}',
                                                                    style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 0.5.h),
                                                      Text(
                                                        AppLocalizations.of(context).map_filter,
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.primary,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 2.w),
                                            // Plan Route button
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _isControlsExpanded = false;
                                                  });
                                                  _showRoutePlanningSheet();
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        Icons.alt_route,
                                                        color: theme.colorScheme.primary,
                                                        size: 28,
                                                      ),
                                                      SizedBox(height: 0.5.h),
                                                      Text(
                                                        AppLocalizations.of(context).route_planRoute,
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.primary,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 2.w),
                                            // Refresh Issues button
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  _refreshIssues();
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        Icons.refresh,
                                                        color: theme.colorScheme.primary,
                                                        size: 28,
                                                      ),
                                                      SizedBox(height: 0.5.h),
                                                      Text(
                                                        AppLocalizations.of(context).map_refresh,
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.primary,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        SizedBox(height: 2.h),
                                        
                                        // Alert radius info
                                        Container(
                                          padding: EdgeInsets.all(3.w),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              CustomIconWidget(
                                                iconName: 'radar',
                                                size: 18,
                                                color: theme.colorScheme.primary,
                                              ),
                                              SizedBox(width: 2.w),
                                              Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context).map_showingIssuesWithin(
                                                    _alertRadiusMiles.toStringAsFixed(1),
                                                  ),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Quick access buttons (Home/Work)
                                        if (_homeLocation != null || _workLocation != null) ...[
                                          SizedBox(height: 2.h),
                                          Text(
                                            AppLocalizations.of(context).route_savedLocations,
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          SizedBox(height: 1.5.h),
                                          Row(
                                            children: [
                                              if (_homeLocation != null)
                                                Expanded(
                                                  child: Semantics(
                                                    label: AccessibilityUtils.quickAccessLabel('Home'),
                                                    button: true,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        await AccessibilityUtils.buttonPressed();
                                                        setState(() {
                                                          _isControlsExpanded = false;
                                                        });
                                                        _navigateToHome();
                                                      },
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: 3.w,
                                                          vertical: 1.5.h,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.home,
                                                              color: theme.colorScheme.primary,
                                                              size: 20,
                                                            ),
                                                            SizedBox(width: 2.w),
                                                            Text(
                                                              AppLocalizations.of(context).map_home,
                                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                                color: theme.colorScheme.primary,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (_homeLocation != null && _workLocation != null)
                                                SizedBox(width: 2.w),
                                              if (_workLocation != null)
                                                Expanded(
                                                  child: Semantics(
                                                    label: AccessibilityUtils.quickAccessLabel('Work'),
                                                    button: true,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        await AccessibilityUtils.buttonPressed();
                                                        setState(() {
                                                          _isControlsExpanded = false;
                                                        });
                                                        _navigateToWork();
                                                      },
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: 3.w,
                                                          vertical: 1.5.h,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.work,
                                                              color: theme.colorScheme.primary,
                                                              size: 20,
                                                            ),
                                                            SizedBox(width: 2.w),
                                                            Text(
                                                              AppLocalizations.of(context).map_work,
                                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                                color: theme.colorScheme.primary,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : SizedBox.shrink(),
                          ),
                        ],
                      ),
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
                                              AppLocalizations.of(context).map_miRadius(_alertRadiusMiles.toStringAsFixed(1)),
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
