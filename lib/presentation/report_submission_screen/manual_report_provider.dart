import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api/report_issue/report_issue_api.dart';
import '../../core/api/report_issue/issue_type_api.dart';
import '../../core/utils/issue_photo_helper.dart';
import '../../core/services/ai_service.dart';
import '../../data/models/report_issue_model.dart';
import '../../data/models/issue_type_model.dart';
import '../../data/models/issue_photo_model.dart';

/// Provider for managing manual report drafts
class ManualReportProvider extends ChangeNotifier {
  final ReportIssueApi _reportApi;
  final IssueTypeApi _issueTypeApi;
  final SupabaseClient _supabase;
  late final IssuePhotoHelper _photoHelper;

  ReportIssueModel? _draftReport;
  List<IssueTypeModel> _availableIssueTypes = [];
  List<IssuePhotoModel> _uploadedPhotos = [];
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _error;
  double _uploadProgress = 0.0;

  ManualReportProvider({
    required ReportIssueApi reportApi,
    required IssueTypeApi issueTypeApi,
    required SupabaseClient supabase,
  }) : _reportApi = reportApi,
       _issueTypeApi = issueTypeApi,
       _supabase = supabase {
    _photoHelper = IssuePhotoHelper(_reportApi);
  }

  ReportIssueModel? get draftReport => _draftReport;
  List<IssueTypeModel> get availableIssueTypes => _availableIssueTypes;
  List<IssuePhotoModel> get uploadedPhotos => _uploadedPhotos;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get error => _error;
  bool get hasDraft => _draftReport != null;
  double get uploadProgress => _uploadProgress;
  int get photoCount => _uploadedPhotos.length;
  int get mainPhotoCount =>
      _uploadedPhotos.where((p) => p.photoType == 'main').length;

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

      // Load photos for the draft
      if (_draftReport != null) {
        await _loadDraftPhotos();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load photos for the current draft
  Future<void> _loadDraftPhotos() async {
    if (_draftReport == null) return;

    try {
      _uploadedPhotos = await _reportApi.getReportPhotos(_draftReport!.id);
    } catch (e) {
      // Non-critical error, just log it
      debugPrint('Failed to load draft photos: $e');
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
        final title = await _generateReportTitle();
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
  /// Auto-increments sequence number if timestamp already exists
  Future<String> _generateReportTitle() async {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    try {
      // Query all reports with titles starting with this timestamp
      final response = await _supabase
          .from('report_issues')
          .select('title')
          .like('title', 'RPT-$timestamp-%')
          .order('title', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        // No existing reports with this timestamp
        return 'RPT-$timestamp-001';
      }

      // Extract the sequence number from the last title
      final lastTitle = response.first['title'] as String;
      final parts = lastTitle.split('-');

      if (parts.length == 3) {
        final lastSequence = int.tryParse(parts[2]) ?? 0;
        final nextSequence = lastSequence + 1;
        return 'RPT-$timestamp-${nextSequence.toString().padLeft(3, '0')}';
      }

      // Fallback if parsing fails
      return 'RPT-$timestamp-001';
    } catch (e) {
      debugPrint('Error generating report title: $e');
      // Fallback to 001 if query fails
      return 'RPT-$timestamp-001';
    }
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
    debugPrint('[Provider] updateDraft called');
    debugPrint('[Provider] Draft report: ${_draftReport?.id}');

    if (_draftReport == null) {
      debugPrint('[Provider] No draft report available!');
      return;
    }

    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (issueTypeIds != null) updates['issue_type_ids'] = issueTypeIds;
      if (severity != null) updates['severity'] = severity;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;

      debugPrint('[Provider] Updates to apply: $updates');

      if (updates.isNotEmpty) {
        debugPrint('[Provider] Calling API updateReport...');
        _draftReport = await _reportApi.updateReport(_draftReport!.id, updates);
        debugPrint('[Provider] API call successful');
        notifyListeners();
      } else {
        debugPrint('[Provider] No updates to apply');
      }
    } catch (e, stackTrace) {
      debugPrint('[Provider] Error updating draft: $e');
      debugPrint('[Provider] Stack trace: $stackTrace');
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

  /// Discard the draft report (change status to 'discarded')
  Future<void> discardDraft() async {
    debugPrint('[Provider] discardDraft called');
    debugPrint('[Provider] Draft report: ${_draftReport?.id}');

    if (_draftReport == null) {
      debugPrint('[Provider] No draft report available!');
      return;
    }

    try {
      debugPrint('[Provider] Calling API to discard draft...');
      await _reportApi.updateReport(_draftReport!.id, {'status': 'discard'});
      debugPrint('[Provider] Draft discarded successfully');
      _draftReport = null;
      _uploadedPhotos.clear();
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[Provider] Error discarding draft: $e');
      debugPrint('[Provider] Stack trace: $stackTrace');
      _error = 'Failed to discard draft: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== Photo Management ==========

  /// Upload photo to the draft report
  Future<IssuePhotoModel> uploadPhoto({
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
    String photoType = 'main',
    bool isPrimary = false,
  }) async {
    if (_draftReport == null) {
      throw Exception('No draft report available');
    }

    _isUploadingPhoto = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // Simulate progress
      _uploadProgress = 0.3;
      notifyListeners();

      final photo = await _photoHelper.uploadPhoto(
        issueId: _draftReport!.id,
        fileName: fileName,
        fileBytes: fileBytes,
        mimeType: mimeType,
        photoType: photoType,
        isPrimary: isPrimary,
        currentPhotoCount: _uploadedPhotos.length,
        currentMainPhotoCount: mainPhotoCount,
      );

      _uploadProgress = 1.0;
      _uploadedPhotos.add(photo);
      notifyListeners();

      return photo;
    } catch (e) {
      _error = 'Failed to upload photo: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isUploadingPhoto = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// AI Analysis result
  Map<String, dynamic>? _aiAnalysisResult;
  bool _isAnalyzingImage = false;

  Map<String, dynamic>? get aiAnalysisResult => _aiAnalysisResult;
  bool get isAnalyzingImage => _isAnalyzingImage;

  /// Analyze uploaded photo with AI
  Future<Map<String, dynamic>?> analyzePhotoWithAI(String photoUrl) async {
    _isAnalyzingImage = true;
    _aiAnalysisResult = null;
    notifyListeners();

    try {
      final aiService = AiService();

      final result = await aiService.analyzeImage(
        imageUrl: photoUrl,
        additionalContext:
            'This is a report about infrastructure or safety issues.',
      );

      _aiAnalysisResult = result;
      notifyListeners();

      return result;
    } catch (e) {
      debugPrint('AI analysis failed: $e');
      _error = 'AI analysis failed: $e';
      notifyListeners();
      return null;
    } finally {
      _isAnalyzingImage = false;
      notifyListeners();
    }
  }

  /// Clear AI analysis result
  void clearAiAnalysis() {
    _aiAnalysisResult = null;
    notifyListeners();
  }

  /// Upload multiple photos
  Future<List<IssuePhotoModel>> uploadMultiplePhotos({
    required List<({String fileName, Uint8List bytes, String? mimeType})> files,
    String photoType = 'additional',
  }) async {
    if (_draftReport == null) {
      throw Exception('No draft report available');
    }

    _isUploadingPhoto = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final photos = await _photoHelper.uploadMultiplePhotos(
        issueId: _draftReport!.id,
        files: files,
        photoType: photoType,
        currentPhotoCount: _uploadedPhotos.length,
      );

      _uploadedPhotos.addAll(photos);
      _uploadProgress = 1.0;
      notifyListeners();

      return photos;
    } catch (e) {
      _error = 'Failed to upload photos: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isUploadingPhoto = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(IssuePhotoModel photo) async {
    try {
      await _reportApi.deletePhoto(photo.id, photo.photoUrl);
      _uploadedPhotos.removeWhere((p) => p.id == photo.id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete photo: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Validate if can add more photos
  String? canAddPhoto(String photoType) {
    return IssuePhotoHelper.validatePhoto(
      bytes: Uint8List(0), // Dummy for count check
      mimeType: 'image/jpeg',
      currentPhotoCount: _uploadedPhotos.length,
      currentMainPhotoCount: mainPhotoCount,
      photoType: photoType,
    );
  }
}
