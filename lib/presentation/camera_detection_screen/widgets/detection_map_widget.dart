import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/detection_model.dart';
import '../ai_detection_provider.dart';

class DetectionMapWidget extends StatefulWidget {
  final List<DetectionModel> detections;
  final AiDetectionProvider aiProvider;
  final Function(DetectionModel) onDetectionTap;

  const DetectionMapWidget({
    super.key,
    required this.detections,
    required this.aiProvider,
    required this.onDetectionTap,
  });

  @override
  State<DetectionMapWidget> createState() => _DetectionMapWidgetState();
}

class _DetectionMapWidgetState extends State<DetectionMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(DetectionMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detections != widget.detections) {
      _updateMarkers();
    }
  }

  void _initializeMap() {
    // Find the first detection with valid coordinates
    for (var detection in widget.detections) {
      if (detection.latitude != null && detection.longitude != null) {
        _initialPosition = LatLng(detection.latitude!, detection.longitude!);
        break;
      }
    }

    // Default to a generic location if no detections have coordinates
    _initialPosition ??= const LatLng(37.7749, -122.4194); // San Francisco

    _updateMarkers();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    for (var detection in widget.detections) {
      if (detection.latitude != null && detection.longitude != null) {
        final alertColor = widget.aiProvider.getAlertColor(detection);
        final markerColor = _getMarkerColor(alertColor);

        markers.add(
          Marker(
            markerId: MarkerId(detection.id),
            position: LatLng(detection.latitude!, detection.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            infoWindow: InfoWindow(
              title: detection.type.displayName,
              snippet: 'Severity: ${detection.severity} | ${(detection.confidence * 100).toInt()}%',
              onTap: () => widget.onDetectionTap(detection),
            ),
            onTap: () => widget.onDetectionTap(detection),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  double _getMarkerColor(Color color) {
    // Convert Color to BitmapDescriptor hue
    if (color == Colors.red) {
      return BitmapDescriptor.hueRed;
    } else if (color == Colors.amber || color == Colors.yellow) {
      return BitmapDescriptor.hueYellow;
    } else if (color == Colors.green) {
      return BitmapDescriptor.hueGreen;
    } else {
      return BitmapDescriptor.hueBlue;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitMapToMarkers();
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    // Calculate bounds to fit all markers
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    // Add padding
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.detections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No detections to display',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Detections will appear here once captured',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Check if any detections have coordinates
    final hasCoordinates = widget.detections.any(
      (d) => d.latitude != null && d.longitude != null,
    );

    if (!hasCoordinates) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No location data available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Detections need GPS coordinates to be displayed on the map',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _initialPosition!,
            zoom: 14.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        ),
        
        // Legend
        Positioned(
          top: 2.h,
          right: 2.w,
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Severity',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                _buildLegendItem(theme, Colors.red, 'High (4-5)'),
                SizedBox(height: 0.5.h),
                _buildLegendItem(theme, Colors.amber, 'Medium (2-3)'),
                SizedBox(height: 0.5.h),
                _buildLegendItem(theme, Colors.green, 'Low (1)'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
