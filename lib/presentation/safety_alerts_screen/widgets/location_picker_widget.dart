import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';

class LocationPickerWidget extends StatefulWidget {
  final String? initialLocationName;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationPickerWidget({
    super.key,
    this.initialLocationName,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final _locationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();
  
  GoogleMapController? _mapController;
  double? _latitude;
  double? _longitude;
  bool _isFetchingAddress = false;
  bool _hasLocationPermission = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _locationNameController.text = widget.initialLocationName ?? '';
    _addressController.text = widget.initialAddress ?? '';
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    
    // Check location permissions
    _checkLocationPermission();
    
    if (_latitude != null && _longitude != null) {
      _updateMarker(_latitude!, _longitude!);
    } else {
      // Set default location to show map immediately
      _initializeDefaultLocation();
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        if (mounted) {
          // Show a snackbar to inform user
          WidgetsBinding.instance.addPostFrameCallback((_) {
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
          });
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (mounted) {
        setState(() {
          _hasLocationPermission = permission == LocationPermission.whileInUse || 
                                   permission == LocationPermission.always;
        });
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      if (mounted) {
        setState(() {
          _hasLocationPermission = false;
        });
      }
    }
  }

  Future<void> _initializeDefaultLocation() async {
    try {
      // Try to get last known position first (faster)
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        return;
      }
    } catch (e) {
      debugPrint('Could not get last known position: $e');
    }
    
    // Fallback to a default location (e.g., Kuala Lumpur, Malaysia)
    // You can change this to any default location you prefer
    setState(() {
      _latitude = 3.1390; // Kuala Lumpur latitude
      _longitude = 101.6869; // Kuala Lumpur longitude
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateMarker(double lat, double lng) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(lat, lng),
          draggable: true,
          onDragEnd: (newPosition) async {
            setState(() {
              _latitude = newPosition.latitude;
              _longitude = newPosition.longitude;
            });
            // Auto-fetch address when marker is dragged
            await _fetchAddressFromCoordinates(_latitude!, _longitude!);
          },
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _updateMarker(_latitude!, _longitude!);
    });
    
    // Auto-fetch address when tapping on map
    await _fetchAddressFromCoordinates(_latitude!, _longitude!);
  }

  Future<void> _fetchAddressFromCoordinates(double lat, double lng) async {
    setState(() => _isFetchingAddress = true);
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        
        // Auto-fill location name if empty
        if (_locationNameController.text.isEmpty) {
          String locationName = '';
          if (place.name != null && place.name!.isNotEmpty) {
            locationName = place.name!;
          } else if (place.street != null && place.street!.isNotEmpty) {
            locationName = place.street!;
          } else if (place.locality != null) {
            locationName = place.locality!;
          }
          
          if (locationName.isNotEmpty) {
            _locationNameController.text = locationName;
          }
        }
        
        // Auto-fill address
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        if (addressParts.isNotEmpty) {
          _addressController.text = addressParts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingAddress = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _updateMarker(_latitude!, _longitude!);
      });

      // Animate camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_latitude!, _longitude!),
            15.0,
          ),
        );
      }

      // Auto-fetch address from current location
      await _fetchAddressFromCoordinates(_latitude!, _longitude!);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.report_locationUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildTip(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(top: 0.5.h, left: 1.w),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          SizedBox(width: 2.w),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLocation() {
    if (_locationNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).common_nameRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).common_locationRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'locationName': _locationNameController.text,
      'latitude': _latitude,
      'longitude': _longitude,
      'address': _addressController.text.isEmpty ? null : _addressController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 85.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_searching,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    l10n.savedRoute_selectLocation,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quick tips
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'How to select location:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          _buildTip(Icons.touch_app, 'Tap anywhere on map', theme),
                          _buildTip(Icons.pan_tool, 'Drag the red marker', theme),
                          _buildTip(Icons.zoom_in, 'Use zoom controls', theme),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Google Map - Enhanced with larger size and floating controls
                    Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _latitude != null && _longitude != null
                          ? Stack(
                              children: [
                                GoogleMap(
                                  onMapCreated: _onMapCreated,
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_latitude!, _longitude!),
                                    zoom: 15.0,
                                  ),
                                  markers: _markers,
                                  onTap: _onMapTap,
                                  myLocationEnabled: _hasLocationPermission,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  mapToolbarEnabled: false,
                                  compassEnabled: true,
                                  mapType: MapType.normal,
                                ),
                                // Floating controls overlay
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: Column(
                                    children: [
                                      // Zoom In
                                      FloatingActionButton.small(
                                        heroTag: 'zoom_in',
                                        onPressed: () {
                                          _mapController?.animateCamera(
                                            CameraUpdate.zoomIn(),
                                          );
                                        },
                                        backgroundColor: Colors.white,
                                        child: Icon(Icons.add, color: theme.colorScheme.primary),
                                      ),
                                      SizedBox(height: 8),
                                      // Zoom Out
                                      FloatingActionButton.small(
                                        heroTag: 'zoom_out',
                                        onPressed: () {
                                          _mapController?.animateCamera(
                                            CameraUpdate.zoomOut(),
                                          );
                                        },
                                        backgroundColor: Colors.white,
                                        child: Icon(Icons.remove, color: theme.colorScheme.primary),
                                      ),
                                      SizedBox(height: 8),
                                      // My Location
                                      FloatingActionButton.small(
                                        heroTag: 'my_location',
                                        onPressed: _getCurrentLocation,
                                        backgroundColor: theme.colorScheme.primary,
                                        child: Icon(Icons.my_location, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                // Selected location indicator at top
                                if (_markers.isNotEmpty)
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    right: 12,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 2.w),
                                          Expanded(
                                            child: Text(
                                              _isFetchingAddress
                                                  ? l10n.savedLocation_fetchingAddress
                                                  : _addressController.text.isEmpty
                                                      ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                                      : _addressController.text,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Loading overlay
                                if (_isFetchingAddress)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      child: Center(
                                        child: Container(
                                          padding: EdgeInsets.all(3.w),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 1.h),
                                              Text(
                                                l10n.savedLocation_fetchingAddress,
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Loading map...',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    SizedBox(height: 3.h),

                    // Location Name Input
                    TextField(
                      controller: _locationNameController,
                      decoration: InputDecoration(
                        labelText: l10n.savedLocation_locationName,
                        hintText: l10n.savedLocation_locationNameHint,
                        prefixIcon: const Icon(Icons.label),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Address Input
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: '${l10n.savedLocation_address} (${l10n.report_optional})',
                        hintText: 'Enter full address',
                        prefixIcon: _isFetchingAddress
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.place),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: _isFetchingAddress ? l10n.savedLocation_fetchingAddress : null,
                      ),
                      maxLines: 2,
                    ),


                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: Text(l10n.common_cancel),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: Text(l10n.common_confirm),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
