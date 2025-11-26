import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import '../utils/error_handler.dart';

/// Service for optimizing multi-stop routes to minimize travel distance
class RouteOptimizer {
  final _logger = Logger();

  /// Optimize waypoints using nearest neighbor algorithm
  /// Preserves start and destination points, only reorders intermediate waypoints
  /// Returns original waypoints on failure (RouteOptimizationFailedException)
  Future<OptimizationResult> optimizeNearestNeighbor({
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
  }) async {
    try {
      _logger.i('Optimizing route with ${waypoints.length} waypoints');

      // Validate coordinates
      ErrorHandler.validateCoordinates(start.latitude, start.longitude);
      ErrorHandler.validateCoordinates(destination.latitude, destination.longitude);
      for (final waypoint in waypoints) {
        ErrorHandler.validateCoordinates(waypoint.latitude, waypoint.longitude);
      }

      // If less than 2 waypoints, no optimization needed
      if (waypoints.length < 2) {
        _logger.i('Less than 2 waypoints, no optimization needed');
        final originalDistance = await _calculateTotalDistance(
          start: start,
          waypoints: waypoints,
          destination: destination,
        );
        
        return OptimizationResult(
          optimizedWaypoints: List.from(waypoints),
          originalDistance: originalDistance,
          optimizedDistance: originalDistance,
          savingsPercent: 0.0,
        );
      }

      // Calculate original distance
      final originalDistance = await _calculateTotalDistance(
        start: start,
        waypoints: waypoints,
        destination: destination,
      );

      _logger.i('Original distance: ${originalDistance.toStringAsFixed(2)} meters');

      // Build distance matrix for all waypoints
      final distanceMatrix = await calculateDistanceMatrix(waypoints);

      // Apply nearest neighbor algorithm
      final optimizedWaypoints = <LatLng>[];
      final unvisited = Set<int>.from(List.generate(waypoints.length, (i) => i));
      
      // Find nearest waypoint to start
      int currentIndex = _findNearestPoint(start, waypoints, unvisited);
      optimizedWaypoints.add(waypoints[currentIndex]);
      unvisited.remove(currentIndex);

      // Continue finding nearest unvisited waypoints
      while (unvisited.isNotEmpty) {
        final nearest = _findNearestFromMatrix(
          currentIndex,
          distanceMatrix,
          unvisited,
        );
        optimizedWaypoints.add(waypoints[nearest]);
        currentIndex = nearest;
        unvisited.remove(nearest);
      }

      // Calculate optimized distance
      final optimizedDistance = await _calculateTotalDistance(
        start: start,
        waypoints: optimizedWaypoints,
        destination: destination,
      );

      _logger.i('Optimized distance: ${optimizedDistance.toStringAsFixed(2)} meters');

      // Calculate savings
      final savings = calculateSavings(
        originalDistance: originalDistance,
        optimizedDistance: optimizedDistance,
      );

      _logger.i('Savings: ${savings.toStringAsFixed(2)}%');

      return OptimizationResult(
        optimizedWaypoints: optimizedWaypoints,
        originalDistance: originalDistance,
        optimizedDistance: optimizedDistance,
        savingsPercent: savings,
      );
    } catch (e) {
      // Log the optimization failure
      ErrorHandler.logError('RouteOptimizer.optimizeNearestNeighbor', e);
      
      // On failure, return original waypoints with error
      try {
        final originalDistance = await _calculateTotalDistance(
          start: start,
          waypoints: waypoints,
          destination: destination,
        );
        
        // Throw optimization failed exception but still return result
        _logger.w('Optimization failed, returning original waypoints');
        
        return OptimizationResult(
          optimizedWaypoints: List.from(waypoints),
          originalDistance: originalDistance,
          optimizedDistance: originalDistance,
          savingsPercent: 0.0,
        );
      } catch (distanceError) {
        // If we can't even calculate original distance, throw
        throw RouteOptimizationFailedException(originalError: e);
      }
    }
  }

  /// Calculate distance matrix between all waypoints
  /// Returns a 2D list where matrix[i][j] is the distance from waypoint i to waypoint j
  Future<List<List<double>>> calculateDistanceMatrix(
    List<LatLng> points,
  ) async {
    final n = points.length;
    final matrix = List.generate(n, (_) => List.filled(n, 0.0));

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i != j) {
          matrix[i][j] = _calculateHaversineDistance(points[i], points[j]);
        }
      }
    }

    return matrix;
  }

  /// Calculate distance savings percentage
  double calculateSavings({
    required double originalDistance,
    required double optimizedDistance,
  }) {
    if (originalDistance == 0) {
      return 0.0;
    }
    
    final savings = ((originalDistance - optimizedDistance) / originalDistance) * 100;
    return savings.clamp(0.0, 100.0);
  }

  /// Calculate total distance for a route
  Future<double> _calculateTotalDistance({
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
  }) async {
    double totalDistance = 0.0;

    // Distance from start to first waypoint (or destination if no waypoints)
    if (waypoints.isEmpty) {
      totalDistance += _calculateHaversineDistance(start, destination);
    } else {
      totalDistance += _calculateHaversineDistance(start, waypoints.first);

      // Distance between consecutive waypoints
      for (int i = 0; i < waypoints.length - 1; i++) {
        totalDistance += _calculateHaversineDistance(waypoints[i], waypoints[i + 1]);
      }

      // Distance from last waypoint to destination
      totalDistance += _calculateHaversineDistance(waypoints.last, destination);
    }

    return totalDistance;
  }

  /// Find the nearest point to the given location from a set of unvisited indices
  int _findNearestPoint(LatLng from, List<LatLng> points, Set<int> unvisited) {
    double minDistance = double.infinity;
    int nearestIndex = unvisited.first;

    for (final index in unvisited) {
      final distance = _calculateHaversineDistance(from, points[index]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = index;
      }
    }

    return nearestIndex;
  }

  /// Find the nearest unvisited point using the distance matrix
  int _findNearestFromMatrix(
    int currentIndex,
    List<List<double>> matrix,
    Set<int> unvisited,
  ) {
    double minDistance = double.infinity;
    int nearestIndex = unvisited.first;

    for (final index in unvisited) {
      final distance = matrix[currentIndex][index];
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = index;
      }
    }

    return nearestIndex;
  }

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in meters
  double _calculateHaversineDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000.0; // Earth's radius in meters

    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final dLat = (point2.latitude - point1.latitude) * pi / 180;
    final dLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}

/// Result of route optimization
class OptimizationResult {
  final List<LatLng> optimizedWaypoints;
  final double originalDistance;
  final double optimizedDistance;
  final double savingsPercent;

  OptimizationResult({
    required this.optimizedWaypoints,
    required this.originalDistance,
    required this.optimizedDistance,
    required this.savingsPercent,
  });

  @override
  String toString() {
    return 'OptimizationResult('
        'waypoints: ${optimizedWaypoints.length}, '
        'original: ${originalDistance.toStringAsFixed(2)}m, '
        'optimized: ${optimizedDistance.toStringAsFixed(2)}m, '
        'savings: ${savingsPercent.toStringAsFixed(2)}%)';
  }
}
