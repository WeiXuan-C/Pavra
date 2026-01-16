import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Service for continuous location tracking with intelligent throttling
/// 
/// This service manages GPS position monitoring and implements threshold-based
/// server updates to balance accuracy with battery life and server load.
/// 
/// Uses singleton pattern to ensure only one GPS stream is active.
class LocationTrackingService {
  // Singleton instance
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  
  /// Factory constructor returns singleton instance
  factory LocationTrackingService() => _instance;
  
  /// Private constructor for singleton pattern
  LocationTrackingService._internal();

  // State management
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;
  
  // Configuration constants - Distance threshold (meters)
  static const double _minDistanceThreshold = 100.0;
  
  // Configuration constants - Time threshold (seconds)
  static const int _minUpdateInterval = 60;
  
  // Configuration constants - Distance filter for position stream (meters)
  static const int _positionStreamDistanceFilter = 50;

  /// Whether location tracking is currently active
  bool get isTracking => _isTracking;
  
  /// Last known position from GPS
  Position? get lastPosition => _lastPosition;
  
  /// Last time server was updated with location
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// Start location tracking with callbacks for position updates
  /// 
  /// [onLocationUpdate] is called for every position received from GPS
  /// [onServerUpdate] is called when thresholds are met and server should be updated
  /// 
  /// Throws [Exception] if location permission is denied
  Future<void> startTracking({
    required Function(Position) onLocationUpdate,
    required Function(double lat, double lng) onServerUpdate,
  }) async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. Please grant location permission to use this feature.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Please enable location permission in app settings.');
    }

    // Initialize position stream with high accuracy and 50m distance filter
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _positionStreamDistanceFilter,
      ),
    ).listen(
      (Position position) async {
        // Update last position
        _lastPosition = position;
        
        // Invoke onLocationUpdate callback for every position
        try {
          onLocationUpdate(position);
        } catch (e) {
          developer.log(
            'Error in onLocationUpdate callback: $e',
            name: 'LocationTrackingService',
            error: e,
          );
        }
        
        // Check if server update thresholds are met
        if (_shouldUpdateServer(position)) {
          try {
            // Invoke onServerUpdate callback
            await onServerUpdate(position.latitude, position.longitude);
            
            // Record update time after successful server update
            _lastUpdateTime = DateTime.now();
            
            developer.log(
              'Location updated on server: (${position.latitude}, ${position.longitude})',
              name: 'LocationTrackingService',
            );
          } catch (e) {
            // Log error but don't throw - server update failures shouldn't disrupt tracking
            developer.log(
              'Failed to update location on server: $e',
              name: 'LocationTrackingService',
              error: e,
            );
          }
        }
      },
      onError: (error) {
        // Log error but don't throw - stream errors shouldn't crash the app
        developer.log(
          'Location tracking error: $error',
          name: 'LocationTrackingService',
          error: error,
        );
      },
    );

    _isTracking = true;
    developer.log('Location tracking started', name: 'LocationTrackingService');
  }

  /// Check if we should update server based on distance and time thresholds
  /// 
  /// Returns true if:
  /// - This is the first position (no previous update)
  /// - Both time threshold (60 seconds) AND distance threshold (100 meters) are exceeded
  /// 
  /// Returns false if:
  /// - Less than 60 seconds have elapsed since last update
  /// - Distance from last position is less than 100 meters
  bool _shouldUpdateServer(Position newPosition) {
    // First position - always update
    if (_lastUpdateTime == null) {
      return true;
    }

    // Check time threshold - must be at least 60 seconds since last update
    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
    if (timeSinceLastUpdate.inSeconds < _minUpdateInterval) {
      return false;
    }

    // Check distance threshold - must be at least 100 meters from last position
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      
      if (distance < _minDistanceThreshold) {
        return false;
      }
    }

    // Both thresholds exceeded - update server
    return true;
  }

  /// Stop location tracking and clean up resources
  /// 
  /// Cancels the position stream subscription and sets isTracking to false
  Future<void> stopTracking() async {
    // Cancel position stream subscription
    await _positionStream?.cancel();
    _positionStream = null;
    
    // Set isTracking to false
    _isTracking = false;
    
    developer.log('Location tracking stopped', name: 'LocationTrackingService');
  }

  /// Get current position once with high accuracy
  /// 
  /// This is a one-time position request, not continuous tracking
  /// 
  /// Throws [Exception] if location permission is denied or services are disabled
  Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. Please grant location permission to use this feature.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Please enable location permission in app settings.');
    }

    // Get current position with high accuracy
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return position;
  }
}
