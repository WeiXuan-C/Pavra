import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class NearbyIssuesBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> nearbyIssues;
  final Function(Map<String, dynamic>) onIssueSelected;
  final String? currentUserId;

  const NearbyIssuesBottomSheet({
    super.key,
    required this.nearbyIssues,
    required this.onIssueSelected,
    this.currentUserId,
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
    final isOwnIssue = currentUserId != null && issue['created_by'] == currentUserId;
    final severity = issue['severity'] as String? ?? 'moderate';
    final severityColor = _getSeverityColor(context, severity);
    
    return GestureDetector(
      onTap: () => onIssueSelected(issue),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.w),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              left: BorderSide(
                color: severityColor,
                width: 4,
              ),
              top: BorderSide(
                color: isOwnIssue 
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.dividerColor, 
                width: isOwnIssue ? 2 : 1,
              ),
              right: BorderSide(
                color: isOwnIssue 
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.dividerColor, 
                width: isOwnIssue ? 2 : 1,
              ),
              bottom: BorderSide(
                color: isOwnIssue 
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.dividerColor, 
                width: isOwnIssue ? 2 : 1,
              ),
            ),
          ),
        child: Row(
          children: [
            // Severity indicator strip with icon
            Container(
              width: 12.w,
              padding: EdgeInsets.symmetric(vertical: 3.w),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2.5.w),
                  bottomLeft: Radius.circular(2.5.w),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getSeverityIconData(severity),
                    color: severityColor,
                    size: 24,
                  ),
                  SizedBox(height: 0.5.h),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      _getSeverityLabel(severity, l10n),
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Issue image
            Container(
              width: 15.w,
              height: 15.w,
              margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
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
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.dividerColor,
                        size: 20,
                      ),
                    ),
            ),

            // Issue details
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue['title'] as String? ?? 'Road Issue',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwnIssue)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            margin: EdgeInsets.only(right: 2.w),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(1.w),
                            ),
                            child: Text(
                              'YOURS',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                          size: 14,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            _formatDistance(issue['distance'] ?? issue['distance_miles'], l10n),
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                          size: 14,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          _formatDate(_parseDate(issue['created_at']), l10n),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Navigation arrow
            Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: Icon(
                Icons.chevron_right,
                color: theme.dividerColor,
                size: 24,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _getSeverityLabel(String severity, AppLocalizations l10n) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return l10n.severity_critical;
      case 'high':
        return l10n.severity_high;
      case 'moderate':
        return l10n.severity_moderate;
      case 'low':
        return l10n.severity_low;
      case 'minor':
        return l10n.severity_minor;
      default:
        return severity.toUpperCase();
    }
  }

  IconData _getSeverityIconData(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning;
      case 'moderate':
        return Icons.error_outline;
      case 'low':
        return Icons.info_outline;
      case 'minor':
        return Icons.report_problem_outlined;
      default:
        return Icons.help_outline;
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

  String _formatDistance(dynamic distance, AppLocalizations l10n) {
    if (distance == null) return 'Unknown distance';
    
    final distNum = distance is num ? distance.toDouble() : double.tryParse(distance.toString()) ?? 0.0;
    
    if (distNum < 0.1) {
      // Convert to feet if less than 0.1 miles
      final feet = (distNum * 5280).round();
      return l10n.map_feetAway(feet);
    } else {
      return l10n.map_milesAway(distNum.toStringAsFixed(1));
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return l10n.map_daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return l10n.map_hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return l10n.map_minutesAgo(difference.inMinutes);
    } else {
      return l10n.map_justNow;
    }
  }
}
