import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/location_utils.dart';
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
  final Function(int)? onCountChanged; // 数量变化回调

  const ReportListTab({
    super.key,
    required this.filterType,
    required this.onReportTap,
    this.onCountChanged,
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
  bool _isGridView = false; // false = list view, true = grid view

  // Location state for proximity check
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    // Initialize in didChangeDependencies where we have context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initRepository(context);
      _loadReports();
      _getCurrentLocation();
      _isInitialized = true;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {}); // Trigger rebuild with new location
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  bool _isReportNearby(ReportIssueModel report) {
    if (_currentPosition == null ||
        report.latitude == null ||
        report.longitude == null) {
      return false;
    }

    return LocationUtils.isWithinRadius(
      userLat: _currentPosition!.latitude,
      userLon: _currentPosition!.longitude,
      targetLat: report.latitude!,
      targetLon: report.longitude!,
      radiusMiles: 5.0, // 5 miles radius
    );
  }

  @override
  void didUpdateWidget(ReportListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 filterType 改变时重新加载数据
    if (oldWidget.filterType != widget.filterType) {
      _loadReports();
    }
  }

  bool _isInitialized = false;

  void _initRepository(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final supabase = authProvider.supabaseClient;
    _repository = ReportIssueRepository(
      reportRemoteSource: ReportIssueRemoteSource(supabase),
      typeRemoteSource: IssueTypeRemoteSource(supabase),
      voteRemoteSource: IssueVoteRemoteSource(supabase),
    );
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<ReportIssueModel> reports;
      List<String> allowedStatuses;

      if (widget.filterType == ReportFilterType.myReports) {
        // My Reports: show draft, submitted (exclude discard)
        reports = await _repository.getReportIssues(createdBy: user.id);
        allowedStatuses = ['draft', 'submitted'];

        // Initialize selected statuses for My Reports
        if (_selectedStatuses.isEmpty) {
          _selectedStatuses = {'draft', 'submitted'};
        }
      } else {
        // All Reports: show only submitted (exclude draft and discard)
        reports = await _repository.getReportIssues();
        allowedStatuses = ['submitted'];

        // Initialize selected statuses for All Reports
        if (_selectedStatuses.isEmpty) {
          _selectedStatuses = {'submitted'};
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
    
    // 通知父组件数量变化
    widget.onCountChanged?.call(filtered.length);
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
        // Modern 工具栏 - 响应式设计
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              // 筛选芯片 - 横向滚动
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 排序芯片
                      _buildModernChip(
                        label: _sortBy == 'date' ? l10n.report_sortLatest : l10n.report_sortPriority,
                        icon: Icons.swap_vert,
                        isSelected: true,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 3.h),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 拖动条
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  _buildBottomSheetOption(
                                    context,
                                    l10n.report_sortLatestFirst,
                                    Icons.access_time,
                                    _sortBy == 'date',
                                    () {
                                      _sortReports('date');
                                      Navigator.pop(context);
                                    },
                                    theme,
                                  ),
                                  _buildBottomSheetOption(
                                    context,
                                    l10n.report_sortByPriority,
                                    Icons.priority_high,
                                    _sortBy == 'severity',
                                    () {
                                      _sortReports('severity');
                                      Navigator.pop(context);
                                    },
                                    theme,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        theme: theme,
                      ),
                      
                      // 状态筛选 (仅 My Reports)
                      if (widget.filterType == ReportFilterType.myReports) ...[
                        SizedBox(width: 2.w),
                        _buildModernChip(
                          label: l10n.report_filterDraft,
                          icon: Icons.edit_outlined,
                          isSelected: _selectedStatuses.contains('draft'),
                          color: Colors.orange,
                          onTap: () => _toggleStatusFilter('draft'),
                          theme: theme,
                        ),
                        SizedBox(width: 2.w),
                        _buildModernChip(
                          label: l10n.report_filterSubmitted,
                          icon: Icons.send_outlined,
                          isSelected: _selectedStatuses.contains('submitted'),
                          color: Colors.green,
                          onTap: () => _toggleStatusFilter('submitted'),
                          theme: theme,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: 2.w),
              
              // 搜索按钮 (仅 All Reports)
              if (widget.filterType == ReportFilterType.allReports)
                IconButton(
                  icon: Icon(Icons.search, size: 24),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: ReportSearchDelegate(_filteredReports, widget.onReportTap),
                    );
                  },
                  tooltip: l10n.report_search,
                ),
              
              // 视图切换 - 单个按钮
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                tooltip: _isGridView ? l10n.report_viewList : l10n.report_viewGrid,
              ),
            ],
          ),
        ),
        
        // 分隔线
        Divider(height: 1, thickness: 1),



        // Report List or Grid
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
                  child: _isGridView
                      ? GridView.builder(
                          padding: EdgeInsets.all(4.w),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 3.w,
                            mainAxisSpacing: 2.h,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filteredReports.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _filteredReports.length) {
                              return _buildEndMessage(theme, l10n);
                            }
                            final report = _filteredReports[index];
                            return _buildReportGridCard(report, theme, l10n);
                          },
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _filteredReports.length + 1,
                          separatorBuilder: (context, index) => SizedBox(height: 2.h),
                          itemBuilder: (context, index) {
                            if (index == _filteredReports.length) {
                              return _buildEndMessage(theme, l10n);
                            }
                            final report = _filteredReports[index];
                            return _buildReportCard(report, theme, l10n);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  // Modern 芯片设计 - 类似 Instagram/Twitter
  Widget _buildModernChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? color,
  }) {
    final chipColor = color ?? theme.colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isSelected 
                ? chipColor 
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected 
                    ? Colors.white 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              SizedBox(width: 2.w),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected 
                      ? Colors.white 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern 底部表单选项
  Widget _buildBottomSheetOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // 列表底部提示信息
  Widget _buildEndMessage(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Text(
            _filteredReports.isEmpty 
                ? l10n.report_noReports 
                : l10n.report_reachedEnd,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_filteredReports.isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            Text(
              l10n.report_noMoreReports,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildReportCard(
    ReportIssueModel report,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isMyReport = user != null && report.createdBy == user.id;

    // Get status color for left border (matching My Contribution stats colors)
    Color statusBorderColor;
    switch (report.status) {
      case 'draft':
        statusBorderColor = Colors.orange; // Orange for draft
        break;
      case 'submitted':
        statusBorderColor = Colors.green; // Green for submitted
        break;
      case 'discard':
        statusBorderColor = Colors.red.shade600;
        break;
      default:
        statusBorderColor = Colors.grey.shade600;
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => widget.onReportTap(report),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: statusBorderColor,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部信息行 - 更简洁
              Row(
                children: [
                  // 严重程度标签
                  _buildCompactSeverityBadge(report.severity, theme, l10n),
                  
                  SizedBox(width: 2.w),
                  
                  // 我的报告标记
                  if (isMyReport)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: theme.colorScheme.secondary,
                      ),
                    ),

                  const Spacer(),

                  // 时间
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    timeago.format(report.createdAt, locale: l10n.localeName),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              // 投票信息 - 仅显示附近的报告
              if (report.status == 'submitted' && _isReportNearby(report)) ...[
                SizedBox(height: 1.h),
                Row(
                  children: [
                    // 验证票数
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.thumb_up, size: 18, color: Colors.green.shade700),
                            SizedBox(width: 1.5.w),
                            Text(
                              '${report.verifiedVotes}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 2.w),
                    
                    // 垃圾票数
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.thumb_down, size: 18, color: Colors.red.shade700),
                            SizedBox(width: 1.5.w),
                            Text(
                              '${report.spamVotes}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 2.w),
                    
                    // 结果图标
                    Container(
                      padding: EdgeInsets.all(1.5.w),
                      decoration: BoxDecoration(
                        color: report.verifiedVotes > report.spamVotes
                            ? Colors.green.withValues(alpha: 0.15)
                            : report.spamVotes > report.verifiedVotes
                                ? Colors.red.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        report.verifiedVotes > report.spamVotes
                            ? Icons.verified
                            : report.spamVotes > report.verifiedVotes
                                ? Icons.report
                                : Icons.balance,
                        size: 20,
                        color: report.verifiedVotes > report.spamVotes
                            ? Colors.green.shade700
                            : report.spamVotes > report.verifiedVotes
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
              ] else if (report.status == 'submitted' && !_isReportNearby(report)) ...[
                // 显示距离提示（不在附近）- Enhanced design
                SizedBox(height: 1.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_off,
                          size: 18,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      SizedBox(width: 2.5.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).report_notInYourArea,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 0.3.h),
                            Text(
                              'Must be within 5 miles to vote',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),
              ],

              // Title and Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  // 简洁版严重程度标签
  Widget _buildCompactSeverityBadge(
    String severity,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    Color color;
    IconData icon;

    switch (severity) {
      case 'critical':
        color = Colors.red.shade900;
        icon = Icons.warning;
        break;
      case 'high':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'moderate':
        color = Colors.orange;
        icon = Icons.report_problem;
        break;
      case 'low':
        color = Colors.yellow.shade700;
        icon = Icons.info;
        break;
      case 'minor':
        color = Colors.grey;
        icon = Icons.circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle;
    }

    return Container(
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  // 增强的网格卡片 - 更美观实用
  Widget _buildReportGridCard(
    ReportIssueModel report,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isMyReport = user != null && report.createdBy == user.id;

    // 状态颜色
    Color statusColor;
    switch (report.status) {
      case 'draft':
        statusColor = Colors.orange;
        break;
      case 'submitted':
        statusColor = Colors.green;
        break;
      case 'discard':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => widget.onReportTap(report),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部状态条
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顶部行：严重程度 + 我的标记
                      Row(
                        children: [
                          _buildCompactSeverityBadge(report.severity, theme, l10n),
                          const Spacer(),
                          if (isMyReport)
                            Container(
                              padding: EdgeInsets.all(1.w),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 2.h),

                      // 标题
                      Text(
                        report.title ?? l10n.report_untitled,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 1.h),

                      // 位置
                      if (report.address != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.colorScheme.primary.withValues(alpha: 0.7),
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                report.address!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      const Spacer(),

                      // 投票信息 (submitted reports - only if nearby)
                      if (report.status == 'submitted' && _isReportNearby(report)) ...[
                        Divider(height: 2.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Verify
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.thumb_up, size: 14, color: Colors.green),
                                SizedBox(width: 1.w),
                                Text(
                                  '${report.verifiedVotes}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Divider
                            Container(
                              width: 1,
                              height: 16,
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            // Spam
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.thumb_down, size: 14, color: Colors.red),
                                SizedBox(width: 1.w),
                                Text(
                                  '${report.spamVotes}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ] else if (report.status == 'submitted' && !_isReportNearby(report)) ...[
                        // Not nearby indicator - Enhanced for grid view
                        Divider(height: 2.h),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 0.8.h, horizontal: 2.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 14, color: Colors.orange.shade700),
                              SizedBox(width: 1.5.w),
                              Flexible(
                                child: Text(
                                  'Not nearby',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade800,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // 时间 (draft reports)
                        Text(
                          timeago.format(report.createdAt, locale: l10n.localeName),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// 搜索委托
class ReportSearchDelegate extends SearchDelegate<ReportIssueModel?> {
  final List<ReportIssueModel> reports;
  final Function(ReportIssueModel) onReportTap;

  ReportSearchDelegate(this.reports, this.onReportTap);

  @override
  String get searchFieldLabel {
    // Access l10n through context - we'll override buildResults to get it
    return 'Search reports...'; // Fallback, will be replaced in UI
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.report_searchByTitleLocation,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final results = reports.where((report) {
      final searchLower = query.toLowerCase();
      final titleMatch = report.title?.toLowerCase().contains(searchLower) ?? false;
      final addressMatch = report.address?.toLowerCase().contains(searchLower) ?? false;
      final descMatch = report.description?.toLowerCase().contains(searchLower) ?? false;
      return titleMatch || addressMatch || descMatch;
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.report_noResultsFound,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 1.h),
            Text(
              l10n.report_tryDifferentKeywords,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: results.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final report = results[index];
        return Card(
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.article,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              report.title ?? l10n.common_untitled,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: report.address != null
                ? Text(
                    report.address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              close(context, report);
              onReportTap(report);
            },
          ),
        );
      },
    );
  }
}
