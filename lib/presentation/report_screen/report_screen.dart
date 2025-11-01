import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/repositories/report_issue_repository.dart';
import '../../data/sources/remote/report_issue_remote_source.dart';
import '../../data/sources/remote/issue_type_remote_source.dart';
import '../../data/sources/remote/issue_vote_remote_source.dart';
import '../../data/models/report_issue_model.dart';
import '../camera_detection_screen/camera_detection_screen.dart';
import '../layouts/header_layout.dart';
import '../issue_types_screen/issue_types_screen.dart';
import '../report_submission_screen/manual_report_screen.dart';
import '../report_detail_screen/report_detail_screen.dart';
import './widgets/report_list_tab.dart';
import './widgets/report_home_skeleton.dart';

/// 报告屏幕 - 根据 filterType 显示不同内容
/// filterType: 0 = 首页（快速报告）, 1 = 我的报告, 2 = 所有报告
class ReportScreen extends StatefulWidget {
  final int filterType;

  const ReportScreen({super.key, this.filterType = 0});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  bool _isDeveloper = false;
  late ReportIssueRepository _repository;
  List<ReportIssueModel> _recentReports = [];
  int _totalReports = 0;
  int _reviewedReports = 0;
  int _inProgressReports = 0;

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
      _checkUserRole();
      _loadData();
      _isInitialized = true;
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

  Future<void> _checkUserRole() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final profile = authProvider.userProfile;

      if (mounted && profile != null) {
        setState(() {
          _isDeveloper = profile.role == 'developer';
        });
      }
    } catch (e) {
      // Silently fail - user just won't see the button
    }
  }

  @override
  void didUpdateWidget(ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterType != widget.filterType) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user != null && widget.filterType == 0) {
        // Load all reports for current user
        final allReports = await _repository.getReportIssues(
          createdBy: user.id,
        );

        // Filter reports with status: draft, submitted, reviewed, spam
        final filteredReports = allReports.where((report) {
          return [
            'draft',
            'submitted',
            'reviewed',
            'spam',
          ].contains(report.status);
        }).toList();

        // Sort by updated_at descending
        filteredReports.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        // Take only the 3 most recent for preview
        final recentReports = filteredReports.take(3).toList();

        // Calculate stats
        final reviewed = filteredReports
            .where((r) => r.status == 'reviewed')
            .length;
        final inProgress = filteredReports
            .where((r) => r.status == 'submitted')
            .length;

        if (mounted) {
          setState(() {
            _recentReports = recentReports;
            _totalReports = filteredReports.length;
            _reviewedReports = reviewed;
            _inProgressReports = inProgress;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(
        title: _getTitle(l10n),
        centerTitle: false,
        actions: _isDeveloper
            ? [
                IconButton(
                  icon: const Icon(Icons.category),
                  tooltip: l10n.issueTypes_manageTooltip,
                  onPressed: () => _navigateToIssueTypes(context),
                ),
              ]
            : null,
      ),
      body: _buildBody(context, theme, l10n),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (widget.filterType) {
      case 0:
        return l10n.report_title;
      case 1:
        return l10n.report_myReports;
      case 2:
        return l10n.report_allReports;
      default:
        return l10n.report_title;
    }
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    // Show skeleton loading for home tab
    if (_isLoading && widget.filterType == 0) {
      return const ReportHomeSkeleton();
    }

    switch (widget.filterType) {
      case 0:
        return _buildHomeTab(context, theme, l10n);
      case 1:
        return _buildMyReportsTab(context);
      case 2:
        return _buildAllReportsTab(context);
      default:
        return _buildHomeTab(context, theme, l10n);
    }
  }

  Widget _buildHomeTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.report_reportMethods,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            // Report Methods Row - AI (5/9) + Manual (4/9)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Camera Detection - Primary (5/9 width)
                Expanded(
                  flex: 5,
                  child: _buildSimplePrimaryCard(
                    context,
                    theme,
                    icon: Icons.camera_alt,
                    title: l10n.report_aiSmartDetection,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    onTap: () => _openCameraDetection(context),
                  ),
                ),
                SizedBox(width: 3.w),

                // Manual Report - Secondary (4/9 width)
                Expanded(
                  flex: 4,
                  child: _buildCompactActionCard(
                    context,
                    theme,
                    icon: Icons.edit_location_alt,
                    title: l10n.report_manualReport,
                    color: theme.colorScheme.secondary,
                    onTap: () => _navigateToManualReport(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            _buildStatsSection(theme, l10n),
            SizedBox(height: 4.h),
            _buildRecentReportsPreview(context, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePrimaryCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140, // Fixed height to match compact card
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            SizedBox(height: 1.5.h),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140, // Fixed height to match primary card
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(height: 1.5.h),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Icon(Icons.arrow_forward, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.report_myContribution,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.report_outlined,
                value: _totalReports.toString(),
                label: l10n.report_totalReports,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.check_circle_outline,
                value: _reviewedReports.toString(),
                label: l10n.report_reviewed,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.pending_outlined,
                value: _inProgressReports.toString(),
                label: l10n.report_inProgress,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsPreview(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.report_recentReports,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to My Reports screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportScreen(filterType: 1),
                  ),
                );
              },
              child: Text(l10n.report_viewAll),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (_recentReports.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                children: [
                  Icon(
                    Icons.report_off,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    l10n.report_noReports,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentReports.map((report) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: _buildReportPreviewCard(
                context,
                theme,
                l10n,
                report: report,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildReportPreviewCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n, {
    required ReportIssueModel report,
  }) {
    final statusColor = _getStatusColor(report.status);
    final statusLabel = _getStatusLabel(report.status, l10n);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: report),
          ),
        ).then((result) {
          if (result == true) {
            _loadData();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.report_problem, color: statusColor),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title ?? l10n.report_untitled,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    report.address ?? l10n.report_noLocation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  timeago.format(report.updatedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  Widget _buildMyReportsTab(BuildContext context) {
    return ReportListTab(
      filterType: ReportFilterType.myReports,
      onReportTap: (report) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: report),
          ),
        ).then((result) {
          if (result == true) {
            _loadData();
          }
        });
      },
    );
  }

  Widget _buildAllReportsTab(BuildContext context) {
    return ReportListTab(
      filterType: ReportFilterType.allReports,
      onReportTap: (report) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: report),
          ),
        ).then((result) {
          if (result == true) {
            _loadData();
          }
        });
      },
    );
  }

  void _openCameraDetection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const CameraDetectionScreen(),
      ),
    );
  }

  void _navigateToManualReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualReportScreen()),
    );
  }

  void _navigateToIssueTypes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IssueTypesScreen()),
    );
  }
}
