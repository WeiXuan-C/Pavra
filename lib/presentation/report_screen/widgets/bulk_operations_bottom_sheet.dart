import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/report_management_service.dart';
import '../../../data/models/report_issue_model.dart';
import '../../../l10n/app_localizations.dart';

class BulkOperationsBottomSheet extends StatefulWidget {
  final List<ReportIssueModel> selectedReports;
  final ReportManagementService managementService;
  final VoidCallback onCompleted;

  const BulkOperationsBottomSheet({
    super.key,
    required this.selectedReports,
    required this.managementService,
    required this.onCompleted,
  });

  @override
  State<BulkOperationsBottomSheet> createState() =>
      _BulkOperationsBottomSheetState();
}

class _BulkOperationsBottomSheetState
    extends State<BulkOperationsBottomSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(bottom: 3.h),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),

          // Title
          Row(
            children: [
              Icon(
                Icons.checklist,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.report_bulkOperations,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.report_bulkSelected(widget.selectedReports.length),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          if (_isProcessing)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text(
                    l10n.report_bulkProcessing,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else ...[
            // Export to CSV
            _buildActionTile(
              context,
              icon: Icons.table_chart,
              title: l10n.report_bulkExportCSV,
              subtitle: l10n.report_bulkExportCSVDesc,
              color: Colors.green,
              onTap: _handleExportCSV,
            ),

            // Export to PDF (multiple files)
            _buildActionTile(
              context,
              icon: Icons.picture_as_pdf,
              title: l10n.report_bulkExportPDF,
              subtitle: l10n.report_bulkExportPDFDesc,
              color: Colors.orange,
              onTap: _handleExportPDF,
            ),

            // Bulk Delete
            _buildActionTile(
              context,
              icon: Icons.delete_sweep,
              title: l10n.report_bulkDeleteAll,
              subtitle: l10n.report_bulkDeleteAllDesc,
              color: Colors.red,
              onTap: _handleBulkDelete,
            ),

            SizedBox(height: 2.h),

            // Cancel button
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
              ),
              child: Text(l10n.common_cancel),
            ),
          ],

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2.w),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _handleExportCSV() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isProcessing = true);

    try {
      final filePath = await widget.managementService.exportReportsToCSV(
        widget.selectedReports,
      );

      // Share the CSV file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Reports Export (${widget.selectedReports.length} reports)',
      );

      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: l10n.report_bulkCSVExported,
          backgroundColor: Colors.green,
        );
        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        Fluttertoast.showToast(
          msg: l10n.report_bulkCSVExportFailed(e.toString()),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  Future<void> _handleExportPDF() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isProcessing = true);

    try {
      final filePaths = await widget.managementService.bulkExportToPDF(
        widget.selectedReports,
      );

      if (filePaths.isEmpty) {
        throw Exception('No PDFs were generated');
      }

      // Share all PDF files
      await Share.shareXFiles(
        filePaths.map((path) => XFile(path)).toList(),
        subject: 'Reports Export (${filePaths.length} PDFs)',
      );

      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: l10n.report_bulkPDFsExported(filePaths.length),
          backgroundColor: Colors.green,
        );
        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        Fluttertoast.showToast(
          msg: l10n.report_bulkPDFsExportFailed(e.toString()),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  Future<void> _handleBulkDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.report_bulkDeleteConfirmTitle(widget.selectedReports.length)),
        content: Text(l10n.report_bulkDeleteConfirmMessage),
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
            child: Text(l10n.report_bulkDeleteAll),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final reportIds = widget.selectedReports.map((r) => r.id).toList();
      final result = await widget.managementService.bulkDeleteReports(reportIds);

      if (mounted) {
        Navigator.pop(context);
        
        final successCount = result['success'] as int;
        final failCount = result['failed'] as int;

        if (failCount == 0) {
          Fluttertoast.showToast(
            msg: l10n.report_bulkDeleteSuccess(successCount),
            backgroundColor: Colors.green,
          );
        } else {
          Fluttertoast.showToast(
            msg: l10n.report_bulkDeletePartial(successCount, failCount),
            backgroundColor: Colors.orange,
            toastLength: Toast.LENGTH_LONG,
          );
        }

        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        Fluttertoast.showToast(
          msg: l10n.report_bulkDeleteFailed(e.toString()),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }
}
