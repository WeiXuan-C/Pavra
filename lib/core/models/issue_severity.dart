/// Issue Severity Enum
enum IssueSeverity {
  minor,
  low,
  moderate,
  high,
  critical;

  String get label {
    switch (this) {
      case IssueSeverity.minor:
        return 'Minor';
      case IssueSeverity.low:
        return 'Low';
      case IssueSeverity.moderate:
        return 'Moderate';
      case IssueSeverity.high:
        return 'High';
      case IssueSeverity.critical:
        return 'Critical';
    }
  }

  String get value {
    return name;
  }

  static IssueSeverity fromString(String value) {
    return IssueSeverity.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => IssueSeverity.moderate,
    );
  }
}

/// Issue Status Enum
enum IssueStatus {
  draft,
  submitted,
  reviewed,
  spam,
  discard;

  String get label {
    switch (this) {
      case IssueStatus.draft:
        return 'Draft';
      case IssueStatus.submitted:
        return 'Submitted';
      case IssueStatus.reviewed:
        return 'Reviewed';
      case IssueStatus.spam:
        return 'Spam';
      case IssueStatus.discard:
        return 'Discarded';
    }
  }

  String get value {
    return name;
  }

  static IssueStatus fromString(String value) {
    return IssueStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => IssueStatus.draft,
    );
  }
}

/// Photo Type Enum
enum PhotoType {
  main,
  additional,
  reviewed,
  aiReference;

  String get label {
    switch (this) {
      case PhotoType.main:
        return 'Main Photo';
      case PhotoType.additional:
        return 'Additional Photo';
      case PhotoType.reviewed:
        return 'Review Photo';
      case PhotoType.aiReference:
        return 'AI Reference';
    }
  }

  String get value {
    switch (this) {
      case PhotoType.aiReference:
        return 'ai_reference';
      default:
        return name;
    }
  }

  static PhotoType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ai_reference':
        return PhotoType.aiReference;
      case 'main':
        return PhotoType.main;
      case 'additional':
        return PhotoType.additional;
      case 'reviewed':
        return PhotoType.reviewed;
      default:
        return PhotoType.main;
    }
  }
}

/// Vote Type Enum
enum VoteType {
  verify,
  spam;

  String get label {
    switch (this) {
      case VoteType.verify:
        return 'Verify';
      case VoteType.spam:
        return 'Spam';
    }
  }

  String get value {
    return name;
  }

  static VoteType fromString(String value) {
    return VoteType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => VoteType.verify,
    );
  }
}
