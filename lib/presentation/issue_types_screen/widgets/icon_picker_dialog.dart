import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../l10n/app_localizations.dart';

/// Icon Picker Dialog
/// Allows selecting an icon for issue types
class IconPickerDialog extends StatefulWidget {
  final String? currentIcon;

  const IconPickerDialog({super.key, this.currentIcon});

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  String? _selectedIcon;
  final _searchController = TextEditingController();
  List<String> _filteredIcons = [];

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.currentIcon;
    _filteredIcons = IconMapper.getAvailableIcons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterIcons(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIcons = IconMapper.getAvailableIcons();
      } else {
        _filteredIcons = IconMapper.getAvailableIcons()
            .where((icon) => icon.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 90.w,
        height: 70.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.iconPicker_title, style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.iconPicker_searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterIcons,
            ),
            SizedBox(height: 2.h),

            // Icon Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 2.w,
                  mainAxisSpacing: 2.w,
                ),
                itemCount: _filteredIcons.length,
                itemBuilder: (context, index) {
                  final iconName = _filteredIcons[index];
                  final isSelected = iconName == _selectedIcon;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconName;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconMapper.getIcon(iconName),
                            size: 32,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            iconName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 2.h),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.common_cancel),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: _selectedIcon != null
                      ? () => Navigator.pop(context, _selectedIcon)
                      : null,
                  child: Text(l10n.common_save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
