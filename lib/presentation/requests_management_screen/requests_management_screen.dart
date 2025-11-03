import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart';
import '../../data/repositories/authority_request_repository.dart';
import '../../data/models/authority_request_model.dart';
import '../layouts/header_layout.dart';
import 'widgets/request_detail_dialog.dart';

/// Requests Management Screen
/// For developers to view and manage all authority requests
class RequestsManagementScreen extends StatefulWidget {
  static const String routeName = '/requests-management';

  const RequestsManagementScreen({super.key});

  @override
  State<RequestsManagementScreen> createState() =>
      _RequestsManagementScreenState();
}

class _RequestsManagementScreenState extends State<RequestsManagementScreen> {
  final _repository = AuthorityRequestRepository();
  List<AuthorityRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedFilter; // null = all, 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await _repository.getAllRequests(
        status: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
      appBar: HeaderLayout(title: l10n.requests_managementTitle),
      body: Column(
        children: [
          // Filter Chips
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.requests_tabAll,
                    icon: Icons.list_alt,
                    isSelected: _selectedFilter == null,
                    onTap: () {
                      setState(() => _selectedFilter = null);
                      _loadRequests();
                    },
                  ),
                  SizedBox(width: 2.w),
                  _FilterChip(
                    label: l10n.requests_tabPending,
                    icon: Icons.hourglass_empty,
                    isSelected: _selectedFilter == 'pending',
                    color: Colors.orange,
                    onTap: () {
                      setState(() => _selectedFilter = 'pending');
                      _loadRequests();
                    },
                  ),
                  SizedBox(width: 2.w),
                  _FilterChip(
                    label: l10n.requests_tabApproved,
                    icon: Icons.check_circle,
                    isSelected: _selectedFilter == 'approved',
                    color: Colors.green,
                    onTap: () {
                      setState(() => _selectedFilter = 'approved');
                      _loadRequests();
                    },
                  ),
                  SizedBox(width: 2.w),
                  _FilterChip(
                    label: l10n.requests_tabRejected,
                    icon: Icons.cancel,
                    isSelected: _selectedFilter == 'rejected',
                    color: Colors.red,
                    onTap: () {
                      setState(() => _selectedFilter = 'rejected');
                      _loadRequests();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(child: _buildBody(l10n, theme)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.common_error,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              FilledButton.icon(
                onPressed: _loadRequests,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.requests_noRequests,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _RequestCard(
            request: request,
            onTap: () => _showRequestDetail(request),
            onStatusChanged: _loadRequests,
          );
        },
      ),
    );
  }

  void _showRequestDetail(AuthorityRequestModel request) {
    showDialog(
      context: context,
      builder: (context) =>
          RequestDetailDialog(request: request, onStatusChanged: _loadRequests),
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return Material(
      color: isSelected
          ? chipColor.withValues(alpha: 0.15)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? chipColor
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 4.5.w,
                color: isSelected
                    ? chipColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 2.w),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? chipColor
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Request Card Widget
class _RequestCard extends StatelessWidget {
  final AuthorityRequestModel request;
  final VoidCallback onTap;
  final VoidCallback onStatusChanged;

  const _RequestCard({
    required this.request,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.organization,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 3.5.w,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              request.location,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: request.status),
                ],
              ),
              SizedBox(height: 1.5.h),
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 4.w,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            '${l10n.requests_userId}: ${request.userId.substring(0, 8)}...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 4.w,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _formatDate(request.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Status Badge Widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.5.w, color: color),
          SizedBox(width: 1.5.w),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 9.sp,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
