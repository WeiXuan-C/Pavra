import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../data/models/report_issue_model.dart';
import '../../core/supabase/supabase_client.dart';
import '../layouts/header_layout.dart';
import '../../l10n/app_localizations.dart';

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
  String? _errorMessage;
  String _selectedStatusFilter = 'all';
  String _searchQuery = '';

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      debugPrint('🔄 Loading admin panel data...');
      
      // Load reports - only draft and submitted status
      final reportsData = await supabase
          .from('report_issues')
          .select()
          .inFilter('status', ['draft', 'submitted'])
          .order('created_at', ascending: false);
      
      debugPrint('✅ Reports loaded: ${(reportsData as List).length} items');
      
      // Load users (profiles table)
      final usersData = await supabase
          .from('profiles')
          .select()
          .order('updated_at', ascending: false);
      
      debugPrint('✅ Users loaded: ${(usersData as List).length} items');
      
      if (mounted) {
        setState(() {
          _reports = (reportsData).map((e) => ReportIssueModel.fromJson(e)).toList();
          _users = List<Map<String, dynamic>>.from(usersData);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading admin data: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.common_error}: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.common_retry,
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: HeaderLayout(
        title: l10n.admin_dashboard,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: l10n.map_refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                Tab(
                  icon: Icon(Icons.dashboard),
                  text: l10n.admin_overview,
                ),
                Tab(
                  icon: Icon(Icons.report),
                  text: '${l10n.admin_reports} (${_reports.length})',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: '${l10n.admin_users} (${_users.length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 2.h),
                        Text(l10n.common_loading),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                l10n.admin_errorLoadingData,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 3.h),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: Icon(Icons.refresh),
                                label: Text(l10n.common_retry),
                              ),
                            ],
                          ),
                        ),
                      )
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final totalReports = _reports.length;
    final totalUsers = _users.length;
    final draftReports = _reports.where((r) => r.status == 'draft').length;
    final submittedReports = _reports.where((r) => r.status == 'submitted').length;
    
    final criticalReports = _reports.where((r) => r.severity == 'critical').length;
    final highReports = _reports.where((r) => r.severity == 'high').length;
    
    final adminUsers = _users.where((u) => u['role'] == 'developer' || u['role'] == 'authority').length;
    final regularUsers = _users.where((u) => u['role'] == 'user').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Quick Stats Section
          Text(
            l10n.admin_quickStatistics,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.admin_totalReports,
                  totalReports.toString(),
                  Icons.assessment,
                  theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  l10n.admin_totalUsers,
                  totalUsers.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Report Status Section
          Text(
            l10n.admin_reportStatus,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.admin_draft,
                  draftReports.toString(),
                  Icons.drafts,
                  Colors.grey,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  l10n.admin_submitted,
                  submittedReports.toString(),
                  Icons.send,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Severity Section
          Text(
            l10n.admin_reportSeverity,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.admin_critical,
                  criticalReports.toString(),
                  Icons.warning_amber_rounded,
                  Colors.red[700]!,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  l10n.admin_high,
                  highReports.toString(),
                  Icons.priority_high,
                  Colors.orange[700]!,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // User Roles Section
          Text(
            l10n.admin_userRoles,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.admin_admins,
                  adminUsers.toString(),
                  Icons.admin_panel_settings,
                  Colors.indigo,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  l10n.admin_regularUsers,
                  regularUsers.toString(),
                  Icons.person,
                  Colors.teal,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    // Filter reports based on selected status
    final filteredReports = _selectedStatusFilter == 'all'
        ? _reports
        : _reports.where((r) => r.status == _selectedStatusFilter).toList();
    
    // Further filter by search query
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
        // Filter and Search Bar
        Container(
          padding: EdgeInsets.all(3.w),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.admin_searchReports,
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              SizedBox(height: 1.5.h),
              // Status filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(l10n.admin_all, 'all', _reports.length),
                    SizedBox(width: 2.w),
                    _buildFilterChip(l10n.admin_draft, 'draft', 
                      _reports.where((r) => r.status == 'draft').length),
                    SizedBox(width: 2.w),
                    _buildFilterChip(l10n.admin_submitted, 'submitted',
                      _reports.where((r) => r.status == 'submitted').length),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Reports list
        Expanded(
          child: searchedReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _searchQuery.isNotEmpty
                            ? l10n.admin_noReportsFound
                            : l10n.admin_noReportsYet,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        SizedBox(height: 1.h),
                        Text(
                          l10n.admin_tryDifferentSearch,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
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
    final l10n = AppLocalizations.of(context);
    final statusColor = _getStatusColor(report.status);
    final severityColor = _getSeverityColor(report.severity);
    
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(3.w),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and severity
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title ?? l10n.admin_untitledReport,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                            Text(l10n.admin_delete),
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
              
              // Description
              if (report.description != null && report.description!.isNotEmpty)
                Text(
                  report.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              SizedBox(height: 1.5.h),
              
              // Status and Severity badges
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: [
                  _buildBadge(
                    report.status.toUpperCase(),
                    statusColor,
                    Icons.info_outline,
                  ),
                  _buildBadge(
                    report.severity.toUpperCase(),
                    severityColor,
                    Icons.warning_amber_rounded,
                  ),
                ],
              ),
              
              SizedBox(height: 1.5.h),
              
              // Footer with metadata
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      report.createdBy ?? l10n.admin_unknown,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
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

  Widget _buildUsersTab() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return _users.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.admin_noUsersFound,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: EdgeInsets.all(3.w),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isAdmin = user['role'] == 'developer' || user['role'] == 'authority';
                
                return Card(
                  margin: EdgeInsets.only(bottom: 2.h),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(3.w),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: isAdmin 
                          ? theme.colorScheme.primary 
                          : Colors.grey[400],
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
                            user['username'] ?? l10n.admin_unknownUser,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(1.w),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  l10n.admin_admins.toUpperCase(),
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
                        Text(
                          user['email'] ?? l10n.admin_noEmail,
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${l10n.home_lastUpdated}: ${_formatDate(DateTime.parse(user['updated_at']))}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3.w),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
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
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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
      default:
        return Colors.grey;
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

  void _showReportDetails(ReportIssueModel report) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
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
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h, bottom: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.admin_reportDetails,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title ?? l10n.admin_untitled,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    
                    if (report.description != null) ...[
                      Text(
                        l10n.admin_description,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(report.description!),
                      SizedBox(height: 2.h),
                    ],
                    
                    Text(
                      l10n.admin_details,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    
                    _buildDetailRow(l10n.admin_status, report.status.toUpperCase()),
                    _buildDetailRow(l10n.admin_severity, report.severity.toUpperCase()),
                    _buildDetailRow(l10n.admin_createdBy, report.createdBy ?? l10n.admin_unknown),
                    _buildDetailRow(l10n.admin_created, _formatDate(report.createdAt)),
                    
                    if (report.latitude != null && report.longitude != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        l10n.admin_location,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      _buildDetailRow(l10n.admin_latitude, report.latitude.toString()),
                      _buildDetailRow(l10n.admin_longitude, report.longitude.toString()),
                    ],
                  ],
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.admin_userDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(l10n.admin_username, user['username'] ?? l10n.admin_unknown),
            _buildDetailRow(l10n.admin_email, user['email'] ?? l10n.admin_noEmail),
            _buildDetailRow(l10n.admin_role, user['role'] ?? 'user'),
            _buildDetailRow(l10n.admin_reportsCount, (user['reports_count'] ?? 0).toString()),
            _buildDetailRow(l10n.admin_reputationScore, (user['reputation_score'] ?? 0).toString()),
            _buildDetailRow(l10n.home_lastUpdated, _formatDate(DateTime.parse(user['updated_at']))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.admin_deleteReport),
        content: Text(l10n.admin_deleteReportConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase
            .from('report_issues')
            .delete()
            .eq('id', reportId);
        
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.admin_reportDeletedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.admin_reportDeleteFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

}
