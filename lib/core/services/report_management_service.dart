import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';

import '../api/report_issue/report_issue_api.dart';
import '../../data/models/report_issue_model.dart';

/// Service for managing report operations
/// Handles editing, deletion, sharing, and export functionality
class ReportManagementService {
  final ReportIssueApi _reportApi;

  ReportManagementService(this._reportApi);

  /// Update an existing report
  Future<ReportIssueModel> updateReport({
    required String reportId,
    String? title,
    String? description,
    List<String>? issueTypeIds,
    String? severity,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('🔄 Updating report: $reportId');

      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (issueTypeIds != null) updates['issue_type_ids'] = issueTypeIds;
      if (severity != null) updates['severity'] = severity;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;

      final updatedReport = await _reportApi.updateReport(reportId, updates);

      debugPrint('✅ Report updated successfully');
      return updatedReport;
    } catch (e) {
      debugPrint('❌ Error updating report: $e');
      rethrow;
    }
  }

  /// Delete a report (soft delete)
  Future<void> deleteReport(String reportId) async {
    try {
      debugPrint('🗑️ Deleting report: $reportId');
      await _reportApi.deleteReport(reportId);
      debugPrint('✅ Report deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting report: $e');
      rethrow;
    }
  }

  /// Bulk delete reports
  Future<Map<String, dynamic>> bulkDeleteReports(List<String> reportIds) async {
    int successCount = 0;
    int failCount = 0;
    List<String> failedIds = [];

    for (final reportId in reportIds) {
      try {
        await deleteReport(reportId);
        successCount++;
      } catch (e) {
        failCount++;
        failedIds.add(reportId);
        debugPrint('Failed to delete report $reportId: $e');
      }
    }

    return {
      'success': successCount,
      'failed': failCount,
      'failedIds': failedIds,
    };
  }

  /// Share report as text
  Future<void> shareReport(ReportIssueModel report) async {
    try {
      final text = _formatReportForSharing(report);
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
      debugPrint('✅ Report shared successfully');
    } catch (e) {
      debugPrint('❌ Error sharing report: $e');
      rethrow;
    }
  }

  /// Export single report to PDF
  Future<String> exportReportToPDF(ReportIssueModel report) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Road Safety Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        report.title ?? 'Untitled Report',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Report Details
                _buildPDFSection('Report ID', report.id),
                _buildPDFSection('Status', report.status.toUpperCase()),
                _buildPDFSection('Severity', report.severity.toUpperCase()),
                _buildPDFSection('Created', report.createdAt.toString()),
                _buildPDFSection('Updated', report.updatedAt.toString()),

                pw.SizedBox(height: 20),

                // Location
                pw.Text(
                  'Location',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPDFSection('Address', report.address ?? 'N/A'),
                if (report.latitude != null && report.longitude != null)
                  _buildPDFSection(
                    'Coordinates',
                    '${report.latitude}, ${report.longitude}',
                  ),

                pw.SizedBox(height: 20),

                // Description
                pw.Text(
                  'Description',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  report.description ?? 'No description provided',
                  style: const pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 20),

                // Votes
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(
                            'Verified Votes',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            report.verifiedVotes.toString(),
                            style: const pw.TextStyle(
                              fontSize: 20,
                              color: PdfColors.green,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'Spam Votes',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            report.spamVotes.toString(),
                            style: const pw.TextStyle(
                              fontSize: 20,
                              color: PdfColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Text(
                    'Generated by Pavra - Road Safety Platform',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/report_${report.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF exported: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ Error exporting PDF: $e');
      rethrow;
    }
  }

  /// Export multiple reports to CSV
  Future<String> exportReportsToCSV(List<ReportIssueModel> reports) async {
    try {
      List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'ID',
        'Title',
        'Description',
        'Status',
        'Severity',
        'Address',
        'Latitude',
        'Longitude',
        'Verified Votes',
        'Spam Votes',
        'Created At',
        'Updated At',
      ]);

      // Data rows
      for (final report in reports) {
        rows.add([
          report.id,
          report.title ?? '',
          report.description ?? '',
          report.status,
          report.severity,
          report.address ?? '',
          report.latitude ?? '',
          report.longitude ?? '',
          report.verifiedVotes,
          report.spamVotes,
          report.createdAt.toIso8601String(),
          report.updatedAt.toIso8601String(),
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Save CSV
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/reports_export.csv');
      await file.writeAsString(csv);

      debugPrint('✅ CSV exported: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ Error exporting CSV: $e');
      rethrow;
    }
  }

  /// Bulk export reports to PDF (creates a zip file)
  Future<List<String>> bulkExportToPDF(List<ReportIssueModel> reports) async {
    List<String> filePaths = [];

    for (final report in reports) {
      try {
        final path = await exportReportToPDF(report);
        filePaths.add(path);
      } catch (e) {
        debugPrint('Failed to export report ${report.id}: $e');
      }
    }

    return filePaths;
  }

  // Helper methods

  pw.Widget _buildPDFSection(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatReportForSharing(ReportIssueModel report) {
    final buffer = StringBuffer();

    buffer.writeln('🚨 Road Safety Report');
    buffer.writeln('');
    buffer.writeln('Title: ${report.title ?? "Untitled"}');
    buffer.writeln('Status: ${report.status.toUpperCase()}');
    buffer.writeln('Severity: ${report.severity.toUpperCase()}');
    buffer.writeln('');
    buffer.writeln('📍 Location:');
    buffer.writeln(report.address ?? 'No address provided');
    if (report.latitude != null && report.longitude != null) {
      buffer.writeln('Coordinates: ${report.latitude}, ${report.longitude}');
    }
    buffer.writeln('');
    buffer.writeln('📝 Description:');
    buffer.writeln(report.description ?? 'No description provided');
    buffer.writeln('');
    buffer.writeln('📊 Community Votes:');
    buffer.writeln('✅ Verified: ${report.verifiedVotes}');
    buffer.writeln('⚠️ Spam: ${report.spamVotes}');
    buffer.writeln('');
    buffer.writeln('📅 Created: ${report.createdAt}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('Shared from Pavra - Road Safety Platform');

    return buffer.toString();
  }
}
