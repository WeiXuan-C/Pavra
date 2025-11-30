import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';
import '../../data/models/report_issue_model.dart';
import '../../core/supabase/supabase_client.dart';
import 'widgets/analytics_skeleton.dart';
import '../layouts/header_layout.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  static const String routeName = '/analytics';

  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ReportIssueModel> _reports = [];
  List<Map<String, dynamic>> _users = [];
  Map<String, int> _severityStats = {};
  Map<String, int> _statusStats = {};
  Map<String, int> _issueTypeStats = {};
  Map<String, Map<String, dynamic>> _issueTypeDetails = {};
  int _touchedIndex = -1;
  int _selectedDays = 7;
  String _selectedStatusFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      // Load reports with user info
      final reportsData = await supabase
          .from('report_issues')
          .select('*, profiles!report_issues_created_by_fkey(username)')
          .inFilter('status', ['draft', 'submitted'])
          .order('created_at', ascending: false);
      
      // Load users
      final usersData = await supabase
          .from('profiles')
          .select()
          .order('updated_at', ascending: false);
      
      final reports = (reportsData as List).map((e) => ReportIssueModel.fromJson(e)).toList();
      _calculateStats(reports, reportsData);
      
      setState(() {
        _reports = reports;
        _users = List<Map<String, dynamic>>.from(usersData as List);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats(List<ReportIssueModel> reports, List<dynamic> reportsData) {
    _severityStats = {};
    _statusStats = {};
    _issueTypeStats = {};
    _issueTypeDetails = {};

    for (var i = 0; i < reports.length; i++) {
      final report = reports[i];
      final reportData = reportsData[i];
      
      _severityStats[report.severity] = (_severityStats[report.severity] ?? 0) + 1;
      _statusStats[report.status] = (_statusStats[report.status] ?? 0) + 1;
      
      final username = reportData['profiles']?['username'] ?? 'Unknown';
      
      for (var typeId in report.issueTypeIds) {
        _issueTypeStats[typeId] = (_issueTypeStats[typeId] ?? 0) + 1;
        
        if (!_issueTypeDetails.containsKey(typeId)) {
          _issueTypeDetails[typeId] = {
            'users': <String>{},
            'count': 0,
          };
        }
        _issueTypeDetails[typeId]!['users'].add(username);
        _issueTypeDetails[typeId]!['count'] = (_issueTypeDetails[typeId]!['count'] as int) + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(
        title: 'Admin Analytics',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const AnalyticsSkeleton()
          : Column(
              children: [
                Container(
                  color: theme.colorScheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    indicatorColor: theme.colorScheme.primary,
                    tabs: [
                      Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                      Tab(icon: Icon(Icons.report), text: 'Reports (${_reports.length})'),
                      Tab(icon: Icon(Icons.people), text: 'Users (${_users.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildReportsTab(),
                      _buildUsersTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics Grid
            _buildKeyMetricsGrid(theme, isDark),
            SizedBox(height: 3.h),
            
            // Charts Section
            _buildSeverityDoughnutChart(theme, isDark),
            SizedBox(height: 3.h),
            _buildSeverityBarChart(theme, isDark),
            SizedBox(height: 3.h),
            _buildIssueTypesChart(theme, isDark),
            SizedBox(height: 3.h),
            _buildTrendChart(theme, isDark),
            SizedBox(height: 3.h),
            _buildStatusBreakdown(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsGrid(ThemeData theme, bool isDark) {
    final totalReports = _reports.length;
    final totalUsers = _users.length;
    final criticalReports = _reports.where((r) => r.severity == 'critical').length;
    final todayReports = _reports.where((r) {
      final today = DateTime.now();
      return r.createdAt.year == today.year &&
             r.createdAt.month == today.month &&
             r.createdAt.day == today.day;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: theme.colorScheme.primary, size: 28),
            SizedBox(width: 2.w),
            Text(
              'Key Metrics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3.w,
          crossAxisSpacing: 3.w,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard('Total Reports', totalReports.toString(), Icons.assessment, theme.colorScheme.primary, isDark),
            _buildMetricCard('Total Users', totalUsers.toString(), Icons.people, Colors.blue, isDark),
            _buildMetricCard('Critical Issues', criticalReports.toString(), Icons.warning_amber_rounded, Colors.red[700]!, isDark),
            _buildMetricCard('Today\'s Reports', todayReports.toString(), Icons.today, Colors.green, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityDoughnutChart(ThemeData theme, bool isDark) {
    if (_severityStats.isEmpty) return const SizedBox();

    final total = _severityStats.values.fold(0, (sum, val) => sum + val);
    final sortedEntries = _severityStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(Icons.pie_chart, color: theme.colorScheme.primary, size: 24),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports by Severity',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Distribution of issue severity levels',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: sortedEntries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final isTouched = index == _touchedIndex;
                        final radius = isTouched ? 65.0 : 60.0;
                        final percentage = (data.value / total * 100).toStringAsFixed(1);

                        return PieChartSectionData(
                          value: data.value.toDouble(),
                          title: isTouched ? '$percentage%' : '',
                          color: _getSeverityColor(data.key),
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: sortedEntries.map((entry) {
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.5.h),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getSeverityColor(entry.key),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key.toUpperCase(),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${entry.value} ($percentage%)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBarChart(ThemeData theme, bool isDark) {
    if (_severityStats.isEmpty) return const SizedBox();

    final severityOrder = ['critical', 'high', 'moderate', 'low'];
    final orderedEntries = severityOrder
        .where((key) => _severityStats.containsKey(key))
        .map((key) => MapEntry(key, _severityStats[key]!))
        .toList();

    final maxValue = orderedEntries.isEmpty 
        ? 1.0 
        : orderedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(Icons.bar_chart, color: theme.colorScheme.primary, size: 24),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Severity Breakdown',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Detailed count by severity level',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final severity = orderedEntries[group.x.toInt()].key;
                      return BarTooltipItem(
                        '${severity.toUpperCase()}\n${rod.toY.toInt()} reports',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < orderedEntries.length) {
                          final severity = orderedEntries[value.toInt()].key;
                          return Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              severity.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getSeverityColor(severity),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 10 ? maxValue / 5 : 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: orderedEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: _getSeverityColor(entry.value.key),
                        width: 40,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxValue * 1.2,
                          color: isDark
                              ? Colors.grey[800]!.withValues(alpha: 0.3)
                              : Colors.grey[200]!,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueTypesChart(ThemeData theme, bool isDark) {
    if (_issueTypeStats.isEmpty) return const SizedBox();

    final sortedEntries = _issueTypeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sortedEntries.first.value.toDouble();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(Icons.category, color: theme.colorScheme.primary, size: 24),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports by Issue Type',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Most common types of issues with reporters',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...sortedEntries.take(10).map((entry) {
            final percentage = (entry.value / maxValue);
            final details = _issueTypeDetails[entry.key];
            final users = details?['users'] as Set<String>? ?? {};
            final userList = users.take(3).toList();
            final moreUsers = users.length > 3 ? users.length - 3 : 0;
            
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (userList.isNotEmpty) ...[
                    SizedBox(height: 0.3.h),
                    Text(
                      'Reported by: ${userList.join(", ")}${moreUsers > 0 ? " +$moreUsers more" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 0.5.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrendChart(ThemeData theme, bool isDark) {
    if (_reports.isEmpty) return const SizedBox();
    
    final now = DateTime.now();
    final days = List.generate(_selectedDays, (i) => now.subtract(Duration(days: _selectedDays - 1 - i)));
    final dailyCounts = <DateTime, int>{};

    for (var date in days) {
      final dateKey = DateTime(date.year, date.month, date.day);
      dailyCounts[dateKey] = 0;
    }

    for (var report in _reports) {
      final reportDate = DateTime(
        report.createdAt.year,
        report.createdAt.month,
        report.createdAt.day,
      );
      if (dailyCounts.containsKey(reportDate)) {
        dailyCounts[reportDate] = dailyCounts[reportDate]! + 1;
      }
    }

    final spots = dailyCounts.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 24),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports Trend',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Activity over time',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimeRangeChip('7 Days', 7),
                SizedBox(width: 2.w),
                _buildTimeRangeChip('14 Days', 14),
                SizedBox(width: 2.w),
                _buildTimeRangeChip('30 Days', 30),
                SizedBox(width: 2.w),
                _buildTimeRangeChip('90 Days', 90),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          final date = days[value.toInt()];
                          final interval = _selectedDays > 30 ? 15 : _selectedDays > 14 ? 7 : _selectedDays > 7 ? 3 : 1;
                          if (value.toInt() % interval == 0 || value.toInt() == days.length - 1) {
                            return Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                '${date.month}/${date.day}',
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, int days) {
    final isSelected = _selectedDays == days;
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDays = days;
        });
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildStatusBreakdown(ThemeData theme, bool isDark) {
    if (_statusStats.isEmpty) return const SizedBox();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 24),
              ),
              SizedBox(width: 3.w),
              Text(
                'Status Breakdown',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ..._statusStats.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(entry.key),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    final theme = Theme.of(context);
    
    final filteredReports = _selectedStatusFilter == 'all'
        ? _reports
        : _reports.where((r) => r.status == _selectedStatusFilter).toList();
    
    final searchedReports = _searchQuery.isEmpty
        ? filteredReports
        : filteredReports.where((r) {
            final title = r.title?.toLowerCase() ?? '';
            final description = r.description?.toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return title.contains(query) || description.contains(query);
          }).toList();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search reports...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(2.w)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              SizedBox(height: 1.5.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', _reports.length),
                    SizedBox(width: 2.w),
                    _buildFilterChip('Draft', 'draft', 
                      _reports.where((r) => r.status == 'draft').length),
                    SizedBox(width: 2.w),
                    _buildFilterChip('Submitted', 'submitted',
                      _reports.where((r) => r.status == 'submitted').length),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: searchedReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 2.h),
                      Text(
                        _searchQuery.isNotEmpty ? 'No reports found' : 'No reports yet',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        SizedBox(height: 1.h),
                        Text('Try a different search term', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView.builder(
                    padding: EdgeInsets.all(3.w),
                    itemCount: searchedReports.length,
                    itemBuilder: (context, index) {
                      final report = searchedReports[index];
                      return _buildReportCard(report, theme);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedStatusFilter == value;
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = value;
        });
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildReportCard(ReportIssueModel report, ThemeData theme) {
    final statusColor = _getStatusColor(report.status);
    final severityColor = _getSeverityColor(report.severity);
    
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(3.w),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title ?? 'Untitled Report',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 2.w),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteReport(report.id);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              if (report.description != null && report.description!.isNotEmpty)
                Text(
                  report.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 1.5.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: [
                  _buildBadge(report.status.toUpperCase(), statusColor, Icons.info_outline),
                  _buildBadge(report.severity.toUpperCase(), severityColor, Icons.warning_amber_rounded),
                ],
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      report.createdBy ?? 'Unknown',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(1.w),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final theme = Theme.of(context);
    
    return _users.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                SizedBox(height: 2.h),
                Text(
                  'No users found',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadAnalytics,
            child: ListView.builder(
              padding: EdgeInsets.all(3.w),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isAdmin = user['role'] == 'admin';
                
                return Card(
                  margin: EdgeInsets.only(bottom: 2.h),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(3.w),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: isAdmin ? theme.colorScheme.primary : Colors.grey[400],
                      child: Text(
                        (user['username'] as String?)?.isNotEmpty == true 
                            ? (user['username'] as String)[0].toUpperCase() 
                            : 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['username'] ?? 'Unknown User',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(1.w),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.admin_panel_settings, size: 14, color: theme.colorScheme.primary),
                                SizedBox(width: 1.w),
                                Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 0.5.h),
                        Text(user['email'] ?? 'No email', style: TextStyle(fontSize: 12)),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Last updated: ${_formatDate(DateTime.parse(user['updated_at']))}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => _showUserDetails(user),
                  ),
                );
              },
            ),
          );
  }

  void _showReportDetails(ReportIssueModel report) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h, bottom: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Report Details',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title ?? 'Untitled',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2.h),
                    if (report.description != null) ...[
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 1.h),
                      Text(report.description!),
                      SizedBox(height: 2.h),
                    ],
                    Text(
                      'Details',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    _buildDetailRow('Status', report.status.toUpperCase()),
                    _buildDetailRow('Severity', report.severity.toUpperCase()),
                    _buildDetailRow('Created By', report.createdBy ?? 'Unknown'),
                    _buildDetailRow('Created', _formatDate(report.createdAt)),
                    if (report.latitude != null && report.longitude != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Location',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 1.h),
                      _buildDetailRow('Latitude', report.latitude.toString()),
                      _buildDetailRow('Longitude', report.longitude.toString()),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, size: 18),
                label: Text('Close'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Username', user['username'] ?? 'Unknown'),
            _buildDetailRow('Email', user['email'] ?? 'No email'),
            _buildDetailRow('Role', user['role'] ?? 'user'),
            _buildDetailRow('Created', _formatDate(DateTime.parse(user['created_at']))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Report'),
        content: Text('Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('report_issues').delete().eq('id', reportId);
        await _loadAnalytics();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'moderate':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue[700]!;
      case 'minor':
        return Colors.grey[700]!;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'reviewed':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'spam':
        return Colors.red;
      case 'discard':
        return Colors.grey;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
