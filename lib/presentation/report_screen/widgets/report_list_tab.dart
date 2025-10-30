import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../l10n/app_localizations.dart';
import '../../../data/repositories/report_issue_repository.dart';
import '../../../data/sources/remote/report_issue_remote_source.dart';
import '../../../data/sources/remote/issue_type_remote_source.dart';
import '../../../data/sources/remote/issue_vote_remote_source.dart';
import '../../../data/models/report_issue_model.dart';
import './report_skeleton.dart';

enum ReportFilterType { myReports, allReports }

/// Report List Tab
/// 显示报告列表（我的报告或所有报告）
class ReportListTab extends StatefulWidget {
  final ReportFilterType filterType;
  final Function(ReportIssueModel) onReportTap;

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
  List<ReportIssueModel> _reports = [];
  List<ReportIssueModel> _filteredReports = [];
  late ReportIssueRepository _repository;

  // Status filters
  Set<String> _selectedStatuses = {};

  // UI state
  bool _isFilterExpanded = false;
  bool _isSortExpanded = false;

  @override
  void initState() {
    super.initState();
    _initRepository();
    _loadReports();
  }

  void _initRepository() {
    final supabase = Supabase.instance.client;
    _repository = ReportIssueRepository(
      reportRemoteSource: ReportIssueRemoteSource(supabase),
      typeRemoteSource: IssueTypeRemoteSource(),
      voteRemoteSource: IssueVoteRemoteSource(supabase),
    );
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<ReportIssueModel> reports;
      List<String> allowedStatuses;

      if (widget.filterType == ReportFilterType.myReports) {
        // My Reports: show draft, submitted, reviewed, spam
        reports = await _repository.getReportIssues(createdBy: user.id);
        allowedStatuses = ['draft', 'submitted', 'reviewed', 'spam'];

        // Initialize selected statuses for My Reports
        if (_selectedStatuses.isEmpty) {
          _selectedStatuses = {'draft', 'submitted', 'reviewed', 'spam'};
        }
      } else {
        // All Reports: show only submitted, reviewed, spam (exclude draft)
        reports = await _repository.getReportIssues();
        allowedStatuses = ['submitted', 'reviewed', 'spam'];

        // Initialize selected statuses for All Reports
        if (_selectedStatuses.isEmpty) {
          _selectedStatuses = {'submitted', 'reviewed', 'spam'};
        }
      }

      // Filter to only show allowed statuses (exclude discarded)
      final filteredReports = reports
          .where((report) => allowedStatuses.contains(report.status))
          .toList();

      if (mounted) {
        setState(() {
          _reports = filteredReports;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    // Apply status filters
    List<ReportIssueModel> filtered = _reports.where((report) {
      return _selectedStatuses.contains(report.status);
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'date':
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'severity':
        final severityOrder = {
          'critical': 0,
          'high': 1,
          'moderate': 2,
          'low': 3,
          'minor': 4,
        };
        filtered.sort(
          (a, b) => (severityOrder[a.severity] ?? 5).compareTo(
            severityOrder[b.severity] ?? 5,
          ),
        );
        break;
      case 'status':
        final statusOrder = {
          'submitted': 0,
          'reviewed': 1,
          'draft': 2,
          'spam': 3,
        };
        filtered.sort(
          (a, b) => (statusOrder[a.status] ?? 4).compareTo(
            statusOrder[b.status] ?? 4,
          ),
        );
        break;
    }

    setState(() {
      _filteredReports = filtered;
    });
  }

  void _toggleStatusFilter(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        // Don't allow deselecting all statuses
        if (_selectedStatuses.length > 1) {
          _selectedStatuses.remove(status);
        }
      } else {
        _selectedStatuses.add(status);
      }
    });
    _applyFiltersAndSort();
  }

  void _sortReports(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const ReportSkeleton(itemCount: 5);
    }

    return Column(
      children: [
        // Filter & Sort Header (Always Visible)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Filter Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isFilterExpanded = !_isFilterExpanded;
                      if (_isFilterExpanded) _isSortExpanded = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: _isFilterExpanded
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isFilterExpanded
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 18,
                          color: _isFilterExpanded
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          l10n.report_filter,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isFilterExpanded
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Icon(
                          _isFilterExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                          color: _isFilterExpanded
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              // Sort Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isSortExpanded = !_isSortExpanded;
                      if (_isSortExpanded) _isFilterExpanded = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: _isSortExpanded
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isSortExpanded
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sort,
                          size: 18,
                          color: _isSortExpanded
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          l10n.report_sort,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isSortExpanded
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Icon(
                          _isSortExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                          color: _isSortExpanded
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Expandable Filter Section
        if (_isFilterExpanded)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.report_filterByStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: _getAvailableStatuses().map((status) {
                    return _buildStatusFilterChip(status, theme, l10n);
                  }).toList(),
                ),
              ],
            ),
          ),

        // Expandable Sort Section
        if (_isSortExpanded)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.report_sortBy,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: [
                    _buildSortChip(l10n.report_sortDate, 'date', theme),
                    _buildSortChip(l10n.report_sortSeverity, 'severity', theme),
                    _buildSortChip(l10n.report_sortStatus, 'status', theme),
                  ],
                ),
              ],
            ),
          ),

        // Report Count
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${_filteredReports.length} ${l10n.report_reportsFound}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Report List
        Expanded(
          child: _filteredReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.report_off,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        l10n.report_noReports,
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        l10n.report_noReportsMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.separated(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _filteredReports.length,
                    separatorBuilder: (context, index) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return _buildReportCard(report, theme, l10n);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<String> _getAvailableStatuses() {
    if (widget.filterType == ReportFilterType.myReports) {
      return ['draft', 'submitted', 'reviewed', 'spam'];
    } else {
      return ['submitted', 'reviewed', 'spam'];
    }
  }

  Widget _buildStatusFilterChip(
    String status,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isSelected = _selectedStatuses.contains(status);
    final statusColor = _getStatusColorForFilter(status);
    final statusLabel = _getStatusLabel(status, l10n);

    return FilterChip(
      label: Text(
        statusLabel,
        style: TextStyle(
          color: isSelected
              ? statusColor
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => _toggleStatusFilter(status),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: statusColor.withValues(alpha: 0.15),
      checkmarkColor: statusColor,
      side: BorderSide(
        color: isSelected
            ? statusColor
            : theme.colorScheme.outline.withValues(alpha: 0.3),
        width: isSelected ? 1.5 : 1,
      ),
      avatar: isSelected
          ? Icon(_getStatusIcon(status), size: 16, color: statusColor)
          : null,
    );
  }

  Color _getStatusColorForFilter(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'reviewed':
        return Colors.green;
      case 'spam':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'submitted':
        return Icons.send;
      case 'reviewed':
        return Icons.check_circle;
      case 'spam':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'draft':
        return l10n.report_statusDraft;
      case 'submitted':
        return l10n.report_statusSubmitted;
      case 'reviewed':
        return l10n.report_statusReviewed;
      case 'spam':
        return l10n.report_statusSpam;
      default:
        return status;
    }
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
          fontSize: 12,
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
    ReportIssueModel report,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final user = Supabase.instance.client.auth.currentUser;
    final isMyReport = user != null && report.createdBy == user.id;

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
                  _buildSeverityBadge(report.severity, theme, l10n),
                ],
              ),

              SizedBox(height: 1.h),

              // Title and Location
              Row(
                children: [
                  Icon(
                    Icons.report_problem,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title ?? l10n.report_untitled,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (report.address != null)
                          Text(
                            report.address!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              if (report.description != null) ...[
                SizedBox(height: 1.h),
                // Description
                Text(
                  report.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: 1.h),

              // Footer Row
              Row(
                children: [
                  // Status
                  _buildStatusBadge(report.status, theme, l10n),

                  const Spacer(),

                  // Time
                  Text(
                    timeago.format(report.updatedAt, locale: l10n.localeName),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
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
      case 'critical':
        color = Colors.red.shade900;
        label = l10n.report_critical;
        break;
      case 'high':
        color = Colors.red;
        label = l10n.report_high;
        break;
      case 'moderate':
        color = Colors.orange;
        label = l10n.report_moderate;
        break;
      case 'low':
        color = Colors.yellow.shade700;
        label = l10n.report_low;
        break;
      case 'minor':
        color = Colors.grey;
        label = l10n.report_minor;
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
      case 'draft':
        color = Colors.grey;
        icon = Icons.edit;
        label = l10n.report_statusDraft;
        break;
      case 'submitted':
        color = Colors.orange;
        icon = Icons.send;
        label = l10n.report_statusSubmitted;
        break;
      case 'reviewed':
        color = Colors.green;
        icon = Icons.check_circle;
        label = l10n.report_statusReviewed;
        break;
      case 'spam':
        color = Colors.red;
        icon = Icons.block;
        label = l10n.report_statusSpam;
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
}
