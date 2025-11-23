import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DirectionsService {
  final _logger = Logger();
  
  /// Get the Google Maps API key from environment
  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Fetch directions from origin to destination
  /// Returns a list of LatLng points representing the route
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving', // driving, walking, bicycling, transit
  }) async {
    if (_apiKey.isEmpty) {
      _logger.e('❌ Google Maps API key not found in .env file');
      _logger.e('Add GOOGLE_MAPS_API_KEY=your-key to .env');
      return null;
    }

    _logger.i('🗺️ Using API key: ${_apiKey.substring(0, 10)}...');
    _logger.i('📍 Origin: ${origin.latitude}, ${origin.longitude}');
    _logger.i('📍 Destination: ${destination.latitude}, ${destination.longitude}');

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$travelMode'
        '&key=$_apiKey',
      );

      _logger.i('Fetching directions from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');

      final response = await http.get(url);

      _logger.i('Directions API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        _logger.i('Directions API status: ${data['status']}');

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = _decodePolyline(route['overview_polyline']['points']);
          
          // Extract route information
          final leg = route['legs'][0];
          final distance = leg['distance']['text'] as String;
          final duration = leg['duration']['text'] as String;
          final distanceValue = leg['distance']['value'] as int;
          final durationValue = leg['duration']['value'] as int;
          
          final steps = (leg['steps'] as List).map((step) {
            return DirectionStep(
              instruction: _stripHtml(step['html_instructions']),
              distance: step['distance']['text'],
              duration: step['duration']['text'],
              maneuver: step['maneuver'] as String?,
              startLocation: LatLng(
                step['start_location']['lat'],
                step['start_location']['lng'],
              ),
              endLocation: LatLng(
                step['end_location']['lat'],
                step['end_location']['lng'],
              ),
            );
          }).toList();

          _logger.i('Route found: $distance, $duration, ${polylinePoints.length} points');

          return DirectionsResult(
            polylinePoints: polylinePoints,
            distance: distance,
            duration: duration,
            distanceValue: distanceValue,
            durationValue: durationValue,
            steps: steps,
            travelMode: travelMode,
            startLocation: origin,
            endLocation: destination,
          );
        } else {
          _logger.e('❌ Directions API error: ${data['status']}');
          if (data['error_message'] != null) {
            _logger.e('💬 Error message: ${data['error_message']}');
          }
          
          // Provide helpful error messages
          switch (data['status']) {
            case 'REQUEST_DENIED':
              _logger.e('🚫 REQUEST_DENIED - Directions API is not enabled or API key is restricted');
              _logger.e('👉 Go to: https://console.cloud.google.com/google/maps-apis/api-list');
              _logger.e('👉 Enable "Directions API" for your project');
              break;
            case 'OVER_QUERY_LIMIT':
              _logger.e('⚠️ OVER_QUERY_LIMIT - You have exceeded your API quota');
              break;
            case 'ZERO_RESULTS':
              _logger.e('🔍 ZERO_RESULTS - No route found between these locations for travel mode: $travelMode');
              _logger.e('💡 This often happens when the distance is too short for transit/bicycling, or locations are not accessible by this mode');
              break;
            case 'INVALID_REQUEST':
              _logger.e('❓ INVALID_REQUEST - Check your coordinates are valid');
              break;
            default:
              _logger.e('Full response: ${response.body}');
          }
          return null;
        }
      } else {
        _logger.e('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching directions: $e');
      return null;
    }
  }

  /// Decode Google's encoded polyline format
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Strip HTML tags from instructions
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}

/// Result from directions API
class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final int durationValue; // Duration in seconds
  final int distanceValue; // Distance in meters
  final List<DirectionStep> steps;
  final String travelMode;
  final LatLng startLocation;
  final LatLng endLocation;

  DirectionsResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.durationValue,
    required this.distanceValue,
    required this.steps,
    required this.travelMode,
    required this.startLocation,
    required this.endLocation,
  });
}

/// Individual step in directions
class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final String? maneuver; // turn-left, turn-right, etc.
  final LatLng startLocation;
  final LatLng endLocation;

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.maneuver,
    required this.startLocation,
    required this.endLocation,
  });
}
