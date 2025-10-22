import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../l10n/app_localizations.dart';
import './report_skeleton.dart';

enum ReportFilterType { myReports, allReports }

/// Report List Tab
/// 显示报告列表（我的报告或所有报告）
class ReportListTab extends StatefulWidget {
  final ReportFilterType filterType;
  final Function(Map<String, dynamic>) onReportTap;

  const ReportListTab({
    super.key,
    required this.filterType,
    required this.onReportTap,
  });

  @override
  State<ReportListTab> createState() => _ReportListTabState();
}

class _ReportListTabState extends State<ReportListTab> {
  bool _isLoading = false;
  String _sortBy = 'date'; // date, severity, status
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data
    _reports = widget.filterType == ReportFilterType.myReports
        ? _getMyReports()
        : _getAllReports();

    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getMyReports() {
    return [
      {
        'id': 'RPT-001',
        'type': 'Pothole',
        'severity': 'high',
        'status': 'reported',
        'location': 'Main Street & 5th Avenue',
        'description': 'Large pothole causing traffic issues',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        'imageUrl':
            'https://images.pexels.com/photos/1108572/pexels-photo-1108572.jpeg',
        'isMyReport': true,
      },
      {
        'id': 'RPT-002',
        'type': 'Crack',
        'severity': 'medium',
        'status': 'in_progress',
        'location': 'Oak Avenue, Downtown',
        'description': 'Road crack extending across lane',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'imageUrl':
            'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg',
        'isMyReport': true,
      },
      {
        'id': 'RPT-003',
        'type': 'Obstacle',
        'severity': 'low',
        'status': 'resolved',
        'location': 'Pine Street Bridge',
        'description': 'Debris removed from roadway',
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
        'imageUrl':
            'https://images.pexels.com/photos/1108101/pexels-photo-1108101.jpeg',
        'isMyReport': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getAllReports() {
    return [
      ..._getMyReports(),
      {
        'id': 'RPT-004',
        'type': 'Pothole',
        'severity': 'high',
        'status': 'reported',
        'location': 'Highway 101, Mile 23',
        'description': 'Multiple potholes in right lane',
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
        'imageUrl':
            'https://images.pexels.com/photos/1108572/pexels-photo-1108572.jpeg',
        'isMyReport': false,
        'reportedBy': 'John Doe',
      },
      {
        'id': 'RPT-005',
        'type': 'Lighting',
        'severity': 'medium',
        'status': 'reported',
        'location': 'Sunset Boulevard',
        'description': 'Street lights not working',
        'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
        'imageUrl':
            'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg',
        'isMyReport': false,
        'reportedBy': 'Jane Smith',
      },
    ];
  }

  void _sortReports(String sortBy) {
    setState(() {
      _sortBy = sortBy;

      switch (sortBy) {
        case 'date':
          _reports.sort(
            (a, b) => (b['createdAt'] as DateTime).compareTo(
              a['createdAt'] as DateTime,
            ),
          );
          break;
        case 'severity':
          final severityOrder = {'high': 0, 'medium': 1, 'low': 2};
          _reports.sort(
            (a, b) => severityOrder[a['severity']]!.compareTo(
              severityOrder[b['severity']]!,
            ),
          );
          break;
        case 'status':
          final statusOrder = {'reported': 0, 'in_progress': 1, 'resolved': 2};
          _reports.sort(
            (a, b) =>
                statusOrder[a['status']]!.compareTo(statusOrder[b['status']]!),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const ReportSkeleton(itemCount: 5);
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_off,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            SizedBox(height: 2.h),
            Text(l10n.report_noReports, style: theme.textTheme.titleLarge),
            SizedBox(height: 1.h),
            Text(
              l10n.report_noReportsMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sort Options
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          color: theme.cardColor,
          child: Row(
            children: [
              Text(l10n.report_sortBy, style: theme.textTheme.bodyMedium),
              SizedBox(width: 2.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip(l10n.report_sortDate, 'date', theme),
                      SizedBox(width: 2.w),
                      _buildSortChip(
                        l10n.report_sortSeverity,
                        'severity',
                        theme,
                      ),
                      SizedBox(width: 2.w),
                      _buildSortChip(l10n.report_sortStatus, 'status', theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Report List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadReports,
            child: ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: _reports.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final report = _reports[index];
                return _buildReportCard(report, theme, l10n);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value, ThemeData theme) {
    final isSelected = _sortBy == value;
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _sortReports(value);
        }
      },
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: theme.colorScheme.primary,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withValues(alpha: 0.3),
        width: isSelected ? 1.5 : 1,
      ),
    );
  }

  Widget _buildReportCard(
    Map<String, dynamic> report,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final severity = report['severity'] as String;
    final status = report['status'] as String;
    final isMyReport = report['isMyReport'] as bool;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => widget.onReportTap(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Report ID
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      report['id'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),

                  // My Report Badge
                  if (isMyReport)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.report_mine,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Severity Badge
                  _buildSeverityBadge(severity, theme, l10n),
                ],
              ),

              SizedBox(height: 1.h),

              // Type and Location
              Row(
                children: [
                  Icon(
                    _getTypeIcon(report['type'] as String),
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['type'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          report['location'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Description
              Text(
                report['description'] as String,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 1.h),

              // Footer Row
              Row(
                children: [
                  // Status
                  _buildStatusBadge(status, theme, l10n),

                  const Spacer(),

                  // Time
                  Text(
                    timeago.format(report['createdAt'] as DateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),

                  // Reporter (for all reports)
                  if (!isMyReport && report.containsKey('reportedBy')) ...[
                    SizedBox(width: 2.w),
                    Text(
                      '• ${report['reportedBy']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(
    String severity,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    Color color;
    String label;

    switch (severity) {
      case 'high':
        color = Colors.red;
        label = l10n.report_high;
        break;
      case 'medium':
        color = Colors.orange;
        label = l10n.report_medium;
        break;
      case 'low':
        color = Colors.yellow;
        label = l10n.report_low;
        break;
      default:
        color = Colors.grey;
        label = severity;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    String status,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'reported':
        color = Colors.blue;
        icon = Icons.report;
        label = l10n.report_statusReported;
        break;
      case 'in_progress':
        color = Colors.orange;
        icon = Icons.construction;
        label = l10n.report_statusInProgress;
        break;
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        label = l10n.report_statusResolved;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = status;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 1.w),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return Icons.warning;
      case 'crack':
        return Icons.broken_image;
      case 'obstacle':
        return Icons.block;
      case 'lighting':
        return Icons.lightbulb_outline;
      default:
        return Icons.report_problem;
    }
  }
}
