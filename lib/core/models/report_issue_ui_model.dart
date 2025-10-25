import '../../data/models/report_issue_model.dart';
import '../../data/models/issue_photo_model.dart';
import '../../data/models/issue_type_model.dart';
import 'user_model.dart';

/// UI-friendly Report Issue Model
/// Combines data from multiple sources for easy UI consumption
class ReportIssueUiModel {
  final ReportIssueModel report;
  final List<IssuePhotoModel> photos;
  final List<IssueTypeModel> issueTypes;
  final UserProfile? creator;
  final UserProfile? reviewer;
  final String? userVote; // 'verify', 'spam', or null

  ReportIssueUiModel({
    required this.report,
    this.photos = const [],
    this.issueTypes = const [],
    this.creator,
    this.reviewer,
    this.userVote,
  });

  // Convenience getters
  String get id => report.id;
  String? get title => report.title;
  String? get description => report.description;
  String get status => report.status;
  String get severity => report.severity;
  double? get latitude => report.latitude;
  double? get longitude => report.longitude;
  String? get address => report.address;
  DateTime get createdAt => report.createdAt;
  int get verifiedVotes => report.verifiedVotes;
  int get spamVotes => report.spamVotes;

  // UI helpers
  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isReviewed => status == 'reviewed';
  bool get isSpam => status == 'spam';
  bool get isDiscarded => status == 'discard';

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasPhotos => photos.isNotEmpty;
  bool get hasIssueTypes => issueTypes.isNotEmpty;

  IssuePhotoModel? get primaryPhoto =>
      photos.firstWhere((p) => p.isPrimary, orElse: () => photos.first);

  String get severityLabel {
    switch (severity) {
      case 'minor':
        return 'Minor';
      case 'low':
        return 'Low';
      case 'moderate':
        return 'Moderate';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'reviewed':
        return 'Reviewed';
      case 'spam':
        return 'Spam';
      case 'discard':
        return 'Discarded';
      default:
        return 'Unknown';
    }
  }

  bool get canEdit => isDraft;
  bool get canSubmit => isDraft;
  bool get canDelete => isDraft;
  bool get canVote => isSubmitted || isReviewed;

  ReportIssueUiModel copyWith({
    ReportIssueModel? report,
    List<IssuePhotoModel>? photos,
    List<IssueTypeModel>? issueTypes,
    UserProfile? creator,
    UserProfile? reviewer,
    String? userVote,
  }) {
    return ReportIssueUiModel(
      report: report ?? this.report,
      photos: photos ?? this.photos,
      issueTypes: issueTypes ?? this.issueTypes,
      creator: creator ?? this.creator,
      reviewer: reviewer ?? this.reviewer,
      userVote: userVote ?? this.userVote,
    );
  }
}
