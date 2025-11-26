# Saved Locations Screen

## Overview
The Saved Locations Screen displays a list of user's saved locations with search, edit, and delete functionality.

## Features Implemented

### 1. Display List of Saved Locations (Requirement 1.4)
- Shows all non-deleted saved locations
- Ordered by creation date (newest first)
- Displays location cards with:
  - Icon (customizable)
  - Label (e.g., Home, Work, School)
  - Location name
  - Address
  - Creation date

### 2. Search/Filter Functionality
- Real-time search as user types
- Searches across:
  - Label
  - Location name
  - Address
- Clear button to reset search

### 3. Edit Location (Requirement 1.7)
- Edit button on each location card
- Opens dialog to edit:
  - Label
  - Icon (from predefined set)
- Preserves coordinates and address (as per requirement)
- Validates label uniqueness

### 4. Delete Location (Requirement 1.6)
- Delete button on each location card
- Confirmation dialog before deletion
- Performs soft delete (sets is_deleted to true)

### 5. Pull-to-Refresh
- Swipe down to refresh the list
- Reloads locations from database

### 6. Empty States
- Shows appropriate message when no locations exist
- Shows "no results" message when search returns empty

## Files Created

1. `lib/presentation/saved_locations_screen/saved_locations_screen.dart`
   - Main screen widget
   - Handles list display, search, and actions

2. `lib/presentation/saved_locations_screen/widgets/edit_location_dialog.dart`
   - Dialog for editing location label and icon
   - Icon picker with common location icons

3. Updated `lib/core/utils/icon_mapper.dart`
   - Added location-specific icons (home, work, school, restaurant, etc.)

4. Updated routing files:
   - `lib/routes/app_router.dart` - Added route mapping
   - `lib/routes/app_routes.dart` - Added route constant

## Usage

Navigate to the screen using:
```dart
Navigator.pushNamed(context, AppRoutes.savedLocations);
```

Or:
```dart
Navigator.pushNamed(context, '/saved-locations');
```

## Dependencies

- `SavedLocationService` - Business logic for location operations
- `SavedRouteRepository` - Data access layer
- `SavedRouteApi` - Supabase API integration
- `IconMapper` - Icon mapping utility

## UI Components

- `HeaderLayout` - App bar with title and actions
- `Card` - Material card for each location
- `ListTile` - Location information display
- `TextField` - Search input
- `RefreshIndicator` - Pull-to-refresh functionality
- `CircularProgressIndicator` - Loading state
- `AlertDialog` - Edit and delete confirmations

## Future Enhancements

- Tap on location to view on map (TODO in code)
- Batch operations (select multiple, delete multiple)
- Sort options (by name, by date, by distance)
- Export/import saved locations
- Share locations with other users
