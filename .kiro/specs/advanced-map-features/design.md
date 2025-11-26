# Design Document

## Overview

This design document outlines the implementation of three advanced map features for the Pavra application: Multi-Stop Route Planning, Voice Search Capability, and Favorite/Saved Locations. These features extend the existing Google Maps-style navigation system to provide users with enhanced route planning capabilities, hands-free search functionality, and quick access to frequently visited locations.

The implementation will leverage the existing `saved_locations` and `saved_routes` database tables, integrate with the current `DirectionsService` and `MapService`, and introduce new components for voice recognition, route optimization, and saved location management.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Map Screen   │  │ Route Planner│  │ Saved Locs   │      │
│  │ with Voice   │  │ Screen       │  │ Screen       │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Voice Search │  │ Multi-Stop   │  │ Saved Loc    │      │
│  │ Service      │  │ Route Service│  │ Service      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Directions   │  │ Map Service  │  │ Route        │      │
│  │ Service      │  │ (existing)   │  │ Optimizer    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Repository Layer                          │
│  ┌──────────────┐  ┌──────────────┐                         │
│  │ Saved Route  │  │ Saved Loc    │                         │
│  │ Repository   │  │ Repository   │                         │
│  └──────────────┘  └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Supabase     │  │ Google Maps  │  │ Speech       │      │
│  │ Database     │  │ API          │  │ Recognition  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Component Interactions

1. **Voice Search Flow**: User taps voice button → VoiceSearchService activates speech recognition → converts speech to text → triggers MapService search → displays results
2. **Multi-Stop Route Flow**: User adds waypoints → MultiStopRouteService calculates route segments → DirectionsService fetches directions for each segment → displays combined route with markers
3. **Saved Location Flow**: User saves location → SavedLocationService stores in database → location appears in search results and quick access buttons

## Components and Interfaces

### 1. VoiceSearchService

Handles speech-to-text conversion and voice command processing.

```dart
class VoiceSearchService {
  final SpeechToText _speechToText;
  
  // Initialize speech recognition
  Future<bool> initialize();
  
  // Start listening for voice input
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  });
  
  // Stop listening
  Future<void> stopListening();
  
  // Check if speech recognition is available
  bool isAvailable();
  
  // Parse voice command (e.g., "navigate home")
  VoiceCommand parseCommand(String text);
}

class VoiceCommand {
  final VoiceCommandType type;
  final String? location;
  final String? rawText;
  
  VoiceCommand({
    required this.type,
    this.location,
    this.rawText,
  });
}

enum VoiceCommandType {
  search,
  navigateHome,
  navigateWork,
  navigateTo,
  stopNavigation,
  showNearbyIssues,
  unknown,
}
```

### 2. MultiStopRouteService

Manages multi-stop route planning and calculation.

```dart
class MultiStopRouteService {
  final DirectionsService _directionsService;
  final MapService _mapService;
  
  // Calculate route with multiple waypoints
  Future<MultiStopRoute?> calculateRoute({
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
    required String travelMode,
  });
  
  // Optimize waypoint order to minimize distance
  Future<List<LatLng>> optimizeWaypoints({
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
    required String travelMode,
  });
  
  // Get nearby issues along route
  Future<List<Map<String, dynamic>>> getIssuesAlongRoute({
    required List<LatLng> routePoints,
    required double radiusMiles,
  });
  
  // Calculate total distance and duration
  RouteMetrics calculateMetrics(MultiStopRoute route);
}

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
```

### 3. SavedLocationService

Manages saved locations and quick access shortcuts.

```dart
class SavedLocationService {
  final SavedRouteRepository _repository;
  
  // Save a new location
  Future<SavedLocationModel> saveLocation({
    required String label,
    required String locationName,
    required double latitude,
    required double longitude,
    String? address,
    String icon = 'place',
  });
  
  // Get all saved locations
  Future<List<SavedLocationModel>> getSavedLocations();
  
  // Get Home location
  Future<SavedLocationModel?> getHomeLocation();
  
  // Get Work location
  Future<SavedLocationModel?> getWorkLocation();
  
  // Update saved location
  Future<SavedLocationModel> updateLocation({
    required String locationId,
    String? label,
    String? icon,
  });
  
  // Delete saved location (soft delete)
  Future<void> deleteLocation(String locationId);
  
  // Check if label already exists
  Future<bool> labelExists(String label);
  
  // Search saved locations
  List<SavedLocationModel> searchSavedLocations(
    String query,
    List<SavedLocationModel> locations,
  );
}
```

### 4. RouteOptimizer

Implements route optimization algorithms.

```dart
class RouteOptimizer {
  // Optimize waypoints using nearest neighbor algorithm
  Future<OptimizationResult> optimizeNearestNeighbor({
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
  });
  
  // Calculate distance matrix between all points
  Future<List<List<double>>> calculateDistanceMatrix(
    List<LatLng> points,
  );
  
  // Calculate distance savings
  double calculateSavings({
    required double originalDistance,
    required double optimizedDistance,
  });
}

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
}
```

### 5. SavedRouteService

Manages saved multi-stop routes.

```dart
class SavedRouteService {
  final SavedRouteRepository _repository;
  
  // Save a multi-stop route
  Future<SavedRouteWithWaypoints> saveRoute({
    required String name,
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
    required String travelMode,
    double? totalDistance,
  });
  
  // Get all saved routes
  Future<List<SavedRouteWithWaypoints>> getSavedRoutes();
  
  // Load a saved route
  Future<SavedRouteWithWaypoints?> loadRoute(String routeId);
  
  // Update saved route
  Future<SavedRouteWithWaypoints> updateRoute({
    required String routeId,
    String? name,
    List<LatLng>? waypoints,
  });
  
  // Delete saved route (soft delete)
  Future<void> deleteRoute(String routeId);
  
  // Share route as text
  String shareRouteAsText(SavedRouteWithWaypoints route);
  
  // Import route from shared text
  Future<SavedRouteWithWaypoints?> importRoute(String sharedText);
}

class SavedRouteWithWaypoints {
  final String id;
  final String name;
  final LatLng start;
  final List<LatLng> waypoints;
  final LatLng destination;
  final String travelMode;
  final double? totalDistance;
  final DateTime createdAt;
  
  SavedRouteWithWaypoints({
    required this.id,
    required this.name,
    required this.start,
    required this.waypoints,
    required this.destination,
    required this.travelMode,
    this.totalDistance,
    required this.createdAt,
  });
}
```

## Data Models

### Database Schema Extensions

#### Waypoints Table (New)

```sql
CREATE TABLE IF NOT EXISTS public.route_waypoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES public.saved_routes(id) ON DELETE CASCADE,
    waypoint_order INT NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(route_id, waypoint_order)
);

-- Enable RLS
ALTER TABLE public.route_waypoints ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.route_waypoints TO authenticated;
```

#### Saved Routes Table Updates

The existing `saved_routes` table needs an additional field for travel mode:

```sql
ALTER TABLE public.saved_routes 
ADD COLUMN IF NOT EXISTS travel_mode VARCHAR(20) DEFAULT 'driving';
```

### Dart Models

#### SavedLocationModel (Existing - from repository)

```dart
class SavedLocationModel {
  final String id;
  final String userId;
  final String label;
  final String locationName;
  final double latitude;
  final double longitude;
  final String? address;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  
  SavedLocationModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  
  factory SavedLocationModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### RouteWaypointModel (New)

```dart
class RouteWaypointModel {
  final String id;
  final String routeId;
  final int waypointOrder;
  final String locationName;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime createdAt;
  
  RouteWaypointModel({
    required this.id,
    required this.routeId,
    required this.waypointOrder,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.createdAt,
  });
  
  factory RouteWaypointModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  LatLng toLatLng() => LatLng(latitude, longitude);
}
```

## Co
rrectness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Saved Locations Properties

**Property 1: Location persistence completeness**
*For any* valid location with label, coordinates, and address, saving the location should result in a database record containing all provided fields (user ID, label, coordinates, address, icon).
**Validates: Requirements 1.2**

**Property 2: Duplicate label rejection**
*For any* existing saved location label, attempting to save another location with the same label should fail with an error message.
**Validates: Requirements 1.3**

**Property 3: Soft delete preservation**
*For any* saved location, performing a delete operation should set is_deleted to true while preserving all other fields in the database.
**Validates: Requirements 1.6**

**Property 4: Edit invariant preservation**
*For any* saved location edit operation, the coordinates and address fields should remain unchanged while label and icon can be modified.
**Validates: Requirements 1.7**

**Property 5: Home/Work location replacement**
*For any* user updating their Home or Work location, the new location should replace the previous one, ensuring only one Home and one Work location exists per user.
**Validates: Requirements 2.7**

**Property 6: Quick access button visibility**
*For any* user with a saved Home location, the Home quick access button should be visible on the map screen, and similarly for Work location.
**Validates: Requirements 2.3, 2.4**

### Multi-Stop Route Properties

**Property 7: Waypoint insertion ordering**
*For any* waypoint added to a route, it should be inserted between the start point and destination, maintaining the sequence: start → waypoints → destination.
**Validates: Requirements 3.2**

**Property 8: Route recalculation on modification**
*For any* waypoint addition, removal, or reordering operation, the route should be recalculated with updated polyline points and distance/time estimates.
**Validates: Requirements 3.3, 3.4, 10.4**

**Property 9: Waypoint marker numbering**
*For any* multi-stop route with N waypoints, the map should display N+2 numbered markers (start=1, waypoints=2 to N+1, destination=N+2) in the correct sequence.
**Validates: Requirements 3.5**

**Property 10: Travel mode consistency**
*For any* multi-stop route with a specified travel mode, all route segments should be calculated using the same travel mode.
**Validates: Requirements 3.6**

**Property 11: Sequential waypoint navigation**
*For any* multi-stop route during active navigation, reaching waypoint N should automatically advance navigation to waypoint N+1.
**Validates: Requirements 3.8**

**Property 12: Route save-load round trip**
*For any* multi-stop route that is saved and then loaded, the loaded route should contain the same waypoints in the same order with the same travel mode.
**Validates: Requirements 4.4**

**Property 13: Route soft delete preservation**
*For any* saved route, performing a delete operation should set is_deleted to true while preserving the route ID and all waypoint data.
**Validates: Requirements 4.5**

**Property 14: Route edit ID invariant**
*For any* saved route edit operation, the route ID should remain unchanged while name and waypoints can be modified.
**Validates: Requirements 4.6**

### Route Optimization Properties

**Property 15: Optimization distance improvement**
*For any* route with 3 or more waypoints, the optimized route's total distance should be less than or equal to the original route's distance.
**Validates: Requirements 5.2**

**Property 16: Optimization endpoint preservation**
*For any* route optimization, the start point and destination should remain in their original positions while only intermediate waypoints are reordered.
**Validates: Requirements 5.3**

**Property 17: Optimization failure safety**
*For any* route optimization that fails, the original waypoint order should be preserved unchanged.
**Validates: Requirements 5.5**

### Voice Search Properties

**Property 18: Voice search result format consistency**
*For any* successful voice search, the results should be displayed in the same format as text search results (same fields, same layout).
**Validates: Requirements 6.6**

**Property 19: Speech recognition workflow completion**
*For any* successful speech-to-text conversion, the system should automatically trigger a location search with the recognized text.
**Validates: Requirements 6.3**

**Property 20: Ambiguous command clarification**
*For any* voice command that matches multiple interpretations, the system should display clarification options for user selection.
**Validates: Requirements 7.6**

### Integration Properties

**Property 21: Saved location search inclusion**
*For any* search query, if saved locations match the query text, they should be included in the search results with a star icon indicator.
**Validates: Requirements 9.1, 9.2**

**Property 22: Saved location waypoint availability**
*For any* waypoint addition in multi-stop route planning, the user should be able to select from their saved locations list.
**Validates: Requirements 9.3**

**Property 23: Route distance and time display**
*For any* calculated multi-stop route, the system should display both total distance and estimated total travel time.
**Validates: Requirements 10.1, 10.2**

**Property 24: Travel mode recalculation**
*For any* travel mode change on a multi-stop route, the distance and time estimates should be recalculated and updated.
**Validates: Requirements 10.3**

**Property 25: Route share-import round trip**
*For any* saved route that is shared and then imported by another user, the imported route should contain the same route name, waypoints, and travel mode.
**Validates: Requirements 11.5**

**Property 26: Route issues spatial query**
*For any* multi-stop route, the system should query and display road issues within 1 mile of any point along the route path.
**Validates: Requirements 12.1**

**Property 27: Critical issue warning display**
*For any* multi-stop route with critical severity issues along the path, the system should display a warning notification to the user.
**Validates: Requirements 12.4**

## Error Handling

### Voice Search Error Handling

1. **Speech Recognition Unavailable**: Display error message "Voice search is not available on this device" and disable voice search button
2. **Microphone Permission Denied**: Prompt user to grant microphone permission with link to settings
3. **Speech Recognition Timeout**: Display "No speech detected" message and allow retry
4. **Network Error During Recognition**: Queue the request and retry when connection is restored
5. **Ambiguous Speech**: Display recognized text with edit option before searching

### Route Calculation Error Handling

1. **No Route Found**: Display "No route available for selected travel mode" with suggestion to try different mode
2. **API Rate Limit Exceeded**: Display error and suggest trying again later, cache last successful route
3. **Invalid Waypoint Coordinates**: Validate coordinates before API call, display error for invalid points
4. **Optimization Failure**: Maintain original route order and log error, display user-friendly message
5. **Network Timeout**: Retry up to 3 times with exponential backoff, then display error

### Database Error Handling

1. **Duplicate Label**: Catch unique constraint violation and display "Label already exists" error
2. **Connection Failure**: Queue operations locally and sync when connection restored
3. **Permission Denied**: Display authentication error and prompt re-login
4. **Data Validation Failure**: Display specific field errors to user before submission
5. **Soft Delete Conflict**: Check is_deleted flag before operations, handle gracefully

### Integration Error Handling

1. **Google Maps API Error**: Log error details, display user-friendly message, fallback to cached data if available
2. **Saved Location Not Found**: Handle deleted locations gracefully, remove from UI
3. **Route Waypoint Limit**: Enforce maximum of 10 waypoints, display error if exceeded
4. **Invalid Travel Mode**: Validate travel mode before API call, default to "driving" if invalid

## Testing Strategy

### Unit Testing

**Saved Location Service Tests:**
- Test saving location with all required fields
- Test duplicate label detection and rejection
- Test soft delete functionality
- Test Home/Work location special handling
- Test location search and filtering

**Multi-Stop Route Service Tests:**
- Test route calculation with multiple waypoints
- Test waypoint addition, removal, and reordering
- Test route metrics calculation (distance, time)
- Test travel mode application to all segments
- Test route save and load operations

**Route Optimizer Tests:**
- Test nearest neighbor optimization algorithm
- Test distance matrix calculation
- Test start/end point preservation
- Test optimization with 2, 3, 5, 10 waypoints
- Test optimization failure handling

**Voice Search Service Tests:**
- Test voice command parsing (navigate home, navigate to, etc.)
- Test command type detection
- Test ambiguous command handling
- Test speech-to-text integration (mocked)

### Property-Based Testing

We will use the **test** package with custom property testing utilities for Dart/Flutter. Each property will run a minimum of 100 iterations with randomly generated inputs.

**Property Test 1: Location save-retrieve round trip**
- Generate random location data (label, coordinates, address, icon)
- Save location to database
- Retrieve location by ID
- Assert all fields match original data
- **Feature: advanced-map-features, Property 1: Location persistence completeness**

**Property Test 2: Duplicate label rejection consistency**
- Generate random label
- Save first location with label
- Attempt to save second location with same label
- Assert second save fails with error
- **Feature: advanced-map-features, Property 2: Duplicate label rejection**

**Property Test 3: Soft delete preservation**
- Generate and save random location
- Perform delete operation
- Retrieve location from database
- Assert is_deleted is true and all other fields unchanged
- **Feature: advanced-map-features, Property 3: Soft delete preservation**

**Property Test 4: Edit invariant preservation**
- Generate and save random location
- Edit label and icon
- Retrieve updated location
- Assert coordinates and address unchanged, label and icon updated
- **Feature: advanced-map-features, Property 4: Edit invariant preservation**

**Property Test 5: Waypoint insertion ordering**
- Generate random start, destination, and waypoints
- Add waypoints one by one
- Assert each waypoint is between start and destination
- Assert final order is start → waypoints → destination
- **Feature: advanced-map-features, Property 7: Waypoint insertion ordering**

**Property Test 6: Route recalculation on modification**
- Generate random multi-stop route
- Calculate initial route
- Add/remove waypoint
- Assert route is recalculated with new polyline
- **Feature: advanced-map-features, Property 8: Route recalculation on modification**

**Property Test 7: Travel mode consistency**
- Generate random waypoints and travel mode
- Calculate multi-stop route
- Assert all segments use same travel mode
- **Feature: advanced-map-features, Property 10: Travel mode consistency**

**Property Test 8: Route save-load round trip**
- Generate random multi-stop route
- Save route to database
- Load route by ID
- Assert waypoints, order, and travel mode match
- **Feature: advanced-map-features, Property 12: Route save-load round trip**

**Property Test 9: Optimization distance improvement**
- Generate random route with 3-10 waypoints
- Calculate original distance
- Optimize route
- Assert optimized distance ≤ original distance
- **Feature: advanced-map-features, Property 15: Optimization distance improvement**

**Property Test 10: Optimization endpoint preservation**
- Generate random route with waypoints
- Optimize route
- Assert start and destination unchanged
- Assert only intermediate waypoints reordered
- **Feature: advanced-map-features, Property 16: Optimization endpoint preservation**

**Property Test 11: Voice search result format consistency**
- Generate random search query
- Perform text search
- Perform voice search with same query (mocked)
- Assert result formats match
- **Feature: advanced-map-features, Property 18: Voice search result format consistency**

**Property Test 12: Saved location search inclusion**
- Generate and save random locations
- Generate search query matching some locations
- Perform search
- Assert matching saved locations included with star icon
- **Feature: advanced-map-features, Property 21: Saved location search inclusion**

**Property Test 13: Route share-import round trip**
- Generate random multi-stop route
- Share route as text
- Import shared text
- Assert imported route matches original
- **Feature: advanced-map-features, Property 25: Route share-import round trip**

### Integration Testing

1. **End-to-End Voice Search Flow**: Voice button → speech recognition → search → results display
2. **Multi-Stop Route Creation Flow**: Add waypoints → calculate route → save route → load route
3. **Saved Location Integration**: Save location → search for location → use in route → navigate
4. **Route Optimization Flow**: Create route → optimize → verify distance savings → save optimized route
5. **Home/Work Quick Access**: Save Home → tap quick access → verify navigation starts

### UI Testing

1. **Voice Search UI**: Test microphone icon animation, listening indicator, transcription display
2. **Route Planner UI**: Test waypoint drag-and-drop, reordering, numbered markers
3. **Saved Locations UI**: Test location list, edit dialog, delete confirmation, icon selection
4. **Quick Access Buttons**: Test Home/Work button visibility and navigation trigger
5. **Route Details UI**: Test distance/time display, issue count badges, optimization results

## Dependencies

### New Package Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Speech recognition for voice search
  speech_to_text: ^7.0.0
  
  # Text-to-speech for voice feedback
  flutter_tts: ^4.2.0
  
  # Permission handling for microphone
  # (already included: permission_handler: ^12.0.1)
```

### Existing Dependencies

- `google_maps_flutter: ^2.13.1` - Map display and markers
- `http: ^1.1.0` - API calls to Google Maps Directions API
- `supabase_flutter: ^2.10.3` - Database operations
- `provider: ^6.1.2` - State management
- `logger: ^2.5.0` - Logging
- `shared_preferences: ^2.3.3` - Local storage for recent searches

## Implementation Notes

### Database Migration Steps

1. **Apply saved_locations table**: Execute `lib/database/tables/saved_locations.sql` in Supabase
2. **Apply saved_routes table**: Execute `lib/database/tables/saved_routes.sql` in Supabase
3. **Create route_waypoints table**: Execute new waypoints table SQL
4. **Add travel_mode column**: Alter saved_routes table to add travel_mode field
5. **Set up RLS policies**: Configure row-level security for all new tables

### Google Maps API Requirements

- **Directions API**: Must be enabled for multi-stop route calculation
- **Geocoding API**: Already in use for address lookup
- **Places API**: Optional for enhanced location search
- **API Key Restrictions**: Ensure API key has proper restrictions and quotas

### Voice Search Platform Considerations

- **Android**: Uses Google Speech Recognition, requires RECORD_AUDIO permission
- **iOS**: Uses Apple Speech Recognition, requires speech recognition permission and microphone access
- **Web**: Uses Web Speech API (browser-dependent)
- **Offline**: Voice search requires internet connection for speech-to-text processing

### Route Optimization Algorithm

Using **Nearest Neighbor Algorithm** for simplicity and performance:

1. Start at the origin point
2. Find the nearest unvisited waypoint
3. Move to that waypoint and mark as visited
4. Repeat until all waypoints visited
5. End at destination

**Time Complexity**: O(n²) where n is number of waypoints
**Space Complexity**: O(n)

For better optimization (at cost of performance), consider:
- **2-opt algorithm**: For routes with 5+ waypoints
- **Genetic algorithm**: For routes with 10+ waypoints
- **Google Maps Waypoint Optimization**: Use `optimize:true` parameter in API call

### Performance Considerations

1. **Route Calculation**: Cache route segments to avoid redundant API calls
2. **Voice Recognition**: Implement timeout (5 seconds) to prevent hanging
3. **Database Queries**: Index on user_id and label for fast lookups
4. **Map Rendering**: Limit waypoint markers to 10 to prevent UI lag
5. **Optimization**: Run in background isolate for routes with 5+ waypoints

## Security Considerations

1. **User Data Isolation**: RLS policies ensure users only access their own saved locations and routes
2. **Input Validation**: Validate all coordinates, labels, and route data before database operations
3. **API Key Protection**: Store Google Maps API key in environment variables, never in code
4. **Voice Data Privacy**: Speech-to-text data should not be logged or stored
5. **Shared Route Validation**: Validate imported route data to prevent injection attacks

## Accessibility

1. **Voice Search**: Provide visual feedback for users who are deaf or hard of hearing
2. **Screen Reader Support**: Add semantic labels to all interactive elements
3. **High Contrast**: Ensure waypoint markers and buttons have sufficient contrast
4. **Font Scaling**: Support dynamic font sizes for route details and saved location lists
5. **Haptic Feedback**: Provide vibration feedback for voice search activation and route optimization completion
