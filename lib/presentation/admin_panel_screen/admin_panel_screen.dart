import 'package:flutter/material.dart';
import '../../data/models/report_issue_model.dart';
import '../../core/supabase/supabase_client.dart';

class AdminPanelScreen extends StatefulWidget {
  static const String routeName = '/admin';

  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ReportIssueModel> _reports = [];
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reportsData = await supabase
          .from('report_issues')
          .select()
          .order('created_at', ascending: false);
      
      final usersData = await supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        _reports = (reportsData as List).map((e) => ReportIssueModel.fromJson(e)).toList();
        _users = List<Map<String, dynamic>>.from(usersData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Reports'),
              Tab(text: 'Users'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
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
    final totalReports = _reports.length;
    final totalUsers = _users.length;
    final pendingReports = _reports.where((r) => r.status == 'submitted').length;
    final resolvedReports = _reports.where((r) => r.status == 'resolved').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('Total Reports', totalReports.toString(), Icons.report),
          _buildStatCard('Total Users', totalUsers.toString(), Icons.people),
          _buildStatCard('Pending Reports', pendingReports.toString(), Icons.pending),
          _buildStatCard('Resolved Reports', resolvedReports.toString(), Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(report.title ?? 'Untitled'),
              subtitle: Text('${report.status} • ${report.severity}'),
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'reviewed',
                    child: Text('Approve'),
                  ),
                  PopupMenuItem(
                    value: 'spam',
                    child: Text('Reject'),
                  ),
                  PopupMenuItem(
                    value: 'resolved',
                    child: Text('Resolve'),
                  ),
                ],
                onSelected: (value) => _updateReportStatus(report.id, value),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text((user['username'] as String?)?.isNotEmpty == true 
                    ? (user['username'] as String)[0].toUpperCase() 
                    : 'U'),
              ),
              title: Text(user['username'] ?? 'Unknown'),
              subtitle: Text(user['email'] ?? ''),
              trailing: Text(user['role'] ?? 'user'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    try {
      await supabase
          .from('report_issues')
          .update({'status': status})
          .eq('id', reportId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }
}
