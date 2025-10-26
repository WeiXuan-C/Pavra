import 'dart:typed_data';
import 'dart:io';
import '../../data/models/issue_photo_model.dart';
import '../api/report_issue/report_issue_api.dart';

/// Helper class for issue photo operations
/// Handles validation and upload coordination
class IssuePhotoHelper {
  final ReportIssueApi _api;

  IssuePhotoHelper(this._api);

  // Photo constraints
  static const int maxPhotoSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxPhotosPerIssue = 10;
  static const int maxMainPhotos = 3;
  static const int maxAdditionalPhotos = 7;
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  /// Validate photo before upload
  static String? validatePhoto({
    required Uint8List bytes,
    required String? mimeType,
    required int currentPhotoCount,
    required int currentMainPhotoCount,
    required String photoType,
  }) {
    // Check file size
    if (bytes.length > maxPhotoSizeBytes) {
      return 'Photo size exceeds 10MB limit';
    }

    // Check MIME type
    if (mimeType != null && !allowedMimeTypes.contains(mimeType)) {
      return 'Invalid photo format. Only JPEG, PNG, and WebP are allowed';
    }

    // Check photo count limits
    if (currentPhotoCount >= maxPhotosPerIssue) {
      return 'Maximum $maxPhotosPerIssue photos allowed per issue';
    }

    if (photoType == 'main' && currentMainPhotoCount >= maxMainPhotos) {
      return 'Maximum $maxMainPhotos main photos allowed';
    }

    return null; // Valid
  }

  /// Upload photo with validation
  Future<IssuePhotoModel> uploadPhoto({
    required String issueId,
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
    String photoType = 'main',
    bool isPrimary = false,
    int currentPhotoCount = 0,
    int currentMainPhotoCount = 0,
  }) async {
    // Validate
    final error = validatePhoto(
      bytes: fileBytes,
      mimeType: mimeType,
      currentPhotoCount: currentPhotoCount,
      currentMainPhotoCount: currentMainPhotoCount,
      photoType: photoType,
    );

    if (error != null) {
      throw Exception(error);
    }

    // Upload
    return await _api.uploadPhoto(
      issueId: issueId,
      fileName: fileName,
      fileBytes: fileBytes,
      mimeType: mimeType,
      photoType: photoType,
      isPrimary: isPrimary,
    );
  }

  /// Upload multiple photos with validation
  Future<List<IssuePhotoModel>> uploadMultiplePhotos({
    required String issueId,
    required List<({String fileName, Uint8List bytes, String? mimeType})> files,
    String photoType = 'additional',
    int currentPhotoCount = 0,
  }) async {
    final uploadedPhotos = <IssuePhotoModel>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      try {
        final photo = await uploadPhoto(
          issueId: issueId,
          fileName: file.fileName,
          fileBytes: file.bytes,
          mimeType: file.mimeType,
          photoType: photoType,
          isPrimary: i == 0 && photoType == 'main',
          currentPhotoCount: currentPhotoCount + uploadedPhotos.length,
          currentMainPhotoCount: photoType == 'main'
              ? uploadedPhotos.length
              : 0,
        );
        uploadedPhotos.add(photo);
      } catch (e) {
        print('Failed to upload ${file.fileName}: $e');
        // Continue with other photos
      }
    }

    return uploadedPhotos;
  }

  /// Get photo from file path
  static Future<({String fileName, Uint8List bytes, String? mimeType})>
  getPhotoFromFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    // Determine MIME type from extension
    String? mimeType;
    if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (fileName.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else if (fileName.toLowerCase().endsWith('.webp')) {
      mimeType = 'image/webp';
    }

    return (fileName: fileName, bytes: bytes, mimeType: mimeType);
  }
}
