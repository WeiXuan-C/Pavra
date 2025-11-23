import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/report_issue_model.dart';
import '../../core/supabase/supabase_client.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final reportsData = await supabase
          .from('report_issues')
          .select()
          .order('created_at', ascending: false);
      
      final reports = (reportsData as List).map((e) => ReportIssueModel.fromJson(e)).toList();
      _calculateStats(reports);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats(List<ReportIssueModel> reports) {
    _severityStats = {};
    _statusStats = {};
    _issueTypeStats = {};

    for (var report in reports) {
      _severityStats[report.severity] = (_severityStats[report.severity] ?? 0) + 1;
      _statusStats[report.status] = (_statusStats[report.status] ?? 0) + 1;
      
      // Count issue types from issueTypeIds list
      for (var typeId in report.issueTypeIds) {
        _issueTypeStats[typeId] = (_issueTypeStats[typeId] ?? 0) + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(theme),
                    const SizedBox(height: 24),
                    _buildSeverityChart(theme),
                    const SizedBox(height: 24),
                    _buildStatusChart(theme),
                    const SizedBox(height: 24),
                    _buildIssueTypesChart(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Reports',
            _reports.length.toString(),
            Icons.report,
            theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Resolved',
            _statusStats['resolved']?.toString() ?? '0',
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityChart(ThemeData theme) {
    if (_severityStats.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports by Severity', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _severityStats.entries.map((e) {
                    return PieChartSectionData(
                      value: e.value.toDouble(),
                      title: '${e.key}\n${e.value}',
                      color: _getSeverityColor(e.key),
                      radius: 80,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(ThemeData theme) {
    if (_statusStats.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports by Status', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _statusStats.entries.toList().asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTypesChart(ThemeData theme) {
    if (_issueTypeStats.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports by Issue Type', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ..._issueTypeStats.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(e.key)),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
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
