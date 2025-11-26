import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'directions_service.dart';
import 'map_service.dart';
import '../utils/error_handler.dart';

/// Service for managing multi-stop route planning and calculation
class MultiStopRouteService {
  final DirectionsService _directionsService;
  final MapService _mapService;
  final _logger = Logger();

  MultiStopRouteService({
    required DirectionsService directionsService,
    required MapService mapService,
  })  : _directionsService = directionsService,
        _mapService = mapService;

  /// Calculate route with multiple waypoints
  /// Returns null if any segment fails to calculate
  /// Throws RouteCalculationException for various error scenarios
  Future<MultiStopRoute?> calculateRoute({
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
    required String travelMode,
  }) async {
    try {
      _logger.i('Calculating multi-stop route with ${waypoints.length} waypoints');
      _logger.i('Travel mode: $travelMode');

      // Validate coordinates
      ErrorHandler.validateCoordinates(start.latitude, start.longitude);
      ErrorHandler.validateCoordinates(destination.latitude, destination.longitude);
      for (final waypoint in waypoints) {
        ErrorHandler.validateCoordinates(waypoint.latitude, waypoint.longitude);
      }

      // Build the complete list of points: start -> waypoints -> destination
      final allPoints = [start, ...waypoints, destination];
      
      // Calculate route segments between consecutive points
      final segments = <RouteSegment>[];
      final allPolylinePoints = <LatLng>[];
      int totalDistanceValue = 0;
      int totalDurationValue = 0;

      for (int i = 0; i < allPoints.length - 1; i++) {
        final segmentStart = allPoints[i];
        final segmentEnd = allPoints[i + 1];

        _logger.i('Calculating segment ${i + 1}/${allPoints.length - 1}');

        try {
          final directions = await _directionsService.getDirections(
            origin: segmentStart,
            destination: segmentEnd,
            travelMode: travelMode,
          );

          if (directions == null) {
            _logger.e('Failed to calculate segment ${i + 1}');
            throw NoRouteFoundException(travelMode);
          }

          // Create route segment
          final segment = RouteSegment(
            start: segmentStart,
            end: segmentEnd,
            directions: directions,
            segmentIndex: i,
          );

          segments.add(segment);
          allPolylinePoints.addAll(directions.polylinePoints);
          totalDistanceValue += directions.distanceValue;
          totalDurationValue += directions.durationValue;
        } catch (e) {
          if (e is RouteCalculationException) {
            rethrow;
          }

          // Check for rate limit errors
          if (ErrorHandler.isRateLimitError(e)) {
            throw ApiRateLimitExceededException();
          }

          // Check for network errors
          if (ErrorHandler.isNetworkError(e)) {
            throw NetworkTimeoutException();
          }

          // Generic route calculation error
          throw RouteCalculationException(
            'Failed to calculate route segment ${i + 1}',
            originalError: e,
          );
        }
      }

      // Format total distance and duration
      final totalDistance = _formatDistance(totalDistanceValue);
      final totalDuration = _formatDuration(totalDurationValue);

      _logger.i('Route calculated successfully');
      _logger.i('Total distance: $totalDistance');
      _logger.i('Total duration: $totalDuration');

      return MultiStopRoute(
        segments: segments,
        allPolylinePoints: allPolylinePoints,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        totalDistanceValue: totalDistanceValue,
        totalDurationValue: totalDurationValue,
        waypoints: waypoints,
      );
    } catch (e) {
      if (e is AppException) {
        ErrorHandler.logError('MultiStopRouteService.calculateRoute', e);
        rethrow;
      }

      ErrorHandler.logError('MultiStopRouteService.calculateRoute', e);
      return null;
    }
  }

  /// Get nearby issues along the route within specified radius
  Future<List<Map<String, dynamic>>> getIssuesAlongRoute({
    required List<LatLng> routePoints,
    required double radiusMiles,
  }) async {
    try {
      _logger.i('Searching for issues along route within $radiusMiles miles');

      if (routePoints.isEmpty) {
        return [];
      }

      // Sample points along the route to check for nearby issues
      // We'll check every 10th point to avoid too many API calls
      final sampleInterval = (routePoints.length / 20).ceil().clamp(1, 50);
      final sampledPoints = <LatLng>[];
      
      for (int i = 0; i < routePoints.length; i += sampleInterval) {
        sampledPoints.add(routePoints[i]);
      }
      
      // Always include the last point
      if (sampledPoints.last != routePoints.last) {
        sampledPoints.add(routePoints.last);
      }

      _logger.i('Sampling ${sampledPoints.length} points along route');

      // Collect all issues found near any sampled point
      final allIssues = <String, Map<String, dynamic>>{};

      for (final point in sampledPoints) {
        final issues = await _mapService.getNearbyIssues(
          latitude: point.latitude,
          longitude: point.longitude,
          radiusMiles: radiusMiles,
        );

        // Add issues to map (using ID as key to avoid duplicates)
        for (final issue in issues) {
          final id = issue['id'] as String;
          if (!allIssues.containsKey(id)) {
            allIssues[id] = issue;
          }
        }
      }

      final issuesList = allIssues.values.toList();
      _logger.i('Found ${issuesList.length} unique issues along route');

      return issuesList;
    } catch (e) {
      _logger.e('Error getting issues along route: $e');
      return [];
    }
  }

  /// Calculate total distance and duration metrics for a route
  RouteMetrics calculateMetrics(MultiStopRoute route) {
    return RouteMetrics(
      totalDistance: route.totalDistance,
      totalDuration: route.totalDuration,
      totalDistanceValue: route.totalDistanceValue,
      totalDurationValue: route.totalDurationValue,
      segmentCount: route.segments.length,
      waypointCount: route.waypoints.length,
    );
  }

  /// Format distance in meters to human-readable string
  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Format duration in seconds to human-readable string
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hr $minutes min';
    } else {
      return '$minutes min';
    }
  }
}

/// Result of a multi-stop route calculation
class MultiStopRoute {
  final List<RouteSegment> segments;
  final List<LatLng> allPolylinePoints;
  final String totalDistance;
  final String totalDuration;
  final int totalDistanceValue; // meters
  final int totalDurationValue; // seconds
  final List<LatLng> waypoints;

  MultiStopRoute({
    required this.segments,
    required this.allPolylinePoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalDistanceValue,
    required this.totalDurationValue,
    required this.waypoints,
  });
}

/// Individual segment of a multi-stop route
class RouteSegment {
  final LatLng start;
  final LatLng end;
  final DirectionsResult directions;
  final int segmentIndex;

  RouteSegment({
    required this.start,
    required this.end,
    required this.directions,
    required this.segmentIndex,
  });
}

/// Metrics for a multi-stop route
class RouteMetrics {
  final String totalDistance;
  final String totalDuration;
  final int totalDistanceValue; // meters
  final int totalDurationValue; // seconds
  final int segmentCount;
  final int waypointCount;

  RouteMetrics({
    required this.totalDistance,
    required this.totalDuration,
    required this.totalDistanceValue,
    required this.totalDurationValue,
    required this.segmentCount,
    required this.waypointCount,
  });
}
