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

          // Issue Types Section
          Text(l10n.map_issueTypes, style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),

          _buildFilterTile(l10n.camera_potholes, 'potholes'),
          _buildFilterTile(l10n.camera_cracks, 'cracks'),
          _buildFilterTile(l10n.camera_obstacles, 'obstacles'),
          _buildFilterTile('Poor Lighting', 'lighting'),

          SizedBox(height: 2.h),

          // Severity Levels Section
          Text(
            l10n.map_severityLevels,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),

          _buildFilterTile(l10n.report_high, 'high'),
          _buildFilterTile(l10n.report_medium, 'medium'),
          _buildFilterTile(l10n.report_low, 'low'),

          SizedBox(height: 2.h),

          // Status Section
          Text(
            l10n.map_status,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),

          _buildFilterTile(l10n.map_reported, 'reported'),
          _buildFilterTile('In Progress', 'in_progress'),
          _buildFilterTile('Resolved', 'resolved'),

          SizedBox(height: 4.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _filters.updateAll((key, value) => false);
                    });
                  },
                  child: Text(l10n.map_clearAll),
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
