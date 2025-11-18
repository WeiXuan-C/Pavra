/// Detection Error Type Enum
/// Represents different types of errors that can occur during detection
enum DetectionErrorType {
  compressionFailed,
  networkError,
  apiError,
  invalidResponse,
  queueFull,
  permissionDenied,
  invalidImage,
  timeout,
  unknown,
}

/// Detection Exception
/// Custom exception class for AI detection errors
class DetectionException implements Exception {
  final String message;
  final DetectionErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  DetectionException({
    required this.message,
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  /// Create exception from network error
  factory DetectionException.network(String message, [dynamic error]) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.networkError,
      originalError: error,
    );
  }

  /// Create exception from API error
  factory DetectionException.api(String message, [dynamic error]) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.apiError,
      originalError: error,
    );
  }

  /// Create exception from compression failure
  factory DetectionException.compression(String message, [dynamic error]) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.compressionFailed,
      originalError: error,
    );
  }

  /// Create exception from invalid response
  factory DetectionException.invalidResponse(String message, [dynamic error]) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.invalidResponse,
      originalError: error,
    );
  }

  /// Create exception from queue full
  factory DetectionException.queueFull(String message) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.queueFull,
    );
  }

  /// Create exception from permission denied
  factory DetectionException.permissionDenied(String message) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.permissionDenied,
    );
  }

  /// Create exception from invalid image
  factory DetectionException.invalidImage(String message, [dynamic error]) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.invalidImage,
      originalError: error,
    );
  }

  /// Create exception from timeout
  factory DetectionException.timeout(String message) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.timeout,
    );
  }

  /// Create exception from unknown error
  factory DetectionException.unknown(String message, [dynamic error]) {
    return DetectionException(
      message: message,
      type: DetectionErrorType.unknown,
      originalError: error,
    );
  }

  @override
  String toString() {
    return 'DetectionException: $message (type: $type)';
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case DetectionErrorType.compressionFailed:
        return 'Failed to process image. Please try again.';
      case DetectionErrorType.networkError:
        return 'Network error. Detection will be queued for retry.';
      case DetectionErrorType.apiError:
        return 'Detection failed. Please try again.';
      case DetectionErrorType.invalidResponse:
        return 'Invalid response from server. Please try again.';
      case DetectionErrorType.queueFull:
        return 'Detection queue is full. Oldest detection discarded.';
      case DetectionErrorType.permissionDenied:
        return 'Camera permission is required for detection.';
      case DetectionErrorType.invalidImage:
        return 'Invalid image format. Please try again.';
      case DetectionErrorType.timeout:
        return 'Detection timed out. Please try again.';
      case DetectionErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
