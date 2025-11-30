import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import '../../core/api/detection/ai_detection_api.dart';
import '../../core/api/notification/notification_api.dart';
import '../../core/services/image_compression_service.dart';
import '../../core/services/notification_helper_service.dart';
import '../models/detection_exception.dart';
import '../models/detection_model.dart';
import '../models/detection_type.dart';

/// AI Detection Repository
/// Bridge between API and UI layer for road damage detection
///
/// Handles:
/// - Image compression before API calls
/// - API response transformation to DetectionModel
/// - Error handling and logging
/// - History retrieval with filtering
class AiDetectionRepository {
  final AiDetectionApi _api;
  final ImageCompressionService _compressionService;

  AiDetectionRepository({
    AiDetectionApi? api,
    ImageCompressionService? compressionService,
  })  : _api = api ?? AiDetectionApi(
          notificationHelper: NotificationHelperService(NotificationApi()),
        ),
        _compressionService = compressionService ?? ImageCompressionService();

  /// Detect road damage from camera image
  ///
  /// This method:
  /// 1. Compresses the image to <150KB
  /// 2. Converts to Base64
  /// 3. Calls the detection API
  /// 4. Returns the DetectionModel result with local image path
  ///
  /// Parameters:
  /// - [image]: Camera image file (XFile from camera plugin)
  /// - [latitude]: GPS latitude coordinate
  /// - [longitude]: GPS longitude coordinate
  /// - [userId]: User ID from authentication
  /// - [sensitivity]: Detection sensitivity level (1-5, default: 3)
  ///
  /// Returns: [DetectionModel] with AI analysis results
  ///
  /// Throws: [DetectionException] on error
  Future<DetectionModel> detectFromCamera({
    required XFile image,
    required double latitude,
    required double longitude,
    required String userId,
    int sensitivity = 3,
  }) async {
    try {
      developer.log(
        'Starting detection from camera: userId=$userId, lat=$latitude, lng=$longitude',
        name: 'AiDetectionRepository',
      );

      // Save the local image path for later use
      final localImagePath = image.path;
      developer.log(
        'Local image path: $localImagePath',
        name: 'AiDetectionRepository',
      );

      // Log original image size
      final originalSize = await _compressionService.getImageSize(image);
      developer.log(
        'Original image size: ${(originalSize / 1024).toStringAsFixed(2)} KB',
        name: 'AiDetectionRepository',
      );

      // Step 1: Compress image
      developer.log(
        'Compressing image...',
        name: 'AiDetectionRepository',
      );

      final compressedBytes = await _compressionService.compressImage(
        imageFile: image,
      );

      developer.log(
        'Compressed image size: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB',
        name: 'AiDetectionRepository',
      );

      // Step 2: Convert to Base64
      final imageBase64 = _compressionService.convertToBase64(compressedBytes);

      developer.log(
        'Image converted to Base64, length: ${imageBase64.length}',
        name: 'AiDetectionRepository',
      );

      // Step 3: Call detection API
      developer.log(
        'Calling detection API...',
        name: 'AiDetectionRepository',
      );

      final detection = await _api.detectRoadDamage(
        imageBase64: imageBase64,
        latitude: latitude,
        longitude: longitude,
        userId: userId,
        timestamp: DateTime.now(),
        sensitivity: sensitivity,
      );

      developer.log(
        'Detection successful: type=${detection.type.value}, severity=${detection.severity}, confidence=${detection.confidence}',
        name: 'AiDetectionRepository',
      );

      // Add local image path to detection model
      final detectionWithPath = detection.copyWith(
        localImagePath: localImagePath,
      );

      return detectionWithPath;
    } on DetectionException {
      // Re-throw DetectionException as-is
      rethrow;
    } catch (e) {
      developer.log(
        'Error in detectFromCamera: $e',
        name: 'AiDetectionRepository',
        error: e,
      );

      // Wrap compression errors
      if (e.toString().contains('compression')) {
        throw DetectionException.compression(
          'Failed to compress image: ${e.toString()}',
          e,
        );
      }

      // Wrap other errors
      throw DetectionException.unknown(
        'Unexpected error during detection: ${e.toString()}',
        e,
      );
    }
  }

  /// Get detection history for user with optional filtering
  ///
  /// Retrieves past detections from the backend with support for:
  /// - Filtering by detection type
  /// - Filtering by date range
  /// - Limiting number of results
  ///
  /// Parameters:
  /// - [userId]: User ID to fetch history for
  /// - [limit]: Maximum number of results (default: 50, max: 100)
  /// - [filterType]: Optional filter by detection type
  /// - [startDate]: Optional filter by start date
  /// - [endDate]: Optional filter by end date
  ///
  /// Returns: List of [DetectionModel] objects ordered by created_at descending
  ///
  /// Throws: [DetectionException] on error
  Future<List<DetectionModel>> getHistory({
    required String userId,
    int limit = 50,
    DetectionType? filterType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      developer.log(
        'Fetching detection history: userId=$userId, limit=$limit, type=${filterType?.value}',
        name: 'AiDetectionRepository',
      );

      // Convert DetectionType enum to string for API
      final issueType = filterType?.value;

      // Call API with filters
      final detections = await _api.getDetectionHistory(
        userId: userId,
        limit: limit,
        issueType: issueType,
        startDate: startDate,
        endDate: endDate,
      );

      developer.log(
        'Retrieved ${detections.length} detections from history',
        name: 'AiDetectionRepository',
      );

      return detections;
    } on DetectionException {
      // Re-throw DetectionException as-is
      rethrow;
    } catch (e) {
      developer.log(
        'Error in getHistory: $e',
        name: 'AiDetectionRepository',
        error: e,
      );

      throw DetectionException.unknown(
        'Unexpected error fetching history: ${e.toString()}',
        e,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _api.dispose();
  }
}
