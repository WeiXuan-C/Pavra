import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/services/map_service.dart';
import '../../l10n/app_localizations.dart';
import './widgets/issue_detail_bottom_sheet.dart';
import './widgets/map_filter_bottom_sheet.dart';
import './widgets/map_search_bar.dart';
import './widgets/nearby_issues_bottom_sheet.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  MapType _currentMapType = MapType.normal;
  bool _isLoading = true;
  bool _showTraffic = false;
  bool _hasLocationPermission = false;
  
  final MapService _mapService = MapService();
  double _alertRadiusMiles = 5.0;
  List<Map<String, dynamic>> _roadIssues = [];

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
    _initializeMap();
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

  void _showIssueDetails(Map<String, dynamic> issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IssueDetailBottomSheet(issue: issue),
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
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
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
                  mapType: _currentMapType,
                  trafficEnabled: _showTraffic,
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onTap: _onMapTap,
                  onLongPress: _onMapLongPress,
                ),

                // Search bar
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

                // Floating action buttons
                Positioned(
                  right: 4.w,
                  bottom: 25.h,
                  child: Column(
                    children: [
                      // Current location button
                      FloatingActionButton(
                        heroTag: 'location',
                        onPressed: _centerOnCurrentLocation,
                        backgroundColor: theme.cardColor,
                        child: CustomIconWidget(
                          iconName: 'my_location',
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Map type button
                      FloatingActionButton(
                        heroTag: 'map_type',
                        onPressed: _toggleMapType,
                        backgroundColor: theme.cardColor,
                        child: CustomIconWidget(
                          iconName: 'layers',
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Traffic toggle button
                      FloatingActionButton(
                        heroTag: 'traffic',
                        onPressed: _toggleTraffic,
                        backgroundColor: _showTraffic
                            ? theme.colorScheme.primary
                            : theme.cardColor,
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

                // Nearby issues button
                Positioned(
                  left: 4.w,
                  bottom: 15.h,
                  child: FloatingActionButton.extended(
                    heroTag: 'nearby',
                    onPressed: _showNearbyIssues,
                    backgroundColor: theme.colorScheme.primary,
                    icon: CustomIconWidget(
                      iconName: 'list',
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                    label: Text(
                      AppLocalizations.of(context).map_nearbyIssues,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),

                // View Alerts button
                Positioned(
                  right: 4.w,
                  bottom: 15.h,
                  child: FloatingActionButton.extended(
                    heroTag: 'view_alerts',
                    onPressed: () {
                      Navigator.pushNamed(context, '/safety-alerts-screen');
                    },
                    backgroundColor: theme.colorScheme.secondary,
                    icon: CustomIconWidget(
                      iconName: 'notifications',
                      color: theme.colorScheme.onSecondary,
                      size: 20,
                    ),
                    label: Text(
                      AppLocalizations.of(context).map_viewAlerts,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
