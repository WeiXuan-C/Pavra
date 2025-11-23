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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),

          // Fixed bottom buttons
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            // Set all to true (show all)
                            _filters.updateAll((key, value) => true);
                          });
                        },
                        icon: Icon(Icons.check_circle_outline, size: 18),
                        label: Text('Select All'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            // Set all to false (hide all)
                            _filters.updateAll((key, value) => false);
                          });
                        },
                        icon: Icon(Icons.clear, size: 18),
                        label: Text('Clear All'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onFiltersChanged(_filters);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    ),
                    child: Text(
                      l10n.map_applyFilters,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTile(String title, String key) {
    final theme = Theme.of(context);
    final isSeverity = ['critical', 'high', 'moderate', 'low', 'minor'].contains(key);
    
    return CheckboxListTile(
      title: Row(
        children: [
          if (isSeverity) ...[
            Container(
              width: 12,
              height: 12,
              margin: EdgeInsets.only(right: 2.w),
              decoration: BoxDecoration(
                color: _getSeverityColor(key),
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(title, style: theme.textTheme.bodyLarge),
        ],
      ),
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.red.shade400;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      case 'minor':
        return Colors.yellow.shade400;
      default:
        return Colors.grey;
    }
  }
}
