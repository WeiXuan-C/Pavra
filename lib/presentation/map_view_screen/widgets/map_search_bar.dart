import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class MapSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilterTap;

  const MapSearchBar({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  final List<String> _recentSearches = [
    'Downtown Main Street',
    'Highway 101',
    'Oak Avenue',
    'Central Park Area',
  ];
  List<String> _searchSuggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isSearching = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchSuggestions.clear();
      } else {
        // Mock search suggestions
        _searchSuggestions =
            [
                  'Main Street, Downtown',
                  'Main Avenue, Uptown',
                  'Main Boulevard, Westside',
                ]
                .where(
                  (suggestion) =>
                      suggestion.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _focusNode.unfocus();
    widget.onSearch(suggestion);
    setState(() {
      _isSearching = false;
      if (!_recentSearches.contains(suggestion)) {
        _recentSearches.insert(0, suggestion);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(3.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                      _selectSuggestion(value);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search locations...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'search',
                        color:
                            AppTheme.lightTheme.textTheme.bodySmall?.color ??
                            Colors.grey,
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
                                color:
                                    AppTheme
                                        .lightTheme
                                        .textTheme
                                        .bodySmall
                                        ?.color ??
                                    Colors.grey,
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

              // Filter button
              Container(
                margin: EdgeInsets.only(right: 2.w),
                child: IconButton(
                  onPressed: widget.onFilterTap,
                  icon: CustomIconWidget(
                    iconName: 'tune',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
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
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(3.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                      style: AppTheme.lightTheme.textTheme.titleSmall,
                    ),
                  ),
                  ..._searchSuggestions.map(
                    (suggestion) =>
                        _buildSuggestionTile(suggestion, 'location_on'),
                  ),
                ],
                if (_searchSuggestions.isEmpty &&
                    _recentSearches.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Text(
                      l10n.map_recentSearches,
                      style: AppTheme.lightTheme.textTheme.titleSmall,
                    ),
                  ),
                  ..._recentSearches.map(
                    (search) => _buildSuggestionTile(search, 'history'),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionTile(String text, String iconName) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.lightTheme.textTheme.bodySmall?.color ?? Colors.grey,
        size: 20,
      ),
      title: Text(text, style: AppTheme.lightTheme.textTheme.bodyMedium),
      onTap: () => _selectSuggestion(text),
      dense: true,
    );
  }
}
