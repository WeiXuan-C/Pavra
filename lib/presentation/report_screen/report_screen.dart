import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart';
import '../camera_detection_screen/camera_detection_screen.dart';
import '../report_submission_screen/report_submission_screen.dart';
import './widgets/report_list_tab.dart';

/// Report Screen
/// 整合相机检测和报告提交功能
/// 包含三个标签页：相机检测、我的报告、所有报告
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCameraExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Camera Section (Collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isCameraExpanded ? 70.h : 30.h,
            child: Stack(
              children: [
                // Camera Detection Screen
                const CameraDetectionScreen(),

                // Expand/Collapse Button
                Positioned(
                  bottom: 2.h,
                  right: 4.w,
                  child: FloatingActionButton.small(
                    heroTag: 'camera_expand',
                    onPressed: () {
                      setState(() {
                        _isCameraExpanded = !_isCameraExpanded;
                      });
                    },
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      _isCameraExpanded ? Icons.expand_more : Icons.expand_less,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: theme.cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.add_circle_outline),
                  text: l10n.report_newReport,
                ),
                Tab(
                  icon: const Icon(Icons.person),
                  text: l10n.report_myReports,
                ),
                Tab(
                  icon: const Icon(Icons.public),
                  text: l10n.report_allReports,
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // New Report (Report Submission)
                const ReportSubmissionScreen(),

                // My Reports
                ReportListTab(
                  filterType: ReportFilterType.myReports,
                  onReportTap: (report) {
                    _navigateToReportDetail(report);
                  },
                ),

                // All Reports
                ReportListTab(
                  filterType: ReportFilterType.allReports,
                  onReportTap: (report) {
                    _navigateToReportDetail(report);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToReportDetail(Map<String, dynamic> report) {
    Navigator.pushNamed(context, '/report-detail', arguments: report);
  }
}
