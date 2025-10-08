import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class IssueTypeSelectorWidget extends StatelessWidget {
  final List<Map<String, dynamic>> detectedIssues;
  final List<String> selectedIssues;
  final Function(String) onIssueToggle;

  const IssueTypeSelectorWidget({
    super.key,
    required this.detectedIssues,
    required this.selectedIssues,
    required this.onIssueToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'category',
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Issue Types',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          Text(
            'Select the issues you want to report',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Issue chips
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _getUniqueIssues()
                .map((issue) => _buildIssueChip(issue))
                .toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getUniqueIssues() {
    Map<String, Map<String, dynamic>> uniqueIssues = {};

    for (var issue in detectedIssues) {
      String type = issue['type'] as String;
      if (!uniqueIssues.containsKey(type) ||
          (issue['confidence'] as double) >
              (uniqueIssues[type]!['confidence'] as double)) {
        uniqueIssues[type] = issue;
      }
    }

    return uniqueIssues.values.toList();
  }

  Widget _buildIssueChip(Map<String, dynamic> issue) {
    final String type = issue['type'] as String;
    final double confidence = issue['confidence'] as double;
    final bool isSelected = selectedIssues.contains(type);
    final Color chipColor = _getIssueColor(type);

    return GestureDetector(
      onTap: () => onIssueToggle(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: _getIssueIcon(type),
              color: isSelected ? Colors.white : chipColor,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getIssueDisplayName(type),
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : chipColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(confidence * 100).toInt()}% confidence',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : chipColor.withValues(alpha: 0.7),
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              SizedBox(width: 2.w),
              CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getIssueColor(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return AppTheme.lightTheme.colorScheme.error;
      case 'crack':
        return const Color(0xFFFF9800);
      case 'obstacle':
        return const Color(0xFF9C27B0);
      case 'debris':
        return const Color(0xFF795548);
      case 'flooding':
        return const Color(0xFF2196F3);
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }

  String _getIssueIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return 'warning';
      case 'crack':
        return 'broken_image';
      case 'obstacle':
        return 'block';
      case 'debris':
        return 'scatter_plot';
      case 'flooding':
        return 'water';
      default:
        return 'report_problem';
    }
  }

  String _getIssueDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return 'Pothole';
      case 'crack':
        return 'Road Crack';
      case 'obstacle':
        return 'Obstacle';
      case 'debris':
        return 'Road Debris';
      case 'flooding':
        return 'Water/Flooding';
      default:
        return type.toUpperCase();
    }
  }
}
