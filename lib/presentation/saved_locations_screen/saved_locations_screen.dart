import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/saved_location_service.dart';
import '../../data/models/saved_location_model.dart';
import '../../data/repositories/saved_route_repository.dart';
import '../../core/api/saved_route/saved_route_api.dart';
import '../../core/api/notification/notification_api.dart';
import '../../core/services/notification_helper_service.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/feedback_utils.dart';
import '../../widgets/skeleton_loader.dart';
import '../layouts/header_layout.dart';
import 'widgets/edit_location_dialog.dart';

/// Saved Locations Screen
/// Displays list of saved locations with search, edit, and delete functionality
class SavedLocationsScreen extends StatefulWidget {
  static const String routeName = '/saved-locations';

  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  late SavedLocationService _locationService;
  List<SavedLocationModel> _locations = [];
  List<SavedLocationModel> _filteredLocations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    final notificationHelper = NotificationHelperService(NotificationApi());
    final api = SavedRouteApi(supabase, notificationHelper);
    final repository = SavedRouteRepository(api);
    _locationService = SavedLocationService(repository);
    _loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load saved locations
  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);

    try {
      final locations = await _locationService.getSavedLocations();
      setState(() {
        _locations = locations;
        _filteredLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to load locations: $e',
        );
      }
    }
  }

  /// Filter locations based on search query
  void _filterLocations(String query) {
    setState(() {
      _searchQuery = query;
      _filteredLocations = _locationService.searchSavedLocations(
        query,
        _locations,
      );
    });
  }

  /// Show edit location dialog
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
        await _locationService.updateLocation(
          locationId: location.id,
          label: result['label'],
          icon: result['icon'],
        );

        if (mounted) {
          FeedbackUtils.showSuccess(
            context,
            'Location updated successfully',
          );
          _loadLocations();
        }
      } catch (e) {
        if (mounted) {
          FeedbackUtils.showError(
            context,
            'Failed to update location: $e',
          );
        }
      }
    }
  }

  /// Delete location with confirmation
  Future<void> _deleteLocation(SavedLocationModel location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text(
          'Are you sure you want to delete "${location.label}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _locationService.deleteLocation(location.id);

        if (mounted) {
          FeedbackUtils.showSuccess(
            context,
            'Location deleted successfully',
          );
          _loadLocations();
        }
      } catch (e) {
        if (mounted) {
          FeedbackUtils.showError(
            context,
            'Failed to delete location: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderLayout(
        title: 'Saved Locations',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterLocations('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterLocations,
            ),
          ),

          // Locations list
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return const LocationSkeletonLoader();
                    },
                  )
                : _filteredLocations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadLocations,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredLocations.length,
                          itemBuilder: (context, index) {
                            final location = _filteredLocations[index];
                            return _buildLocationCard(location);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No locations found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved locations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save locations from the map to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build location card
  Widget _buildLocationCard(SavedLocationModel location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            IconMapper.getIcon(location.icon),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          location.label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              location.locationName,
              style: const TextStyle(fontSize: 14),
            ),
            if (location.address != null && location.address!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                location.address!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Created: ${_formatDate(location.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editLocation(location),
              tooltip: 'Edit',
              color: Theme.of(context).colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _deleteLocation(location),
              tooltip: 'Delete',
              color: Colors.red,
            ),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('View ${location.label} on map'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
