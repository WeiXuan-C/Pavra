# Saved Locations Widgets

This directory contains widgets for the Saved Locations feature.

## SaveLocationDialog

A dialog for saving a new location with custom label and icon.

### Features
- Input field for custom label
- Icon picker with common location icons (home, work, school, restaurant, etc.)
- Display location name and address (read-only)
- Validates label uniqueness before saving
- Shows error message for duplicate labels

### Usage Example

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/saved_location_service.dart';
import '../../data/repositories/saved_route_repository.dart';
import '../../core/api/saved_route/saved_route_api.dart';
import 'widgets/save_location_dialog.dart';

// In your widget (e.g., MapViewScreen or search results)
Future<void> _showSaveLocationDialog(
  String locationName,
  String? address,
  double latitude,
  double longitude,
) async {
  // Initialize the service
  final supabase = Supabase.instance.client;
  final api = SavedRouteApi(supabase);
  final repository = SavedRouteRepository(api);
  final locationService = SavedLocationService(repository);

  // Show the dialog
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) => SaveLocationDialog(
      locationName: locationName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      locationService: locationService,
    ),
  );

  // Handle the result
  if (result != null) {
    try {
      await locationService.saveLocation(
        label: result['label']!,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        address: address,
        icon: result['icon']!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save location: $e')),
        );
      }
    }
  }
}

// Example: Add a save button to search results
ListTile(
  title: Text(locationName),
  subtitle: Text(address ?? ''),
  trailing: IconButton(
    icon: const Icon(Icons.bookmark_add),
    onPressed: () => _showSaveLocationDialog(
      locationName,
      address,
      latitude,
      longitude,
    ),
  ),
)
```

## EditLocationDialog

A dialog for editing an existing saved location's label and icon.

### Features
- Edit label
- Change icon
- Preserves coordinates and address (read-only during edit)

### Usage Example

```dart
import 'widgets/edit_location_dialog.dart';

Future<void> _editLocation(SavedLocationModel location) async {
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) => EditLocationDialog(
      currentLabel: location.label,
      currentIcon: location.icon,
      locationId: location.id,
    ),
  );

  if (result != null) {
    try {
      await locationService.updateLocation(
        locationId: location.id,
        label: result['label'],
        icon: result['icon'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update location: $e')),
        );
      }
    }
  }
}
```

## Available Icons

The following icons are available in both dialogs:
- `home` - Home location
- `work` - Work/office location
- `school` - School/education
- `restaurant` - Restaurant/dining
- `shopping` - Shopping/retail
- `hospital` - Hospital/medical
- `gym` - Gym/fitness
- `park` - Park/recreation
- `place` - Generic place (default)
- `star` - Starred/favorite
- `favorite` - Favorite location
- `bookmark` - Bookmarked location
- `location` - Location pin
- `map` - Map marker

See `lib/core/utils/icon_mapper.dart` for the complete icon mapping.
