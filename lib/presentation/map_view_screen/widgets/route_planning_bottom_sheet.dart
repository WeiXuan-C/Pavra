import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class RoutePlanningBottomSheet extends StatefulWidget {
  final LatLng? currentLocation;
  final Function(List<LatLng>, String) onStartNavigation;

  const RoutePlanningBottomSheet({
    super.key,
    required this.currentLocation,
    required this.onStartNavigation,
  });

  @override
  State<RoutePlanningBottomSheet> createState() => _RoutePlanningBottomSheetState();
}

class _RoutePlanningBottomSheetState extends State<RoutePlanningBottomSheet> {
  final List<RoutePoint> _routePoints = [];
  String _selectedTravelMode = 'driving';

  @override
  void initState() {
    super.initState();
    // Initialize with current location as start point
    if (widget.currentLocation != null) {
      _routePoints.add(RoutePoint(
        location: widget.currentLocation!,
        address: 'Current Location',
        type: RoutePointType.start,
      ));
    }
    // Add empty destination
    _routePoints.add(RoutePoint(
      location: null,
      address: '',
      type: RoutePointType.destination,
    ));
  }

  void _addStop() {
    setState(() {
      // Insert before the last item (destination)
      _routePoints.insert(
        _routePoints.length - 1,
        RoutePoint(
          location: null,
          address: '',
          type: RoutePointType.stop,
        ),
      );
    });
  }

  void _removeStop(int index) {
    if (_routePoints.length > 2) {
      setState(() {
        _routePoints.removeAt(index);
      });
    }
  }

  void _swapPoints(int index1, int index2) {
    if (index1 >= 0 && index1 < _routePoints.length &&
        index2 >= 0 && index2 < _routePoints.length) {
      setState(() {
        final temp = _routePoints[index1];
        _routePoints[index1] = _routePoints[index2];
        _routePoints[index2] = temp;
      });
    }
  }

  void _updatePoint(int index, LatLng location, String address) {
    setState(() {
      _routePoints[index] = RoutePoint(
        location: location,
        address: address,
        type: _routePoints[index].type,
      );
    });
  }

  bool _canStartNavigation() {
    return _routePoints.length >= 2 &&
        _routePoints.first.location != null &&
        _routePoints.last.location != null;
  }

  void _startNavigation() {
    if (!_canStartNavigation()) return;

    final locations = _routePoints
        .where((point) => point.location != null)
        .map((point) => point.location!)
        .toList();

    widget.onStartNavigation(locations, _selectedTravelMode);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Icon(
                  Icons.directions,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Plan Your Route',
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

          // Route points list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              itemCount: _routePoints.length,
              itemBuilder: (context, index) {
                return _buildRoutePointTile(index);
              },
            ),
          ),

          // Add stop button
          if (_routePoints.length < 10)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: OutlinedButton.icon(
                onPressed: _addStop,
                icon: Icon(Icons.add_location_alt, size: 20),
                label: Text('Add Stop'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ),

          SizedBox(height: 2.h),

          // Travel mode selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel Mode',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    _buildTravelModeButton('driving', Icons.directions_car, 'Drive'),
                    SizedBox(width: 2.w),
                    _buildTravelModeButton('walking', Icons.directions_walk, 'Walk'),
                    SizedBox(width: 2.w),
                    _buildTravelModeButton('transit', Icons.directions_transit, 'Transit'),
                    SizedBox(width: 2.w),
                    _buildTravelModeButton('bicycling', Icons.directions_bike, 'Bike'),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Start navigation button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: ElevatedButton.icon(
              onPressed: _canStartNavigation() ? _startNavigation : null,
              icon: Icon(Icons.navigation, size: 20),
              label: Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
                disabledBackgroundColor: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePointTile(int index) {
    final point = _routePoints[index];
    final theme = Theme.of(context);
    final isFirst = index == 0;
    final isLast = index == _routePoints.length - 1;

    IconData iconData;
    Color iconColor;
    String hint;

    switch (point.type) {
      case RoutePointType.start:
        iconData = Icons.trip_origin;
        iconColor = Colors.green;
        hint = 'Starting point';
        break;
      case RoutePointType.stop:
        iconData = Icons.location_on;
        iconColor = Colors.orange;
        hint = 'Stop $index';
        break;
      case RoutePointType.destination:
        iconData = Icons.place;
        iconColor = Colors.red;
        hint = 'Destination';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and connecting line
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  color: theme.dividerColor,
                ),
            ],
          ),

          SizedBox(width: 3.w),

          // Search field
          Expanded(
            child: RoutePointSearchField(
              initialAddress: point.address,
              hint: hint,
              onLocationSelected: (location, address) {
                _updatePoint(index, location, address);
              },
            ),
          ),

          // Actions
          Column(
            children: [
              // Reorder buttons
              if (!isFirst)
                IconButton(
                  icon: Icon(Icons.arrow_upward, size: 18),
                  onPressed: () => _swapPoints(index, index - 1),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              if (!isLast)
                IconButton(
                  icon: Icon(Icons.arrow_downward, size: 18),
                  onPressed: () => _swapPoints(index, index + 1),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              // Remove button (only for stops)
              if (point.type == RoutePointType.stop)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
                  onPressed: () => _removeStop(index),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTravelModeButton(String mode, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedTravelMode == mode;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTravelMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(2.w),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 24,
              ),
              SizedBox(height: 0.5.h),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Route point search field with autocomplete
class RoutePointSearchField extends StatefulWidget {
  final String initialAddress;
  final String hint;
  final Function(LatLng, String) onLocationSelected;

  const RoutePointSearchField({
    super.key,
    required this.initialAddress,
    required this.hint,
    required this.onLocationSelected,
  });

  @override
  State<RoutePointSearchField> createState() => _RoutePointSearchFieldState();
}

class _RoutePointSearchFieldState extends State<RoutePointSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialAddress;
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _controller.text;
    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
      });
      return;
    }

    // Simulate autocomplete suggestions
    // In production, use Google Places API
    setState(() {
      _suggestions = [
        {'title': query, 'subtitle': 'Search for this location'},
      ];
    });
  }

  Future<void> _searchLocation(String query) async {
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
        _focusNode.unfocus();
        setState(() {
          _suggestions.clear();
        });
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not found'),
            duration: Duration(seconds: 2),
          ),
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
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _suggestions.clear();
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _searchLocation(value);
            }
          },
        ),

        // Suggestions dropdown
        if (_suggestions.isNotEmpty && _focusNode.hasFocus)
          Container(
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(2.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((suggestion) {
                return ListTile(
                  leading: Icon(Icons.search, size: 20),
                  title: Text(
                    suggestion['title'],
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: suggestion['subtitle'] != null
                      ? Text(
                          suggestion['subtitle'],
                          style: theme.textTheme.bodySmall,
                        )
                      : null,
                  onTap: () => _searchLocation(suggestion['title']),
                  dense: true,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// Data models
enum RoutePointType { start, stop, destination }

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
