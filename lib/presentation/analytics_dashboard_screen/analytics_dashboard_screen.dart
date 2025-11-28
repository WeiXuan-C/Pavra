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

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  List<ReportIssueModel> _reports = [];
  Map<String, int> _severityStats = {};
  Map<String, int> _statusStats = {};
  Map<String, int> _issueTypeStats = {};
  Map<String, Map<String, dynamic>> _issueTypeDetails = {}; // Store issue type with user info
  int _touchedIndex = -1;
  
  // Time range filter: 7, 14, 30, 90 days
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      // Only load reports with status 'draft' or 'submitted'
      final reportsData = await supabase
          .from('report_issues')
          .select('*, profiles!report_issues_created_by_fkey(username)')
          .inFilter('status', ['draft', 'submitted'])
          .order('created_at', ascending: false);
      
      final reports = (reportsData as List).map((e) => ReportIssueModel.fromJson(e)).toList();
      _calculateStats(reports, reportsData);
      setState(() {
        _reports = reports;
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
      
      // Get username from joined profiles table
      final username = reportData['profiles']?['username'] ?? 'Unknown';
      
      // Count issue types from issueTypeIds list with user info
      for (var typeId in report.issueTypeIds) {
        _issueTypeStats[typeId] = (_issueTypeStats[typeId] ?? 0) + 1;
        
        // Store user info for this issue type
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
        title: 'Analytics Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const AnalyticsSkeleton()
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(theme),
                    SizedBox(height: 3.h),
                    _buildSeverityDoughnutChart(theme),
                    SizedBox(height: 3.h),
                    _buildSeverityBarChart(theme),
                    SizedBox(height: 3.h),
                    _buildIssueTypesChart(theme),
                    SizedBox(height: 3.h),
                    _buildTrendChart(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surface,
                ]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  theme.colorScheme.surface,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
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
                child: Icon(
                  Icons.dashboard,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                'Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Center(
            child: _buildStatCard(
              'Total Reports',
              _reports.length.toString(),
              Icons.assessment,
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                  : Colors.grey[600],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityDoughnutChart(ThemeData theme) {
    if (_severityStats.isEmpty) return const SizedBox();

    final isDark = theme.brightness == Brightness.dark;
    final total = _severityStats.values.fold(0, (sum, val) => sum + val);
    final sortedEntries = _severityStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
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
                child: Icon(
                  Icons.pie_chart,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports by Severity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
              // Doughnut Chart
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
              // Legend
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: sortedEntries.map((entry) {
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                    final theme = Theme.of(context);
                    final isDark = theme.brightness == Brightness.dark;
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
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${entry.value} ($percentage%)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
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

  Widget _buildSeverityBarChart(ThemeData theme) {
    if (_severityStats.isEmpty) return const SizedBox();

    final isDark = theme.brightness == Brightness.dark;
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
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
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
                child: Icon(
                  Icons.bar_chart,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Severity Breakdown',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                      color: isDark 
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
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

  Widget _buildIssueTypesChart(ThemeData theme) {
    if (_issueTypeStats.isEmpty) return const SizedBox();

    final isDark = theme.brightness == Brightness.dark;
    final sortedEntries = _issueTypeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sortedEntries.first.value.toDouble();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
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
                child: Icon(
                  Icons.category,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports by Issue Type',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
          ...sortedEntries.map((entry) {
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
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

  Widget _buildTrendChart(ThemeData theme) {
    if (_reports.isEmpty) return const SizedBox();

    final isDark = theme.brightness == Brightness.dark;
    
    // Group reports by date based on selected time range
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
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
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
                child: Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports Trend',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
          // Time range selector
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
                        color: Colors.grey[300],
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
                            // Show fewer labels for longer time ranges
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'moderate': return Colors.yellow;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
