import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/authority_request_model.dart';
import '../../../data/repositories/authority_request_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/providers/auth_provider.dart';

/// Request Detail Dialog
/// Shows detailed information about an authority request
/// Allows developers to approve or reject requests
class RequestDetailDialog extends StatefulWidget {
  final AuthorityRequestModel request;
  final VoidCallback onStatusChanged;

  const RequestDetailDialog({
    super.key,
    required this.request,
    required this.onStatusChanged,
  });

  @override
  State<RequestDetailDialog> createState() => _RequestDetailDialogState();
}

class _RequestDetailDialogState extends State<RequestDetailDialog> {
  final _repository = AuthorityRequestRepository();
  final _userRepository = UserRepository();
  final _commentController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final request = widget.request;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.requests_detailTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Status Badge
              _StatusBadge(status: request.status),
              SizedBox(height: 3.h),

              // Request Information
              _InfoSection(
                title: l10n.requests_requestInfo,
                children: [
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: l10n.settings_idNumber,
                    value: request.idNumber,
                  ),
                  _InfoRow(
                    icon: Icons.business_outlined,
                    label: l10n.settings_organization,
                    value: request.organization,
                  ),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: l10n.settings_location,
                    value: request.location,
                  ),
                  if (request.referrerCode != null)
                    _InfoRow(
                      icon: Icons.code_outlined,
                      label: l10n.settings_referrerCode,
                      value: request.referrerCode!,
                    ),
                  if (request.remarks != null && request.remarks!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: l10n.settings_remarks,
                      value: request.remarks!,
                    ),
                ],
              ),
              SizedBox(height: 2.h),

              // User Information
              _InfoSection(
                title: l10n.requests_userInfo,
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: l10n.requests_userId,
                    value: request.userId,
                    copyable: true,
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.requests_createdAt,
                    value: _formatDateTime(request.createdAt),
                  ),
                ],
              ),

              // Review Information (if reviewed)
              if (request.status != 'pending') ...[
                SizedBox(height: 2.h),
                _InfoSection(
                  title: l10n.requests_reviewInfo,
                  children: [
                    if (request.reviewedBy != null)
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: l10n.requests_reviewedBy,
                        value: request.reviewedBy!,
                        copyable: true,
                      ),
                    if (request.reviewedAt != null)
                      _InfoRow(
                        icon: Icons.access_time_outlined,
                        label: l10n.requests_reviewedAt,
                        value: _formatDateTime(request.reviewedAt!),
                      ),
                    if (request.reviewedComment != null &&
                        request.reviewedComment!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.comment_outlined,
                        label: l10n.requests_reviewComment,
                        value: request.reviewedComment!,
                      ),
                  ],
                ),
              ],

              // Action Section (only for pending requests)
              if (request.status == 'pending') ...[
                SizedBox(height: 3.h),
                Divider(),
                SizedBox(height: 2.h),
                Text(
                  l10n.requests_reviewAction,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: l10n.requests_reviewComment,
                    hintText: l10n.requests_reviewCommentHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleReject(context),
                        icon: const Icon(Icons.cancel),
                        label: Text(l10n.requests_reject),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleApprove(context),
                        icon: const Icon(Icons.check_circle),
                        label: Text(l10n.requests_approve),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    final reviewerId = authProvider.user?.id;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (reviewerId == null) {
      _showError(context, l10n.common_error);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.requests_confirmApprove),
        content: Text(l10n.requests_confirmApproveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.requests_approve),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('� Star ting approval process...');
      debugPrint('� Requeste ID: ${widget.request.id}');
      debugPrint('👤 User ID: ${widget.request.userId}');
      debugPrint('👨‍💼 Reviewer ID: $reviewerId');

      // 1. Update request status to approved
      debugPrint('📋 Step 1: Updating request status...');
      await _repository.updateRequestStatus(
        requestId: widget.request.id,
        status: 'approved',
        reviewedBy: reviewerId,
        reviewedComment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      debugPrint('✅ Request status updated successfully');

      // 2. Update user role from 'user' to 'authority'
      debugPrint('📋 Step 2: Updating user role...');
      await _userRepository.updateProfile(
        userId: widget.request.userId,
        role: 'authority',
      );
      debugPrint('✅ User role updated successfully');

      if (!mounted) return;

      debugPrint('✅ Approval process completed successfully');
      navigator.pop();
      widget.onStatusChanged();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.requests_approveSuccess)),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error during approval: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() => _isProcessing = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    final reviewerId = authProvider.user?.id;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (reviewerId == null) {
      _showError(context, l10n.common_error);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.requests_confirmReject),
        content: Text(l10n.requests_confirmRejectMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.requests_reject),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await _repository.updateRequestStatus(
        requestId: widget.request.id,
        status: 'rejected',
        reviewedBy: reviewerId,
        reviewedComment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (!mounted) return;

      navigator.pop();
      widget.onStatusChanged();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.requests_rejectSuccess)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDateTime(DateTime date) {
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 5.w, color: color),
          SizedBox(width: 2.w),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
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

/// Info Section Widget
class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Info Row Widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 5.w,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(Icons.copy, size: 4.w),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).common_copied),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 8.w, minHeight: 4.h),
            ),
        ],
      ),
    );
  }
}
