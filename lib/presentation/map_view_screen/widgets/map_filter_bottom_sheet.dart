import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

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
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
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
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),

          // Title
          Text(
            'Filter Road Issues',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          SizedBox(height: 3.h),

          // Issue Types Section
          Text('Issue Types', style: AppTheme.lightTheme.textTheme.titleMedium),
          SizedBox(height: 1.h),

          _buildFilterTile('Potholes', 'potholes'),
          _buildFilterTile('Cracks', 'cracks'),
          _buildFilterTile('Obstacles', 'obstacles'),
          _buildFilterTile('Poor Lighting', 'lighting'),

          SizedBox(height: 2.h),

          // Severity Levels Section
          Text(
            'Severity Levels',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),

          _buildFilterTile('Critical', 'critical'),
          _buildFilterTile('Moderate', 'moderate'),
          _buildFilterTile('Minor', 'minor'),

          SizedBox(height: 2.h),

          // Status Section
          Text('Status', style: AppTheme.lightTheme.textTheme.titleMedium),
          SizedBox(height: 1.h),

          _buildFilterTile('Reported', 'reported'),
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
                  child: Text('Clear All'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged(_filters);
                    Navigator.pop(context);
                  },
                  child: Text('Apply Filters'),
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
    return CheckboxListTile(
      title: Text(title, style: AppTheme.lightTheme.textTheme.bodyLarge),
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
