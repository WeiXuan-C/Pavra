import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

  // Filter state
  Map<String, bool> _filters = {
    'potholes': true,
    'cracks': true,
    'obstacles': true,
    'lighting': true,
    'critical': true,
    'moderate': true,
    'minor': true,
    'reported': true,
    'in_progress': true,
    'resolved': false,
  };

  // Mock data for road issues
  final List<Map<String, dynamic>> _roadIssues = [
    {
      'id': '1',
      'type': 'Pothole',
      'severity': 'critical',
      'status': 'reported',
      'latitude': 37.7749,
      'longitude': -122.4194,
      'address': 'Main Street, Downtown San Francisco',
      'description':
          'Large pothole causing traffic disruption and potential vehicle damage.',
      'reportedAt': DateTime.now().subtract(Duration(hours: 2)),
      'imageUrl':
          'https://images.pexels.com/photos/1004409/pexels-photo-1004409.jpeg?auto=compress&cs=tinysrgb&w=800',
      'distance': 150,
    },
    {
      'id': '2',
      'type': 'Road Crack',
      'severity': 'moderate',
      'status': 'in_progress',
      'latitude': 37.7849,
      'longitude': -122.4094,
      'address': 'Oak Avenue, Mission District',
      'description': 'Significant crack running across the road surface.',
      'reportedAt': DateTime.now().subtract(Duration(days: 1)),
      'imageUrl':
          'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg?auto=compress&cs=tinysrgb&w=800',
      'distance': 320,
    },
    {
      'id': '3',
      'type': 'Obstacle',
      'severity': 'minor',
      'status': 'reported',
      'latitude': 37.7649,
      'longitude': -122.4294,
      'address': 'Pine Street, Financial District',
      'description': 'Debris blocking part of the roadway.',
      'reportedAt': DateTime.now().subtract(Duration(minutes: 45)),
      'imageUrl':
          'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg?auto=compress&cs=tinysrgb&w=800',
      'distance': 85,
    },
    {
      'id': '4',
      'type': 'Poor Lighting',
      'severity': 'moderate',
      'status': 'reported',
      'latitude': 37.7549,
      'longitude': -122.4394,
      'address': 'Sunset Boulevard, Richmond District',
      'description':
          'Street lights not working, creating unsafe driving conditions.',
      'reportedAt': DateTime.now().subtract(Duration(hours: 6)),
      'imageUrl':
          'https://images.pexels.com/photos/1004409/pexels-photo-1004409.jpeg?auto=compress&cs=tinysrgb&w=800',
      'distance': 450,
    },
    {
      'id': '5',
      'type': 'Pothole',
      'severity': 'minor',
      'status': 'resolved',
      'latitude': 37.7949,
      'longitude': -122.3994,
      'address': 'Market Street, SOMA',
      'description': 'Small pothole has been repaired.',
      'reportedAt': DateTime.now().subtract(Duration(days: 3)),
      'imageUrl':
          'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg?auto=compress&cs=tinysrgb&w=800',
      'distance': 200,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    _createMarkers();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enable location services in device settings'),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Settings',
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission permanently denied. Please enable in app settings.'),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Settings',
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
        _markers.add(
          Marker(
            markerId: MarkerId(issue['id'] as String),
            position: LatLng(
              issue['latitude'] as double,
              issue['longitude'] as double,
            ),
            icon: _getMarkerIcon(issue['severity'] as String),
            onTap: () => _showIssueDetails(issue),
            infoWindow: InfoWindow(
              title: issue['type'] as String,
              snippet: issue['address'] as String,
            ),
          ),
        );
      }
    }
  }

  BitmapDescriptor _getMarkerIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'moderate':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'minor':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  bool _shouldShowIssue(Map<String, dynamic> issue) {
    final type = (issue['type'] as String).toLowerCase();
    final severity = issue['severity'] as String;
    final status = issue['status'] as String;

    // Check type filters
    if (type.contains('pothole') && !_filters['potholes']!) return false;
    if (type.contains('crack') && !_filters['cracks']!) return false;
    if (type.contains('obstacle') && !_filters['obstacles']!) return false;
    if (type.contains('lighting') && !_filters['lighting']!) return false;

    // Check severity filters
    if (!_filters[severity]!) return false;

    // Check status filters
    if (!_filters[status.replaceAll(' ', '_')]!) return false;

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Issue'),
        content: Text('Create a new road safety report at this location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/report-submission-screen');
            },
            child: Text('Report'),
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

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0,
        ),
      );
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
                  child: MapSearchBar(
                    onSearch: (query) {
                      // Handle search
                    },
                    onFilterTap: _showFilterBottomSheet,
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
                      'Nearby Issues',
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
                      'Alerts',
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
