import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart';
import '../camera_detection_screen/camera_detection_screen.dart';
import '../layouts/header_layout.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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

    // Simulate loading data
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(title: _getTitle(l10n), centerTitle: false),
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
    return SingleChildScrollView(
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

          // Report Methods Row - AI (2/3) + Manual (1/3)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Camera Detection - Primary (2/3 width)
              Expanded(
                flex: 2,
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

              // Manual Report - Secondary (1/3 width)
              Expanded(
                flex: 1,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Icon(Icons.arrow_forward, color: Colors.white, size: 24),
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
        height: 180, // Match the height of primary card
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Icon(Icons.arrow_forward, color: color, size: 20),
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
                value: '12',
                label: l10n.report_totalReports,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.check_circle_outline,
                value: '8',
                label: l10n.report_resolved,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.pending_outlined,
                value: '4',
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
                // This will be handled by the parent layout
                // User can tap the Report nav button again to see the menu
              },
              child: Text(l10n.report_viewAll),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildReportPreviewCard(
          theme,
          title: '道路坑洞',
          location: 'Main Street & 5th Ave',
          status: '处理中',
          statusColor: Colors.orange,
          time: '2小时前',
        ),
        SizedBox(height: 2.h),
        _buildReportPreviewCard(
          theme,
          title: '路面裂缝',
          location: 'Highway 101, Mile 23',
          status: '已解决',
          statusColor: Colors.green,
          time: '1天前',
        ),
      ],
    );
  }

  Widget _buildReportPreviewCard(
    ThemeData theme, {
    required String title,
    required String location,
    required String status,
    required Color statusColor,
    required String time,
  }) {
    return Container(
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
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  location,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyReportsTab(BuildContext context) {
    return ReportListTab(
      filterType: ReportFilterType.myReports,
      onReportTap: (report) {
        Navigator.pushNamed(context, '/report-detail', arguments: report);
      },
    );
  }

  Widget _buildAllReportsTab(BuildContext context) {
    return ReportListTab(
      filterType: ReportFilterType.allReports,
      onReportTap: (report) {
        Navigator.pushNamed(context, '/report-detail', arguments: report);
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
    Navigator.pushNamed(context, '/report-submission-screen');
  }
}
