import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class IssueDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> issue;

  const IssueDetailBottomSheet({super.key, required this.issue});

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

          // Issue image
          if (issue['imageUrl'] != null)
            Container(
              width: double.infinity,
              height: 25.h,
              margin: EdgeInsets.only(bottom: 3.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.w),
                color: theme.colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3.w),
                child: CustomImageWidget(
                  imageUrl: issue['imageUrl'] as String,
                  width: double.infinity,
                  height: 25.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Issue title and severity
          Row(
            children: [
              Expanded(
                child: Text(
                  issue['type'] as String? ?? 'Road Issue',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _getSeverityColor(
                    issue['severity'] as String? ?? 'minor',
                  ),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  (issue['severity'] as String? ?? 'minor').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Location
          Row(
            children: [
              CustomIconWidget(
                iconName: 'location_on',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  issue['address'] as String? ?? 'Location not available',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Report date
          Row(
            children: [
              CustomIconWidget(
                iconName: 'access_time',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Reported ${_formatDate(issue['reportedAt'] as DateTime? ?? DateTime.now())}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Status
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Status: ${issue['status'] as String? ?? 'Reported'}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),

          if (issue['description'] != null) ...[
            SizedBox(height: 3.h),
            Text(l10n.map_description, style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            Text(
              issue['description'] as String,
              style: theme.textTheme.bodyMedium,
            ),
          ],

          SizedBox(height: 4.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to directions
                  },
                  icon: CustomIconWidget(
                    iconName: 'directions',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  label: Text(l10n.map_directions),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/report-submission-screen');
                  },
                  icon: CustomIconWidget(
                    iconName: 'add_circle',
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(l10n.map_reportSimilar),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppTheme.lightTheme.colorScheme.error;
      case 'moderate':
        return Colors.orange;
      case 'minor':
        return Colors.amber;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
