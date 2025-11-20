import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class NearbyIssuesBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> nearbyIssues;
  final Function(Map<String, dynamic>) onIssueSelected;

  const NearbyIssuesBottomSheet({
    super.key,
    required this.nearbyIssues,
    required this.onIssueSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 12.w,
                height: 0.5.h,
                margin: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    Text(
                      l10n.map_nearbyIssues,
                      style: theme.textTheme.titleLarge,
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        '${nearbyIssues.length} ${l10n.map_found}',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.h),

              // Issues list
              Expanded(
                child: nearbyIssues.isEmpty
                    ? _buildEmptyState(context, l10n)
                    : ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemCount: nearbyIssues.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 2.h),
                        itemBuilder: (context, index) {
                          final issue = nearbyIssues[index];
                          return _buildIssueCard(context, issue, l10n);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'location_off',
            color: theme.dividerColor,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.map_noIssuesFound,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.map_adjustLocation,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(BuildContext context, Map<String, dynamic> issue, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onIssueSelected(issue),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            // Issue image - from issue_photos table
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.w),
                color: theme.colorScheme.surface,
              ),
              child: (issue['issue_photos'] != null && (issue['issue_photos'] as List).isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(2.w),
                      child: CustomImageWidget(
                        imageUrl: (issue['issue_photos'] as List).first['photo_url'] as String,
                        width: 15.w,
                        height: 15.w,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: CustomIconWidget(
                        iconName: _getSeverityIcon(
                          issue['severity'] as String? ?? 'moderate',
                        ),
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
            ),

            SizedBox(width: 3.w),

            // Issue details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue['title'] as String? ?? 'Road Issue',
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(
                            context,
                            issue['severity'] as String? ?? 'moderate',
                          ),
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: Text(
                          (issue['severity'] as String? ?? 'moderate')
                              .toUpperCase(),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white, fontSize: 8.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color:
                            theme.textTheme.bodySmall?.color ??
                            Colors.grey,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          _formatDistance(issue['distance'] ?? issue['distance_miles']),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _formatDate(_parseDate(issue['created_at'])),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Navigation arrow
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.dividerColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return 'error';
      case 'moderate':
        return 'warning';
      case 'low':
      case 'minor':
        return 'info';
      default:
        return 'report_problem';
    }
  }

  Color _getSeverityColor(BuildContext context, String severity) {
    final theme = Theme.of(context);
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return theme.colorScheme.error;
      case 'moderate':
        return Colors.orange;
      case 'low':
      case 'minor':
        return Colors.amber;
      default:
        return theme.colorScheme.primary;
    }
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return 'Unknown distance';
    
    final distNum = distance is num ? distance.toDouble() : double.tryParse(distance.toString()) ?? 0.0;
    
    if (distNum < 0.1) {
      // Convert to feet if less than 0.1 miles
      final feet = (distNum * 5280).round();
      return '$feet ft away';
    } else {
      return '${distNum.toStringAsFixed(1)} mi away';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}
