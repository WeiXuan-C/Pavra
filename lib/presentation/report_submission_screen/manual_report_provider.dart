import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api/report_issue/report_issue_api.dart';
import '../../core/api/report_issue/issue_type_api.dart';
import '../../data/models/report_issue_model.dart';
import '../../data/models/issue_type_model.dart';

/// Provider for managing manual report drafts
class ManualReportProvider extends ChangeNotifier {
  final ReportIssueApi _reportApi;
  final IssueTypeApi _issueTypeApi;
  final SupabaseClient _supabase;

  ReportIssueModel? _draftReport;
  List<IssueTypeModel> _availableIssueTypes = [];
  bool _isLoading = false;
  String? _error;

  ManualReportProvider({
    required ReportIssueApi reportApi,
    required IssueTypeApi issueTypeApi,
    required SupabaseClient supabase,
  }) : _reportApi = reportApi,
       _issueTypeApi = issueTypeApi,
       _supabase = supabase;

  ReportIssueModel? get draftReport => _draftReport;
  List<IssueTypeModel> get availableIssueTypes => _availableIssueTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDraft => _draftReport != null;

  /// Initialize: Load or create draft report
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load available issue types
      await _loadIssueTypes();

      // Try to find existing draft
      await _loadOrCreateDraft();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all active issue types
  Future<void> _loadIssueTypes() async {
    try {
      final types = await _issueTypeApi.getAllIssueTypes();
      _availableIssueTypes = types.where((type) => !type.isDeleted).toList();
    } catch (e) {
      throw Exception('Failed to load issue types: $e');
    }
  }

  /// Load existing draft or create new one
  Future<void> _loadOrCreateDraft() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Find existing draft
      final drafts = await _reportApi.getMyDrafts();

      if (drafts.isNotEmpty) {
        // Use the first draft found
        _draftReport = drafts.first;
      } else {
        // Create new draft with auto-generated title
        final title = _generateReportTitle();
        _draftReport = await _reportApi.createReport(
          title: title,
          severity: 'moderate',
        );
      }
    } catch (e) {
      throw Exception('Failed to load or create draft: $e');
    }
  }

  /// Generate report title: RPT-[timestamp]-[sequence]
  String _generateReportTitle() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'RPT-$timestamp-001';
  }

  /// Update draft report
  Future<void> updateDraft({
    String? title,
    String? description,
    List<String>? issueTypeIds,
    String? severity,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    if (_draftReport == null) return;

    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (issueTypeIds != null) updates['issue_type_ids'] = issueTypeIds;
      if (severity != null) updates['severity'] = severity;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;

      if (updates.isNotEmpty) {
        _draftReport = await _reportApi.updateReport(_draftReport!.id, updates);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update draft: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Submit the draft report
  Future<void> submitDraft() async {
    if (_draftReport == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _reportApi.submitReport(_draftReport!.id);

      // Clear draft after successful submission
      _draftReport = null;
    } catch (e) {
      _error = 'Failed to submit report: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete the draft report
  Future<void> deleteDraft() async {
    if (_draftReport == null) return;

    try {
      await _reportApi.deleteReport(_draftReport!.id);
      _draftReport = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete draft: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
