import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';

/// Retry helper with exponential backoff
///
/// Provides retry logic for failed operations with configurable
/// retry attempts, delays, and exponential backoff
class RetryHelper {
  static final _log = Logger('RetryHelper');

  /// Execute a function with retry logic and exponential backoff
  ///
  /// [operation] - The async function to execute
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay between retries in milliseconds (default: 1000ms)
  /// [maxDelay] - Maximum delay between retries in milliseconds (default: 30000ms)
  /// [backoffMultiplier] - Multiplier for exponential backoff (default: 2.0)
  /// [retryIf] - Optional predicate to determine if error should trigger retry
  /// [onRetry] - Optional callback invoked before each retry attempt
  ///
  /// Returns the result of the operation if successful
  /// Throws the last exception if all retry attempts fail
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 30000,
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? retryIf,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    if (maxAttempts < 1) {
      throw ArgumentError('maxAttempts must be at least 1');
    }

    int attempt = 0;
    dynamic lastError;

    while (attempt < maxAttempts) {
      attempt++;

      try {
        _log.fine('Executing operation (attempt $attempt/$maxAttempts)');
        final result = await operation();
        
        if (attempt > 1) {
          _log.info('✓ Operation succeeded on attempt $attempt/$maxAttempts');
        }
        
        return result;
      } catch (error, stackTrace) {
        lastError = error;
        
        // Check if we should retry this error
        if (retryIf != null && !retryIf(error)) {
          _log.warning('❌ Operation failed with non-retryable error: $error');
          rethrow;
        }

        // If this was the last attempt, throw the error
        if (attempt >= maxAttempts) {
          _log.severe(
            '❌ Operation failed after $maxAttempts attempts: $error',
          );
          _log.severe('Stack trace: $stackTrace');
          rethrow;
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(
          attempt: attempt,
          initialDelay: initialDelay,
          maxDelay: maxDelay,
          backoffMultiplier: backoffMultiplier,
        );

        _log.warning(
          '⚠️ Operation failed (attempt $attempt/$maxAttempts): $error',
        );
        _log.info('⏳ Retrying in ${delay}ms...');

        // Invoke retry callback if provided
        if (onRetry != null) {
          try {
            onRetry(attempt, error);
          } catch (callbackError) {
            _log.warning('⚠️ Retry callback error: $callbackError');
          }
        }

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    // This should never be reached, but just in case
    throw lastError ?? Exception('Operation failed after $maxAttempts attempts');
  }

  /// Calculate delay with exponential backoff and jitter
  ///
  /// Uses exponential backoff with random jitter to prevent thundering herd
  static int _calculateDelay({
    required int attempt,
    required int initialDelay,
    required int maxDelay,
    required double backoffMultiplier,
  }) {
    // Calculate exponential delay: initialDelay * (backoffMultiplier ^ (attempt - 1))
    final exponentialDelay = initialDelay * pow(backoffMultiplier, attempt - 1);
    
    // Cap at maxDelay
    final cappedDelay = min(exponentialDelay, maxDelay.toDouble());
    
    // Add random jitter (±25% of delay)
    final jitter = cappedDelay * 0.25 * (Random().nextDouble() * 2 - 1);
    final finalDelay = cappedDelay + jitter;
    
    return max(0, finalDelay.toInt());
  }

  /// Check if an error is retryable (network/timeout errors)
  static bool isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network-related errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return true;
    }

    // HTTP status codes that should be retried
    if (errorString.contains('429') || // Too Many Requests
        errorString.contains('500') || // Internal Server Error
        errorString.contains('502') || // Bad Gateway
        errorString.contains('503') || // Service Unavailable
        errorString.contains('504')) { // Gateway Timeout
      return true;
    }

    return false;
  }

  /// Check if an error is a OneSignal API error that should be retried
  static bool isRetryableOneSignalError(dynamic error) {
    if (!isRetryableError(error)) {
      return false;
    }

    final errorString = error.toString().toLowerCase();
    
    // Don't retry authentication errors
    if (errorString.contains('401') || errorString.contains('403')) {
      return false;
    }

    // Don't retry bad request errors
    if (errorString.contains('400')) {
      return false;
    }

    return true;
  }

  /// Check if an error is a QStash API error that should be retried
  static bool isRetryableQStashError(dynamic error) {
    return isRetryableError(error);
  }

  /// Check if an error is a database error that should be retried
  static bool isRetryableDatabaseError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Retry on connection errors
    if (errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return true;
    }

    // Don't retry constraint violations or data errors
    if (errorString.contains('constraint') ||
        errorString.contains('duplicate') ||
        errorString.contains('foreign key')) {
      return false;
    }

    return isRetryableError(error);
  }
}

