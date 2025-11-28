import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/app_export.dart';
import '../../../core/services/voice_search_service.dart';
import '../../../core/services/saved_location_service.dart';
import '../../../data/models/saved_location_model.dart';
import '../../../l10n/app_localizations.dart';
import 'voice_search_widget.dart';

class MapSearchBar extends StatefulWidget {
  final Function(String, LatLng?, String?) onSearch;
  final VoidCallback onFilterTap;
  final List<Map<String, dynamic>> issues;
  final int activeFilterCount;
  final Function(VoiceCommand)? onVoiceCommand;
  final SavedLocationService? savedLocationService;

  const MapSearchBar({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
    this.issues = const [],
    this.activeFilterCount = 0,
    this.onVoiceCommand,
    this.savedLocationService,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  List<String> _recentSearches = [];
  List<Map<String, dynamic>> _searchSuggestions = [];
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  List<SavedLocationModel> _savedLocations = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadSavedLocations();
    _focusNode.addListener(() {
      setState(() {
        _isSearching = _focusNode.hasFocus;
      });
    });
  }

  Future<void> _loadSavedLocations() async {
    if (widget.savedLocationService != null) {
      try {
        final locations = await widget.savedLocationService!.getSavedLocations();
        setState(() {
          _savedLocations = locations;
        });
      } catch (e) {
        debugPrint('Error loading saved locations: $e');
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    // Load from shared preferences if needed
    // For now, using default values
    setState(() {
      _recentSearches = [];
    });
  }

  Future<void> _saveRecentSearch(String search) async {
    if (!_recentSearches.contains(search)) {
      setState(() {
        _recentSearches.insert(0, search);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
      // Save to shared preferences if needed
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions.clear();
      });
      return;
    }

    final queryLower = query.toLowerCase();
    final suggestions = <Map<String, dynamic>>[];

    // Search through saved locations first (prioritized)
    if (widget.savedLocationService != null) {
      final matchingSavedLocations = widget.savedLocationService!.searchSavedLocations(
        query,
        _savedLocations,
      );

      for (final location in matchingSavedLocations.take(3)) {
        suggestions.add({
          'type': 'saved_location',
          'title': location.label,
          'subtitle': location.address ?? location.locationName,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'id': location.id,
          'icon': location.icon,
        });
      }
    }

    // Search through issues for matching titles, descriptions, or addresses
    final matchingIssues = widget.issues.where((issue) {
      final title = (issue['title'] as String?)?.toLowerCase() ?? '';
      final description = (issue['description'] as String?)?.toLowerCase() ?? '';
      final address = (issue['address'] as String?)?.toLowerCase() ?? '';
      
      return title.contains(queryLower) || 
             description.contains(queryLower) || 
             address.contains(queryLower);
    }).take(5 - suggestions.length).toList();

    for (final issue in matchingIssues) {
      suggestions.add({
        'type': 'issue',
        'title': issue['title'] ?? 'Untitled Issue',
        'subtitle': issue['address'] ?? 'No address',
        'latitude': issue['latitude'],
        'longitude': issue['longitude'],
        'id': issue['id'],
      });
    }

    setState(() {
      _searchSuggestions = suggestions;
    });
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final title = suggestion['title'] as String;
    final subtitle = suggestion['subtitle'] as String?;
    _searchController.text = title;
    _focusNode.unfocus();
    
    LatLng? location;
    if (suggestion['latitude'] != null && suggestion['longitude'] != null) {
      location = LatLng(
        suggestion['latitude'] as double,
        suggestion['longitude'] as double,
      );
    }
    
    widget.onSearch(title, location, subtitle);
    _saveRecentSearch(title);
    
    setState(() {
      _isSearching = false;
      _searchSuggestions.clear();
    });
  }

  Future<void> _searchLocation(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        
        // Try to get the full address from coordinates
        String? fullAddress;
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            fullAddress = [
              place.street,
              place.locality,
              place.administrativeArea,
              place.postalCode,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          }
        } catch (e) {
          debugPrint('Error getting placemark: $e');
        }
        
        _focusNode.unfocus();
        widget.onSearch(query, latLng, fullAddress);
        _saveRecentSearch(query);
        
        setState(() {
          _isSearching = false;
          _searchSuggestions.clear();
        });
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not found. Try a different search.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _selectRecentSearch(String search) {
    _searchController.text = search;
    _searchLocation(search);
  }

  /// Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
      return false;
    }
    
    return false;
  }

  /// Show dialog when permission is permanently denied
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Microphone Permission Required'),
        content: Text(
          'Voice search requires microphone access. Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Activate voice search
  Future<void> _activateVoiceSearch() async {
    // Request microphone permission first
    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone permission is required for voice search'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Initialize voice search service
    final initialized = await _voiceSearchService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice search is not available on this device'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Show voice search widget as bottom sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VoiceSearchWidget(
          voiceSearchService: _voiceSearchService,
          onSearchResult: (recognizedText) {
            if (recognizedText.isNotEmpty) {
              _searchController.text = recognizedText;
              _searchLocation(recognizedText);
            }
          },
          onCommandRecognized: (command) {
            // Handle voice commands
            if (widget.onVoiceCommand != null) {
              widget.onVoiceCommand!(command);
            } else {
              // Fallback to search if no command handler
              if (command.location != null && command.location!.isNotEmpty) {
                _searchController.text = command.location!;
                _searchLocation(command.location!);
              }
            }
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(left: 4.w, top: 2.h, bottom: 2.h),
      child: Column(
        children: [
          Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(3.w),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _searchLocation(value);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: l10n.map_searchPlaceholder,
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'search',
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: Padding(
                              padding: EdgeInsets.all(3.w),
                              child: CustomIconWidget(
                                iconName: 'clear',
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                size: 20,
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                ),
              ),

              // Voice search button
              IconButton(
                onPressed: _activateVoiceSearch,
                icon: Icon(
                  Icons.mic,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                tooltip: l10n.voice_search,
              ),

              // Filter button with badge
              Container(
                margin: EdgeInsets.only(right: 2.w),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: widget.onFilterTap,
                      icon: CustomIconWidget(
                        iconName: 'tune',
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    if (widget.activeFilterCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '${widget.activeFilterCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search suggestions/recent searches
        if (_isSearching)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(3.w),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_searchSuggestions.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Text(
                      l10n.map_suggestions,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._searchSuggestions.map(
                    (suggestion) => _buildIssueSuggestionTile(context, suggestion),
                  ),
                ] else if (_searchController.text.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.all(3.w),
                    child: ListTile(
                      leading: CustomIconWidget(
                        iconName: 'search',
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      title: Text(
                        'Search for "${_searchController.text}"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => _searchLocation(_searchController.text),
                      dense: true,
                    ),
                  ),
                ] else if (_recentSearches.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Text(
                      l10n.map_recentSearches,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._recentSearches.map(
                    (search) => _buildRecentSearchTile(context, search),
                  ),
                ],
              ],
            ),
          ),

          // Search suggestions/recent searches
          if (_isSearching)
            Container(
              margin: EdgeInsets.only(right: 4.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(3.w),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_searchSuggestions.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Text(
                        l10n.map_suggestions,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._searchSuggestions.map(
                      (suggestion) => _buildIssueSuggestionTile(context, suggestion),
                    ),
                  ] else if (_searchController.text.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.all(3.w),
                      child: ListTile(
                        leading: CustomIconWidget(
                          iconName: 'search',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        title: Text(
                          'Search for "${_searchController.text}"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => _searchLocation(_searchController.text),
                        dense: true,
                      ),
                    ),
                  ] else if (_recentSearches.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Text(
                        l10n.map_recentSearches,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._recentSearches.map(
                      (search) => _buildRecentSearchTile(context, search),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIssueSuggestionTile(BuildContext context, Map<String, dynamic> suggestion) {
    final theme = Theme.of(context);
    final type = suggestion['type'] as String;
    final isSavedLocation = type == 'saved_location';

    return ListTile(
      leading: isSavedLocation
          ? CustomIconWidget(
              iconName: suggestion['icon'] as String? ?? 'place',
              color: theme.colorScheme.primary,
              size: 20,
            )
          : CustomIconWidget(
              iconName: 'warning',
              color: theme.colorScheme.error,
              size: 20,
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              suggestion['title'] as String,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSavedLocation)
            Padding(
              padding: EdgeInsets.only(left: 2.w),
              child: Icon(
                Icons.star,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      subtitle: Text(
        suggestion['subtitle'] as String,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onTap: () => _selectSuggestion(suggestion),
      dense: true,
    );
  }

  Widget _buildRecentSearchTile(BuildContext context, String search) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CustomIconWidget(
        iconName: 'history',
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        size: 20,
      ),
      title: Text(search, style: theme.textTheme.bodyMedium),
      trailing: IconButton(
        icon: Icon(
          Icons.close,
          size: 18,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onPressed: () {
          setState(() {
            _recentSearches.remove(search);
          });
        },
      ),
      onTap: () => _selectRecentSearch(search),
      dense: true,
    );
  }
}
