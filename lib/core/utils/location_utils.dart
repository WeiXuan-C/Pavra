import 'dart:math' as math;

/// Utility class for location-based calculations
class LocationUtils {
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in miles
  static double calculateDistanceInMiles(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371; // Earth's radius in km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    final distanceKm = earthRadiusKm * c;
    
    // Convert km to miles (1 km = 0.621371 miles)
    return distanceKm * 0.621371;
  }

  /// Check if user is within specified miles of a location
  static bool isWithinRadius({
    required double userLat,
    required double userLon,
    required double targetLat,
    required double targetLon,
    required double radiusMiles,
  }) {
    final distance = calculateDistanceInMiles(
      userLat,
      userLon,
      targetLat,
      targetLon,
    );
    return distance <= radiusMiles;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
