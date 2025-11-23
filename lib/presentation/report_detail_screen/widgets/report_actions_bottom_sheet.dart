import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/report_management_service.dart';
import '../../../data/models/report_issue_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../report_edit_screen/report_edit_screen.dart';

class ReportActionsBottomSheet extends StatelessWidget {
  final ReportIssueModel report;
  final ReportManagementService managementService;
  final VoidCallback onDeleted;
  final VoidCallback onEdited;

  const ReportActionsBottomSheet({
    super.key,
    required this.report,
    required this.managementService,
    required this.onDeleted,
    required this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canEdit = report.status == 'draft'; // Only draft reports can be edited

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
          Text(
            l10n.report_actions,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 3.h),

          // Edit
          if (canEdit)
            _buildActionTile(
              context,
              icon: Icons.edit,
              title: l10n.report_actionEdit,
              subtitle: l10n.report_actionEditDesc,
              color: Colors.blue,
              onTap: () => _handleEdit(context),
            ),

          // Share
          _buildActionTile(
            context,
            icon: Icons.share,
            title: l10n.report_actionShare,
            subtitle: l10n.report_actionShareDesc,
            color: Colors.green,
            onTap: () => _handleShare(context),
          ),

          // Export to PDF
          _buildActionTile(
            context,
            icon: Icons.picture_as_pdf,
            title: l10n.report_actionExportPDF,
            subtitle: l10n.report_actionExportPDFDesc,
            color: Colors.orange,
            onTap: () => _handleExportPDF(context),
          ),

          // Delete
          _buildActionTile(
            context,
            icon: Icons.delete,
            title: l10n.report_actionDelete,
            subtitle: l10n.report_actionDeleteDesc,
            color: Colors.red,
            onTap: () => _handleDelete(context),
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
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _handleEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportEditScreen(report: report),
      ),
    );

    if (result == true) {
      onEdited();
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await managementService.shareReport(report);
    } catch (e) {
      Fluttertoast.showToast(
        msg: l10n.report_shareFailed(e.toString()),
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _handleExportPDF(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      // Show loading
      Fluttertoast.showToast(
        msg: l10n.report_generatingPDF,
        backgroundColor: Colors.blue,
      );

      final filePath = await managementService.exportReportToPDF(report);

      // Share the PDF file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Report: ${report.title ?? "Untitled"}',
      );

      Fluttertoast.showToast(
        msg: l10n.report_pdfExported,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: l10n.report_pdfExportFailed(e.toString()),
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.report_deleteConfirmTitle),
        content: Text(l10n.report_deleteConfirmMessage),
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
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await managementService.deleteReport(report.id);
      
      Fluttertoast.showToast(
        msg: l10n.report_deleted,
        backgroundColor: Colors.green,
      );

      onDeleted();
    } catch (e) {
      Fluttertoast.showToast(
        msg: l10n.report_deleteFailed(e.toString()),
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }
}
