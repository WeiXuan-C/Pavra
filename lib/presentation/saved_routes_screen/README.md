# Saved Routes Screen

## Overview
The Saved Routes Screen displays a list of saved multi-stop routes with preview, load, delete, and share functionality.

## Features

### 1. Route List Display
- Shows all saved routes with:
  - Route name
  - Travel mode icon (driving, walking, bicycling, transit)
  - Number of stops and waypoints
  - Total distance (if available)
  - Creation date
- Pull-to-refresh functionality to reload routes

### 2. Map Preview
- Split-screen layout with route list on the left and map preview on the right
- Tapping a route shows:
  - Numbered markers for start (green), waypoints (orange), and destination (red)
  - Polyline connecting all points
  - Color-coded by travel mode
- Auto-fits map bounds to show entire route

### 3. Route Actions

#### Load Route
- Opens the Multi-Stop Route Planner with the saved route pre-populated
- All waypoints, start, destination, and travel mode are loaded
- User can modify and recalculate the route

#### Share Route
- Generates shareable text format of the route
- Copies to clipboard for easy sharing
- Includes route name, travel mode, all coordinates, and distance

#### Delete Route
- Soft delete with confirmation dialog
- Removes route from list and clears map preview if selected

### 4. Empty State
- Shows helpful message when no routes are saved
- Provides button to create a new route

## Navigation

### Route Name
- Defined in `app_routes.dart` as `/saved-routes`
- Registered in `app_router.dart`

### Access Points
- Can be accessed from navigation menu
- Can navigate to Multi-Stop Route Planner by tapping "Load" on any route

## Technical Details

### Dependencies
- `SavedRouteService` - Manages route CRUD operations
- `SavedRouteRepository` - Database access layer
- `SavedRouteApi` - Supabase API integration
- `GoogleMap` - Map preview display

### Data Model
Uses `SavedRouteWithWaypoints` which includes:
- Route ID, name, and creation date
- Start location, waypoints list, and destination
- Travel mode and total distance

### UI Layout
- Responsive split-screen design
- Left panel: Scrollable route list (flex: 2)
- Right panel: Map preview (flex: 3)
- Mobile-friendly with proper spacing using Sizer package

## Requirements Validation
✅ Requirement 4.3 - Display saved routes list
✅ Requirement 4.4 - Load route into planner
✅ Requirement 4.5 - Delete route (soft delete)
✅ Requirement 11.1 - Share route functionality
