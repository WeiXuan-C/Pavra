import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/detection_type.dart';

class DetectionFilterSheet extends StatefulWidget {
  final DetectionType? selectedType;
  final int? selectedSeverity;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DetectionType?) onTypeChanged;
  final Function(int?) onSeverityChanged;
  final Function(DateTime?, DateTime?) onDateRangeChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const DetectionFilterSheet({
    super.key,
    this.selectedType,
    this.selectedSeverity,
    this.startDate,
    this.endDate,
    required this.onTypeChanged,
    required this.onSeverityChanged,
    required this.onDateRangeChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<DetectionFilterSheet> createState() => _DetectionFilterSheetState();
}

class _DetectionFilterSheetState extends State<DetectionFilterSheet> {
  DetectionType? _selectedType;
  int? _selectedSeverity;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedSeverity = widget.selectedSeverity;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter Detections',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Issue Type Filter
          Text(
            'Issue Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: [
              _buildTypeChip(context, null, 'All'),
              ...DetectionType.values
                  .where((type) => type != DetectionType.normal)
                  .map((type) => _buildTypeChip(context, type, type.displayName)),
            ],
          ),
          SizedBox(height: 3.h),

          // Severity Level Filter
          Text(
            'Severity Level',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: [
              _buildSeverityChip(context, null, 'All'),
              for (int i = 1; i <= 5; i++)
                _buildSeverityChip(context, i, 'Level $i'),
            ],
          ),
          SizedBox(height: 3.h),

          // Date Range Filter
          Text(
            'Date Range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  context,
                  'Start Date',
                  _startDate,
                  () => _selectStartDate(context),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildDateButton(
                  context,
                  'End Date',
                  _endDate,
                  () => _selectEndDate(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _selectedSeverity = null;
                      _startDate = null;
                      _endDate = null;
                    });
                    widget.onTypeChanged(null);
                    widget.onSeverityChanged(null);
                    widget.onDateRangeChanged(null, null);
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  child: Text('Clear All'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onTypeChanged(_selectedType);
                    widget.onSeverityChanged(_selectedSeverity);
                    widget.onDateRangeChanged(_startDate, _endDate);
                    widget.onApply();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
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

  Widget _buildTypeChip(BuildContext context, DetectionType? type, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedType == type;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
      ),
    );
  }

  Widget _buildSeverityChip(BuildContext context, int? severity, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedSeverity == severity;

    Color chipColor;
    if (severity == null) {
      chipColor = theme.colorScheme.primary;
    } else if (severity >= 4) {
      chipColor = Colors.red;
    } else if (severity >= 2) {
      chipColor = Colors.amber;
    } else {
      chipColor = Colors.green;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSeverity = selected ? severity : null;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : theme.dividerColor,
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                        : 'Select',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: date != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }
}
