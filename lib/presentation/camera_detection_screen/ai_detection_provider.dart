import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/detection_exception.dart';
import '../../data/models/detection_model.dart';
import '../../data/models/detection_type.dart';
import '../../data/repositories/ai_detection_repository.dart';
import '../../data/sources/local/detection_queue_manager.dart';
import '../../data/models/queued_detection.dart';

/// AI Detection Provider
/// Manages AI detection state for the camera screen
///
/// Handles:
/// - Real-time frame processing
/// - Detection history management
/// - Offline queue retry logic
/// - Sensitivity settings
/// - Alert color and sound logic
class AiDetectionProvider extends ChangeNotifier {
  final AiDetectionRepository _repository;
  final DetectionQueueManager _queueManager;

  // State properties
  bool _isProcessing = false;
  DetectionModel? _latestDetection;
  List<DetectionModel> _detectionHistory = [];
  int _queueSize = 0;
  int _sensitivity = 3; // Default sensitivity level (1-5)

  // Sensitivity preference key
  static const String _sensitivityKey = 'detection_sensitivity';

  AiDetectionProvider({
    required AiDetectionRepository repository,
    required DetectionQueueManager queueManager,
  })  : _repository = repository,
        _queueManager = queueManager {
    _initializeProvider();
  }

  // Getters
  bool get isProcessing => _isProcessing;
  DetectionModel? get latestDetection => _latestDetection;
  List<DetectionModel> get detectionHistory => List.unmodifiable(_detectionHistory);
  int get queueSize => _queueSize;
  int get sensitivity => _sensitivity;

  /// Initialize provider
  /// - Load sensitivity from preferences
  /// - Listen to queue size changes
  Future<void> _initializeProvider() async {
    try {
      // Load sensitivity from preferences
      final prefs = await SharedPreferences.getInstance();
      _sensitivity = prefs.getInt(_sensitivityKey) ?? 3;

      // Listen to queue size changes
      _queueManager.queueSizeStream.listen((size) {
        _queueSize = size;
        notifyListeners();
      });

      // Get initial queue size
      _queueSize = await _queueManager.queueSize;
      notifyListeners();

      developer.log(
        'AiDetectionProvider initialized: sensitivity=$_sensitivity, queueSize=$_queueSize',
        name: 'AiDetectionProvider',
      );
    } catch (e) {
      developer.log(
        'Error initializing provider: $e',
        name: 'AiDetectionProvider',
        error: e,
      );
    }
  }

  /// Process a camera frame for detection
  ///
  /// This method:
  /// 1. Compresses the image
  /// 2. Calls the detection API
  /// 3. Updates the latest detection
  /// 4. Adds to history
  /// 5. Handles offline queueing on network error
  ///
  /// Parameters:
  /// - [image]: Camera frame as XFile
  /// - [latitude]: GPS latitude
  /// - [longitude]: GPS longitude
  /// - [userId]: User ID from authentication
  ///
  /// Throws: [DetectionException] on error
  Future<void> processFrame(
    XFile image,
    double latitude,
    double longitude,
    String userId,
  ) async {
    if (_isProcessing) {
      developer.log(
        'Already processing a frame, skipping',
        name: 'AiDetectionProvider',
      );
      return;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      developer.log(
        'Processing frame: lat=$latitude, lng=$longitude, sensitivity=$_sensitivity',
        name: 'AiDetectionProvider',
      );

      // Call repository to detect from camera
      final detection = await _repository.detectFromCamera(
        image: image,
        latitude: latitude,
        longitude: longitude,
        userId: userId,
        sensitivity: _sensitivity,
      );

      // Update latest detection
      _latestDetection = detection;

      // Add to history (prepend to show newest first)
      _detectionHistory.insert(0, detection);

      // Limit history size to 100 items in memory
      if (_detectionHistory.length > 100) {
        _detectionHistory = _detectionHistory.sublist(0, 100);
      }

      developer.log(
        'Frame processed successfully: type=${detection.type.value}, severity=${detection.severity}',
        name: 'AiDetectionProvider',
      );
    } on DetectionException catch (e) {
      developer.log(
        'Detection exception: ${e.message}',
        name: 'AiDetectionProvider',
        error: e,
      );

      // If network error, queue for retry
      if (e.type == DetectionErrorType.networkError) {
        await _queueDetection(image, latitude, longitude, userId);
      }

      rethrow;
    } catch (e) {
      developer.log(
        'Unexpected error processing frame: $e',
        name: 'AiDetectionProvider',
        error: e,
      );
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Load detection history for user
  ///
  /// Fetches the most recent detections from the backend with optional filtering
  ///
  /// Parameters:
  /// - [userId]: User ID to fetch history for
  /// - [limit]: Maximum number of results (default: 50)
  /// - [filterType]: Optional filter by detection type
  /// - [filterSeverity]: Optional filter by severity level (1-5)
  /// - [startDate]: Optional filter by start date
  /// - [endDate]: Optional filter by end date
  Future<void> loadHistory(
    String userId, {
    int limit = 50,
    DetectionType? filterType,
    int? filterSeverity,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      developer.log(
        'Loading detection history: userId=$userId, limit=$limit, type=${filterType?.value}, severity=$filterSeverity',
        name: 'AiDetectionProvider',
      );

      final history = await _repository.getHistory(
        userId: userId,
        limit: limit,
        filterType: filterType,
        startDate: startDate,
        endDate: endDate,
      );

      // Apply severity filter locally if provided
      // (since backend might not support severity filtering)
      List<DetectionModel> filteredHistory = history;
      if (filterSeverity != null) {
        filteredHistory = history
            .where((detection) => detection.severity == filterSeverity)
            .toList();
      }

      _detectionHistory = filteredHistory;
      notifyListeners();

      developer.log(
        'Loaded ${filteredHistory.length} detections from history',
        name: 'AiDetectionProvider',
      );
    } catch (e) {
      developer.log(
        'Error loading history: $e',
        name: 'AiDetectionProvider',
        error: e,
      );
      rethrow;
    }
  }

  /// Retry all queued detections
  ///
  /// Processes all detections in the offline queue
  /// Called when network connectivity is restored
  ///
  /// Returns: Number of successfully processed detections
  Future<int> retryQueuedDetections() async {
    try {
      developer.log(
        'Retrying queued detections: queueSize=$_queueSize',
        name: 'AiDetectionProvider',
      );

      if (_queueSize == 0) {
        developer.log(
          'No queued detections to retry',
          name: 'AiDetectionProvider',
        );
        return 0;
      }

      // Get userId from first queued detection (all should have same userId)
      final queue = await _queueManager.getQueue();
      final userId = queue.isNotEmpty ? queue.first.userId : '';

      // Process queue with retry logic
      final successfulIds = await _queueManager.processQueue(
        userId: userId,
        processFunction: (queuedDetection) async {
          // Recreate XFile from path
          final image = XFile(queuedDetection.imagePath);

          // Process the detection
          await _repository.detectFromCamera(
            image: image,
            latitude: queuedDetection.latitude,
            longitude: queuedDetection.longitude,
            userId: queuedDetection.userId,
            sensitivity: _sensitivity,
          );
        },
      );

      developer.log(
        'Successfully processed ${successfulIds.length} queued detections',
        name: 'AiDetectionProvider',
      );

      // Update queue size
      _queueSize = await _queueManager.queueSize;
      notifyListeners();

      return successfulIds.length;
    } catch (e) {
      developer.log(
        'Error retrying queued detections: $e',
        name: 'AiDetectionProvider',
        error: e,
      );
      rethrow;
    }
  }

  /// Set detection sensitivity level
  ///
  /// Sensitivity affects the confidence threshold for reporting detections:
  /// - Level 1 (low): Only report detections with confidence > 0.9
  /// - Level 5 (high): Report all detections with confidence > 0.5
  ///
  /// Parameters:
  /// - [level]: Sensitivity level (1-5)
  Future<void> setSensitivity(int level) async {
    if (level < 1 || level > 5) {
      throw ArgumentError('Sensitivity level must be between 1 and 5');
    }

    _sensitivity = level;

    // Persist to preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sensitivityKey, level);

      developer.log(
        'Sensitivity updated to level $level',
        name: 'AiDetectionProvider',
      );

      notifyListeners();
    } catch (e) {
      developer.log(
        'Error saving sensitivity: $e',
        name: 'AiDetectionProvider',
        error: e,
      );
    }
  }

  /// Queue a detection for later processing
  Future<void> _queueDetection(
    XFile image,
    double latitude,
    double longitude,
    String userId,
  ) async {
    try {
      final queuedDetection = QueuedDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: image.path,
        latitude: latitude,
        longitude: longitude,
        userId: userId,
        timestamp: DateTime.now(),
        retryCount: 0,
      );

      await _queueManager.enqueue(queuedDetection);

      developer.log(
        'Detection queued for retry: id=${queuedDetection.id}',
        name: 'AiDetectionProvider',
      );
    } on DetectionException catch (e) {
      if (e.type == DetectionErrorType.queueFull) {
        developer.log(
          'Queue full, oldest detection discarded',
          name: 'AiDetectionProvider',
        );
      }
      // Don't rethrow - queueing failure shouldn't block the UI
    } catch (e) {
      developer.log(
        'Error queueing detection: $e',
        name: 'AiDetectionProvider',
        error: e,
      );
    }
  }

  /// Get alert color based on detection severity and type
  ///
  /// Alert color logic:
  /// - Red: severity >= 4 OR type == accident
  /// - Yellow: severity 2-3
  /// - Green: severity 1 OR type == normal OR no issue detected
  ///
  /// Parameters:
  /// - [detection]: Detection model to evaluate
  ///
  /// Returns: Color for the alert UI
  Color getAlertColor(DetectionModel detection) {
    // Red alert: high severity or accident
    if (detection.isHighSeverity) {
      return Colors.red;
    }

    // Yellow alert: medium severity
    if (detection.isMediumSeverity) {
      return Colors.amber;
    }

    // Green status: low severity or normal
    return Colors.green;
  }

  /// Determine if sound should be played for this detection
  ///
  /// Sound is played only for red alerts (high severity)
  ///
  /// Parameters:
  /// - [detection]: Detection model to evaluate
  ///
  /// Returns: true if sound should be played
  bool shouldPlaySound(DetectionModel detection) {
    return detection.isHighSeverity;
  }

  @override
  void dispose() {
    _repository.dispose();
    _queueManager.dispose();
    super.dispose();
  }
}
