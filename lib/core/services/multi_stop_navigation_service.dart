import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'multi_stop_route_service.dart';

/// Service for managing multi-stop navigation flow
/// Handles sequential waypoint navigation with automatic advancement
class MultiStopNavigationService extends ChangeNotifier {
  final _logger = Logger();

  // Navigation state
  MultiStopRoute? _currentRoute;
  int _currentWaypointIndex = 0;
  bool _isNavigating = false;
  bool _isCancelled = false;
  
  // Current segment being navigated
  RouteSegment? _currentSegment;
  int _currentStepIndex = 0;

  MultiStopNavigationService();

  // Getters
  MultiStopRoute? get currentRoute => _currentRoute;
  int get currentWaypointIndex => _currentWaypointIndex;
  bool get isNavigating => _isNavigating;
  bool get isCancelled => _isCancelled;
  RouteSegment? get currentSegment => _currentSegment;
  int get currentStepIndex => _currentStepIndex;

  /// Get all stops (waypoints + destination)
  List<LatLng> get allStops {
    if (_currentRoute == null) return [];
    return [..._currentRoute!.waypoints, _currentRoute!.segments.last.end];
  }

  /// Get current waypoint location
  LatLng? get currentWaypoint {
    if (_currentRoute == null || _currentWaypointIndex >= allStops.length) {
      return null;
    }
    return allStops[_currentWaypointIndex];
  }

  /// Get remaining stops (including current)
  int get remainingStops {
    if (_currentRoute == null) return 0;
    return allStops.length - _currentWaypointIndex;
  }

  /// Check if navigation is complete
  bool get isComplete {
    if (_currentRoute == null) return false;
    return _currentWaypointIndex >= allStops.length;
  }

  /// Check if navigation is active
  bool get isActive => _isNavigating && !isComplete && !_isCancelled;

  /// Get navigation progress (0.0 to 1.0)
  double get progress {
    if (_currentRoute == null || allStops.isEmpty) return 0.0;
    return _currentWaypointIndex / allStops.length;
  }

  /// Get current navigation instruction
  String? get currentInstruction {
    if (_currentSegment == null || 
        _currentStepIndex >= _currentSegment!.directions.steps.length) {
      return null;
    }
    return _currentSegment!.directions.steps[_currentStepIndex].instruction;
  }

  /// Get distance to current waypoint
  String? get distanceToWaypoint {
    if (_currentSegment == null) return null;
    
    // Return the segment's total distance
    return _currentSegment!.directions.distance;
  }

  /// Start navigation for a multi-stop route
  Future<void> startNavigation(MultiStopRoute route) async {
    _logger.i('Starting multi-stop navigation with ${route.waypoints.length} waypoints');
    
    _currentRoute = route;
    _currentWaypointIndex = 0;
    _isNavigating = true;
    _isCancelled = false;
    _currentStepIndex = 0;
    
    // Set first segment
    if (route.segments.isNotEmpty) {
      _currentSegment = route.segments[0];
    }
    
    notifyListeners();
    
    _logger.i('Navigation started to first waypoint');
  }

  /// Advance to next waypoint
  /// Called when user reaches current waypoint
  void advanceToNextWaypoint() {
    if (!isActive || isComplete) {
      _logger.w('Cannot advance: navigation not active or already complete');
      return;
    }

    _currentWaypointIndex++;
    _currentStepIndex = 0;
    
    _logger.i('Advanced to waypoint $_currentWaypointIndex/${allStops.length}');
    
    // Update current segment
    if (_currentWaypointIndex < _currentRoute!.segments.length) {
      _currentSegment = _currentRoute!.segments[_currentWaypointIndex];
      _logger.i('Now navigating segment ${_currentSegment!.segmentIndex}');
    } else {
      _currentSegment = null;
    }
    
    // Check if navigation is complete
    if (isComplete) {
      _logger.i('Navigation complete! Reached destination.');
      _isNavigating = false;
    }
    
    notifyListeners();
  }

  /// Advance to next step in current segment
  void advanceToNextStep() {
    if (_currentSegment == null) return;
    
    if (_currentStepIndex < _currentSegment!.directions.steps.length - 1) {
      _currentStepIndex++;
      _logger.i('Advanced to step $_currentStepIndex');
      notifyListeners();
    } else {
      // Reached end of segment, advance to next waypoint
      _logger.i('Reached end of segment, advancing to next waypoint');
      advanceToNextWaypoint();
    }
  }

  /// Cancel navigation
  void cancelNavigation() {
    _logger.i('Navigation cancelled');
    
    _isCancelled = true;
    _isNavigating = false;
    _currentRoute = null;
    _currentSegment = null;
    _currentWaypointIndex = 0;
    _currentStepIndex = 0;
    
    notifyListeners();
  }

  /// Reset navigation state
  void reset() {
    _logger.i('Resetting navigation state');
    
    _currentRoute = null;
    _currentSegment = null;
    _currentWaypointIndex = 0;
    _currentStepIndex = 0;
    _isNavigating = false;
    _isCancelled = false;
    
    notifyListeners();
  }

  /// Check if user is near a waypoint (within threshold)
  /// Returns true if user should advance to next waypoint
  bool isNearWaypoint(LatLng userLocation, {double thresholdMeters = 50.0}) {
    final waypoint = currentWaypoint;
    if (waypoint == null) return false;
    
    final distance = _calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      waypoint.latitude,
      waypoint.longitude,
    );
    
    final isNear = distance <= thresholdMeters;
    
    if (isNear) {
      _logger.i('User is near waypoint (${distance.toStringAsFixed(1)}m)');
    }
    
    return isNear;
  }

  /// Calculate distance between two points in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadiusMeters * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
