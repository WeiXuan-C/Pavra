import 'package:flutter/material.dart';
import '../../core/api/report_issue/report_issue_api.dart';
import '../../data/models/report_issue_model.dart';
import '../../data/models/issue_type_model.dart';
import '../../data/models/issue_photo_model.dart';

/// Provider for Report Detail Screen
/// Manages state and business logic for viewing report details
class ReportDetailProvider extends ChangeNotifier {
  final ReportIssueApi _reportApi;
  final ReportIssueModel report;

  ReportDetailProvider({
    required ReportIssueApi reportApi,
    required this.report,
  }) : _reportApi = reportApi;

  // Issue Types
  List<IssueTypeModel> _issueTypes = [];
  bool _isLoadingTypes = true;

  // Photos
  List<IssuePhotoModel> _photos = [];
  bool _isLoadingPhotos = true;

  // Voting
  String? _userVote; // 'verify' or 'spam' or null
  int _verifiedVotes = 0;
  int _spamVotes = 0;
  bool _isLoadingVotes = true;
  bool _isProcessing = false;

  // Error
  String? _error;

  // Getters
  List<IssueTypeModel> get issueTypes => _issueTypes;
  bool get isLoadingTypes => _isLoadingTypes;

  List<IssuePhotoModel> get photos => _photos;
  bool get isLoadingPhotos => _isLoadingPhotos;

  String? get userVote => _userVote;
  int get verifiedVotes => _verifiedVotes;
  int get spamVotes => _spamVotes;
  bool get isLoadingVotes => _isLoadingVotes;
  bool get isProcessing => _isProcessing;

  String? get error => _error;

  /// Initialize all data
  Future<void> initialize() async {
    _verifiedVotes = report.verifiedVotes;
    _spamVotes = report.spamVotes;

    await Future.wait([loadIssueTypes(), loadPhotos(), loadVotingData()]);
  }

  /// Load issue types for this report
  Future<void> loadIssueTypes() async {
    try {
      if (report.issueTypeIds.isEmpty) {
        _isLoadingTypes = false;
        notifyListeners();
        return;
      }

      // For now, we'll load all and filter
      // This should be optimized in the API layer
      _issueTypes = [];

      _isLoadingTypes = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading issue types: $e');
      _error = 'Failed to load issue types';
      _isLoadingTypes = false;
      notifyListeners();
    }
  }

  /// Load photos for this report
  Future<void> loadPhotos() async {
    try {
      _photos = await _reportApi.getReportPhotos(report.id);
      _isLoadingPhotos = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading photos: $e');
      _error = 'Failed to load photos';
      _isLoadingPhotos = false;
      notifyListeners();
    }
  }

  /// Load voting data (user's vote and vote counts)
  Future<void> loadVotingData() async {
    try {
      final userVote = await _reportApi.getMyVote(report.id);
      final voteCounts = await _reportApi.getVoteCounts(report.id);

      _userVote = userVote;
      _verifiedVotes = voteCounts['verified'] ?? 0;
      _spamVotes = voteCounts['spam'] ?? 0;
      _isLoadingVotes = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voting data: $e');
      _isLoadingVotes = false;
      notifyListeners();
    }
  }

  /// Handle verify vote (toggle on/off)
  Future<bool> handleVerify() async {
    if (_isProcessing) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      if (_userVote == 'verify') {
        // Remove verify vote (toggle off)
        await _reportApi.removeVote(report.id);
        _userVote = null;
        _verifiedVotes = (_verifiedVotes - 1).clamp(0, 999999);
      } else {
        // Cast verify vote (will update if user had spam vote)
        await _reportApi.voteVerify(report.id);

        // If user had spam vote, decrement spam count
        if (_userVote == 'spam') {
          _spamVotes = (_spamVotes - 1).clamp(0, 999999);
        }

        _userVote = 'verify';
        _verifiedVotes++;
      }

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error voting: $e');
      _error = 'Failed to vote: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Handle spam vote (toggle on/off)
  Future<bool> handleSpam() async {
    if (_isProcessing) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      if (_userVote == 'spam') {
        // Remove spam vote (toggle off)
        await _reportApi.removeVote(report.id);
        _userVote = null;
        _spamVotes = (_spamVotes - 1).clamp(0, 999999);
      } else {
        // Cast spam vote (will update if user had verify vote)
        await _reportApi.voteSpam(report.id);

        // If user had verify vote, decrement verify count
        if (_userVote == 'verify') {
          _verifiedVotes = (_verifiedVotes - 1).clamp(0, 999999);
        }

        _userVote = 'spam';
        _spamVotes++;
      }

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error voting: $e');
      _error = 'Failed to vote: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
