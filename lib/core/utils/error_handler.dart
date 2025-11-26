import 'dart:developer' as developer;

/// Custom exception classes for different error scenarios

/// Base exception class for all app-specific errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Voice Search Related Exceptions

class VoiceSearchException extends AppException {
  VoiceSearchException(super.message, {super.code, super.originalError});
}

class SpeechRecognitionUnavailableException extends VoiceSearchException {
  SpeechRecognitionUnavailableException()
      : super(
          'Voice search is not available on this device',
          code: 'SPEECH_UNAVAILABLE',
        );
}

class MicrophonePermissionDeniedException extends VoiceSearchException {
  MicrophonePermissionDeniedException()
      : super(
          'Microphone permission is required for voice search. Please grant permission in settings.',
          code: 'MICROPHONE_PERMISSION_DENIED',
        );
}

class SpeechRecognitionTimeoutException extends VoiceSearchException {
  SpeechRecognitionTimeoutException()
      : super(
          'No speech detected. Please try again.',
          code: 'SPEECH_TIMEOUT',
        );
}

class NetworkErrorDuringRecognitionException extends VoiceSearchException {
  NetworkErrorDuringRecognitionException()
      : super(
          'Network error during voice recognition. Please check your connection and try again.',
          code: 'NETWORK_ERROR_RECOGNITION',
        );
}

/// Route Calculation Related Exceptions

class RouteCalculationException extends AppException {
  RouteCalculationException(super.message, {super.code, super.originalError});
}

class NoRouteFoundException extends RouteCalculationException {
  final String travelMode;

  NoRouteFoundException(this.travelMode)
      : super(
          'No route available for selected travel mode: $travelMode. Try a different travel mode.',
          code: 'NO_ROUTE_FOUND',
        );
}

class ApiRateLimitExceededException extends RouteCalculationException {
  ApiRateLimitExceededException()
      : super(
          'Too many requests. Please try again in a few moments.',
          code: 'API_RATE_LIMIT',
        );
}

class InvalidWaypointCoordinatesException extends RouteCalculationException {
  final double? latitude;
  final double? longitude;

  InvalidWaypointCoordinatesException({this.latitude, this.longitude})
      : super(
          'Invalid waypoint coordinates: lat=$latitude, lng=$longitude',
          code: 'INVALID_COORDINATES',
        );
}

class RouteOptimizationFailedException extends RouteCalculationException {
  RouteOptimizationFailedException({dynamic originalError})
      : super(
          'Failed to optimize route. Using original route order.',
          code: 'OPTIMIZATION_FAILED',
          originalError: originalError,
        );
}

/// Database Related Exceptions

class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.originalError});
}

class DuplicateLabelException extends DatabaseException {
  final String label;

  DuplicateLabelException(this.label)
      : super(
          'A location with label "$label" already exists. Please choose a different label.',
          code: 'DUPLICATE_LABEL',
        );
}

class DatabaseConnectionFailedException extends DatabaseException {
  DatabaseConnectionFailedException({dynamic originalError})
      : super(
          'Unable to connect to database. Please check your internet connection.',
          code: 'DATABASE_CONNECTION_FAILED',
          originalError: originalError,
        );
}

class RecordNotFoundException extends DatabaseException {
  final String recordType;
  final String recordId;

  RecordNotFoundException(this.recordType, this.recordId)
      : super(
          '$recordType not found: $recordId',
          code: 'RECORD_NOT_FOUND',
        );
}

/// Network Related Exceptions

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

class NetworkTimeoutException extends NetworkException {
  NetworkTimeoutException()
      : super(
          'Request timed out. Please check your connection and try again.',
          code: 'NETWORK_TIMEOUT',
        );
}

class NoInternetConnectionException extends NetworkException {
  NoInternetConnectionException()
      : super(
          'No internet connection. Please check your network settings.',
          code: 'NO_INTERNET',
        );
}

/// Error Handler Utility Class
class ErrorHandler {
  /// Handle errors and convert them to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    // Handle common error patterns
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission') && errorString.contains('denied')) {
      return 'Permission denied. Please grant the required permissions in settings.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Authentication required. Please sign in again.';
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'You do not have permission to perform this action.';
    }

    if (errorString.contains('rate limit') || errorString.contains('429')) {
      return 'Too many requests. Please try again later.';
    }

    if (errorString.contains('server error') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }

    // Default message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Log error with context
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) {
    final errorMessage = StringBuffer();
    errorMessage.writeln('Error in $context:');
    errorMessage.writeln('Message: ${error.toString()}');

    if (error is AppException && error.code != null) {
      errorMessage.writeln('Code: ${error.code}');
    }

    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      errorMessage.writeln('Additional Info:');
      additionalInfo.forEach((key, value) {
        errorMessage.writeln('  $key: $value');
      });
    }

    developer.log(
      errorMessage.toString(),
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Validate coordinates
  static void validateCoordinates(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      throw InvalidWaypointCoordinatesException(
        latitude: latitude,
        longitude: longitude,
      );
    }

    if (longitude < -180 || longitude > 180) {
      throw InvalidWaypointCoordinatesException(
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  /// Check if error is a network error
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException) return true;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('timeout');
  }

  /// Check if error is a permission error
  static bool isPermissionError(dynamic error) {
    if (error is MicrophonePermissionDeniedException) return true;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') && errorString.contains('denied');
  }

  /// Check if error is a rate limit error
  static bool isRateLimitError(dynamic error) {
    if (error is ApiRateLimitExceededException) return true;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429');
  }
}
