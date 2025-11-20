import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

class MapFilterBottomSheet extends StatefulWidget {
  final Map<String, bool> selectedFilters;
  final Function(Map<String, bool>) onFiltersChanged;

  const MapFilterBottomSheet({
    super.key,
    required this.selectedFilters,
    required this.onFiltersChanged,
  });

  @override
  State<MapFilterBottomSheet> createState() => _MapFilterBottomSheetState();
}

class _MapFilterBottomSheetState extends State<MapFilterBottomSheet> {
  late Map<String, bool> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.selectedFilters);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.only(bottom: 3.h),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),

          // Title
          Text(
            l10n.map_filterTitle,
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 3.h),

          // Severity Levels Section
          Text(
            l10n.map_severityLevels,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),

          _buildFilterTile('Critical', 'critical'),
          _buildFilterTile(l10n.report_high, 'high'),
          _buildFilterTile('Moderate', 'moderate'),
          _buildFilterTile(l10n.report_low, 'low'),
          _buildFilterTile('Minor', 'minor'),

          SizedBox(height: 2.h),

          // Status Section
          Text(
            l10n.map_status,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),

          _buildFilterTile('Draft', 'draft'),
          _buildFilterTile('Submitted', 'submitted'),
          _buildFilterTile('Reviewed', 'reviewed'),
          _buildFilterTile('Spam', 'spam'),
          _buildFilterTile('Discarded', 'discard'),

          SizedBox(height: 4.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      // Set all to true (show all)
                      _filters.updateAll((key, value) => true);
                    });
                  },
                  child: Text('Select All'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged(_filters);
                    Navigator.pop(context);
                  },
                  child: Text(l10n.map_applyFilters),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildFilterTile(String title, String key) {
    final theme = Theme.of(context);
    return CheckboxListTile(
      title: Text(title, style: theme.textTheme.bodyLarge),
      value: _filters[key] ?? false,
      onChanged: (bool? value) {
        setState(() {
          _filters[key] = value ?? false;
        });
      },
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
