# Implementation Plan

## Phase 1: Database Schema and Models

- [x] 1. Create database schema for multi-stop routes





  - Create `route_waypoints` table with fields: id, route_id, waypoint_order, location_name, latitude, longitude, address, created_at
  - Add foreign key constraint to saved_routes table
  - Add unique constraint on (route_id, waypoint_order)
  - Enable RLS and grant permissions to authenticated users
  - _Requirements: 3.2, 3.3, 4.2_

- [x] 2. Update saved_routes table schema





  - Add `travel_mode` column (VARCHAR(20), default 'driving')
  - Create migration script to update existing records
  - _Requirements: 3.6, 4.2_

- [x] 3. Create RouteWaypointModel





  - Implement model with id, routeId, waypointOrder, locationName, latitude, longitude, address, createdAt
  - Add fromJson and toJson methods
  - Add toLatLng() helper method
  - _Requirements: 3.2, 4.2_

- [x] 4. Update SavedRouteModel for multi-stop support





  - Add travelMode field
  - Update fromJson and toJson to handle travel_mode
  - Add copyWith method support for travelMode
  - _Requirements: 3.6, 4.2_

## Phase 2: Core Services - Saved Locations

- [x] 5. Create SavedLocationService




  - Implement saveLocation method with label, coordinates, address, icon
  - Implement getSavedLocations method
  - Implement getHomeLocation and getWorkLocation methods
  - Implement updateLocation method (preserving coordinates/address)
  - Implement deleteLocation method (soft delete)
  - Implement labelExists validation method
  - Implement searchSavedLocations method
  - _Requirements: 1.2, 1.3, 1.4, 1.6, 1.7, 2.1, 2.2_

- [x] 5.1 Write property test for location persistence


  - **Property 1: Location persistence completeness**
  - **Validates: Requirements 1.2**

- [x] 5.2 Write property test for duplicate label rejection

  - **Property 2: Duplicate label rejection**
  - **Validates: Requirements 1.3**

- [x] 5.3 Write property test for soft delete preservation

  - **Property 3: Soft delete preservation**
  - **Validates: Requirements 1.6**

- [x] 5.4 Write property test for edit invariant preservation

  - **Property 4: Edit invariant preservation**
  - **Validates: Requirements 1.7**

- [x] 5.5 Write property test for Home/Work location replacement

  - **Property 5: Home/Work location replacement**
  - **Validates: Requirements 2.7**

## Phase 3: Core Services - Multi-Stop Routes
-

- [x] 6. Create MultiStopRouteService






  - Implement calculateRoute method for multiple waypoints
  - Implement getIssuesAlongRoute method (1 mile radius)
  - Implement calculateMetrics method for total distance/duration
  - Create MultiStopRoute class with segments, polylinePoints, totalDistance, totalDuration
  - Create RouteSegment class with start, end, directions, segmentIndex
  - _Requirements: 3.1, 3.2, 3.5, 3.6, 10.1, 10.2, 12.1_

- [x] 6.1 Write property test for waypoint insertion ordering


  - **Property 7: Waypoint insertion ordering**
  - **Validates: Requirements 3.2**

- [x] 6.2 Write property test for route recalculation on modification





  - **Property 8: Route recalculation on modification**
  - **Validates: Requirements 3.3, 3.4, 10.4**

- [x] 6.3 Write property test for travel mode consistency


  - **Property 10: Travel mode consistency**
  - **Validates: Requirements 3.6**

- [x] 7. Create RouteOptimizer service




  - Implement optimizeNearestNeighbor algorithm
  - Implement calculateDistanceMatrix method
  - Implement calculateSavings method
  - Create OptimizationResult class with optimizedWaypoints, originalDistance, optimizedDistance, savingsPercent
  - Preserve start and destination points during optimization
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 7.1 Write property test for optimization distance improvement


  - **Property 15: Optimization distance improvement**
  - **Validates: Requirements 5.2**

- [x] 7.2 Write property test for optimization endpoint preservation

  - **Property 16: Optimization endpoint preservation**
  - **Validates: Requirements 5.3**

- [x] 7.3 Write property test for optimization failure safety

  - **Property 17: Optimization failure safety**
  - **Validates: Requirements 5.5**
-

- [x] 8. Create SavedRouteService for multi-stop routes




  - Implement saveRoute method with waypoints and travel mode
  - Implement getSavedRoutes method
  - Implement loadRoute method with waypoints
  - Implement updateRoute method
  - Implement deleteRoute method (soft delete)
  - Implement shareRouteAsText method
  - Implement importRoute method
  - Create SavedRouteWithWaypoints class
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 8.1 Write property test for route save-load round trip


  - **Property 12: Route save-load round trip**
  - **Validates: Requirements 4.4**

- [x] 8.2 Write property test for route soft delete preservation



  - **Property 13: Route soft delete preservation**
  - **Validates: Requirements 4.5**

- [x] 8.3 Write property test for route edit ID invariant


  - **Property 14: Route edit ID invariant**
  - **Validates: Requirements 4.6**

- [x] 8.4 Write property test for route share-import round trip


  - **Property 25: Route share-import round trip**
  - **Validates: Requirements 11.5**

## Phase 4: Core Services - Voice Search
- [x] 9. Add voice search dependencies





- [ ] 9. Add voice search dependencies

  - Add speech_to_text: ^7.0.0 to pubspec.yaml
  - Add flutter_tts: ^4.2.0 to pubspec.yaml
  - Run flutter pub get
  - _Requirements: 6.1, 6.2, 8.1_
- [x] 10. Create VoiceSearchService



- [ ] 10. Create VoiceSearchService

  - Implement initialize method for speech recognition
  - Implement startListening method with onResult and onError callbacks
  - Implement stopListening method
  - Implement isAvailable method
  - Implement parseCommand method for voice commands
  - Create VoiceCommand class with type, location, rawText
  - Create VoiceCommandType enum (search, navigateHome, navigateWork, navigateTo, stopNavigation, showNearbyIssues, unknown)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [x] 10.1 Write property test for voice search result format consistency


  - **Property 18: Voice search result format consistency**
  - **Validates: Requirements 6.6**

- [x] 10.2 Write property test for speech recognition workflow completion


  - **Property 19: Speech recognition workflow completion**
  - **Validates: Requirements 6.3**

- [x] 10.3 Write property test for ambiguous command clarification



  - **Property 20: Ambiguous command clarification**
  - **Validates: Requirements 7.6**

## Phase 5: Repository Layer Updates
-

- [x] 11. Update SavedRouteRepository for waypoints




  - Add createRouteWithWaypoints method
  - Add getRouteWithWaypoints method
  - Add updateRouteWaypoints method
  - Add deleteRouteWaypoints method (cascade on route delete)
  - Update existing methods to handle travel_mode field
  - _Requirements: 3.2, 4.2, 4.4, 4.6_
-

- [x] 12. Update SavedRouteApi for waypoints




  - Add methods to insert/update/delete waypoints
  - Add method to fetch route with waypoints joined
  - Update route creation to support travel_mode
  - _Requirements: 3.2, 4.2_

## Phase 6: UI Components - Saved Locations
-

- [x] 13. Create SavedLocationsScreen




  - Display list of saved locations ordered by creation date
  - Show location label, name, address, and icon
  - Add search/filter functionality
  - Add edit and delete actions for each location
  - Implement pull-to-refresh
  - _Requirements: 1.4, 1.5, 1.6, 1.7_
-

- [x] 14. Create SaveLocationDialog



  - Input field for custom label
  - Icon picker with common icons (home, work, school, restaurant, etc.)
  - Display location name and address (read-only)
  - Validate label uniqueness before saving
  - Show error message for duplicate labels
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 15. Add Home/Work quick access buttons to MapViewScreen





  - Display Home button when home location exists
  - Display Work button when work location exists
  - Implement tap handlers to start navigation
  - Position buttons in accessible location on map
  - _Requirements: 2.3, 2.4, 2.5, 2.6_

- [x] 15.1 Write property test for quick access button visibility







  - **Property 6: Quick access button visibility**
  - **Validates: Requirements 2.3, 2.4**

## Phase 7: UI Components - Multi-Stop Routes
-

- [x] 16. Create MultiStopRoutePlannerScreen




  - Display start point, destination, and waypoint fields
  - Implement add waypoint button
  - Implement drag-to-reorder functionality for waypoints
  - Implement remove waypoint button for each waypoint
  - Display numbered markers on map (1 for start, 2-N for waypoints, N+1 for destination)
  - Show travel mode selector (driving, walking, bicycling, transit)
  - Display total distance and estimated time
  - Add optimize route button (visible when 3+ waypoints)
  - Add save route button
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 5.1, 10.1, 10.2_

- [x] 16.1 Write property test for waypoint marker numbering


  - **Property 9: Waypoint marker numbering**
  - **Validates: Requirements 3.5**

- [x] 16.2 Write property test for route distance and time display


  - **Property 23: Route distance and time display**
  - **Validates: Requirements 10.1, 10.2**

- [x] 16.3 Write property test for travel mode recalculation


  - **Property 24: Travel mode recalculation**
  - **Validates: Requirements 10.3**
- [x] 17. Create SavedRoutesScreen




- [ ] 17. Create SavedRoutesScreen

  - Display list of saved routes with names and waypoint counts
  - Show route preview on map when tapped
  - Add load route action to populate route planner
  - Add delete route action (soft delete)
  - Add share route action
  - Implement pull-to-refresh
  - _Requirements: 4.3, 4.4, 4.5, 11.1_
- [x] 18. Implement route optimization UI feedback




- [ ] 18. Implement route optimization UI feedback

  - Show loading indicator during optimization
  - Display optimization results (distance savings, new order)
  - Show error message if optimization fails
  - Maintain original route if optimization fails
  - _Requirements: 5.2, 5.3, 5.4, 5.5_

- [x] 19. Implement route issues display





  - Query issues within 1 mile of route path
  - Display issue markers on map with severity colors
  - Show issue count badges by severity
  - Display warning notification for critical issues
  - Add tap handler to show issue details
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 19.1 Write property test for route issues spatial query


  - **Property 26: Route issues spatial query**
  - **Validates: Requirements 12.1**

- [x] 19.2 Write property test for critical issue warning display


  - **Property 27: Critical issue warning display**
  - **Validates: Requirements 12.4**

## Phase 8: UI Components - Voice Search
-

- [x] 20. Add voice search button to MapViewScreen




  - Add microphone icon button to search bar
  - Implement tap handler to activate voice search
  - Request microphone permission on first use
  - _Requirements: 6.1_

- [x] 21. Create VoiceSearchWidget





  - Display pulsing microphone icon during listening
  - Show real-time speech-to-text transcription
  - Display processing indicator
  - Show recognized text with edit option
  - Play listening sound on activation
  - Play success/error sounds based on result
  - Handle permission denied gracefully
  - _Requirements: 6.1, 6.2, 6.4, 6.5, 8.1, 8.2, 8.3, 8.4, 8.5_
- [x] 22. Implement voice command handling




- [ ] 22. Implement voice command handling

  - Parse "navigate to [location]" command
  - Parse "navigate home" command
  - Parse "navigate to work" command
  - Parse "stop navigation" command
  - Parse "show nearby issues" command
  - Display clarification dialog for ambiguous commands
  - Trigger appropriate actions based on command type
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

## Phase 9: Integration and Navigation
- [x] 23. Integrate saved locations with search




- [ ] 23. Integrate saved locations with search

  - Include saved locations in search results
  - Display star icon for saved locations in results
  - Prioritize saved locations in search ranking
  - _Requirements: 9.1, 9.2_


- [x] 23.1 Write property test for saved location search inclusion

  - **Property 21: Saved location search inclusion**
  - **Validates: Requirements 9.1, 9.2**

- [x] 24. Integrate saved locations with route planning





  - Add "Choose from saved locations" option in waypoint picker
  - Display saved locations list when adding waypoint
  - Allow selecting saved location as waypoint
  - _Requirements: 9.3_
-

- [x] 24.1 Write property test for saved location waypoint availability






  - **Property 22: Saved location waypoint availability**
  - **Validates: Requirements 9.3**
-

- [x] 25. Integrate saved locations with map display




  - Display saved location markers on map with distinct icons
  - Show saved location details on marker tap
  - Provide navigation options from saved location marker
  - _Requirements: 9.4, 9.5_

- [x] 26. Implement multi-stop navigation flow





  - Start navigation to first waypoint
  - Automatically advance to next waypoint when reached
  - Display current waypoint and remaining stops
  - Show progress indicator for multi-stop route
  - Handle navigation cancellation
  - _Requirements: 3.7, 3.8_

- [x] 26.1 Write property test for sequential waypoint navigation


  - **Property 11: Sequential waypoint navigation**
  - **Validates: Requirements 3.8**

## Phase 10: Error Handling and Polish

- [x] 27. Implement comprehensive error handling




  - Handle speech recognition unavailable
  - Handle microphone permission denied
  - Handle speech recognition timeout
  - Handle network errors during recognition
  - Handle no route found errors
  - Handle API rate limit exceeded
  - Handle invalid waypoint coordinates
  - Handle optimization failures
  - Handle duplicate label errors
  - Handle database connection failures
  - _Requirements: All error scenarios from design_
-

- [x] 28. Add loading states and feedback




  - Show loading indicator during route calculation
  - Show loading indicator during optimization
  - Show loading indicator during voice recognition
  - Add skeleton loaders for saved locations/routes lists
  - Add success/error toast messages
  - _Requirements: User experience_
-

- [x] 29. Implement accessibility features







  - Add semantic labels to all interactive elements
  - Ensure sufficient contrast for markers and buttons
  - Support dynamic font sizes
  - Add haptic feedback for voice search and optimization
  - Provide visual feedback for voice search (for deaf users)
  - _Requirements: Accessibility from design_

## Phase 11: Testing and Validation
-

- [x] 30. Checkpoint - Ensure all tests pass





  - Ensure all tests pass, ask the user if questions arise.

- [ ] 31. Write integration tests
  - Test end-to-end voice search flow
  - Test multi-stop route creation and save flow
  - Test saved location integration with search and routes
  - Test route optimization flow
  - Test Home/Work quick access flow

- [ ] 32. Write UI tests
  - Test voice search UI animations and feedback
  - Test route planner drag-and-drop
  - Test saved locations list and dialogs
  - Test quick access buttons
  - Test route details display

- [ ] 33. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
