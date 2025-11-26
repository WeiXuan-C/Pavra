import 'dart:developer' as developer;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/error_handler.dart';

/// Voice Command Type Enum
/// Defines the types of voice commands that can be recognized
enum VoiceCommandType {
  search,
  navigateHome,
  navigateWork,
  navigateTo,
  stopNavigation,
  showNearbyIssues,
  unknown,
}

/// Voice Command Class
/// Represents a parsed voice command with its type and parameters
class VoiceCommand {
  final VoiceCommandType type;
  final String? location;
  final String rawText;

  VoiceCommand({
    required this.type,
    this.location,
    required this.rawText,
  });

  @override
  String toString() {
    return 'VoiceCommand(type: $type, location: $location, rawText: $rawText)';
  }
}

/// Voice Search Service
/// Handles speech-to-text conversion and voice command processing
///
/// Provides functionality for:
/// - Speech recognition initialization
/// - Starting and stopping voice listening
/// - Parsing voice commands for navigation
class VoiceSearchService {
  static final VoiceSearchService _instance = VoiceSearchService._internal();
  factory VoiceSearchService() => _instance;
  VoiceSearchService._internal();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// Initialize speech recognition
  /// Returns true if initialization was successful
  /// Throws SpeechRecognitionUnavailableException if not available
  /// Throws MicrophonePermissionDeniedException if permission denied
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          ErrorHandler.logError(
            'VoiceSearchService.initialize',
            error,
            additionalInfo: {'errorMsg': error.errorMsg},
          );
        },
        onStatus: (status) {
          developer.log(
            'Speech recognition status: $status',
            name: 'VoiceSearchService',
          );
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (!_isInitialized) {
        // Check if it's a permission issue
        final hasPermission = await _speechToText.hasPermission;
        if (!hasPermission) {
          throw MicrophonePermissionDeniedException();
        }
        throw SpeechRecognitionUnavailableException();
      }

      developer.log(
        'VoiceSearchService initialized: $_isInitialized',
        name: 'VoiceSearchService',
      );

      return _isInitialized;
    } catch (e) {
      if (e is VoiceSearchException) {
        rethrow;
      }

      // Check for permission errors
      if (ErrorHandler.isPermissionError(e)) {
        throw MicrophonePermissionDeniedException();
      }

      ErrorHandler.logError('VoiceSearchService.initialize', e);
      throw SpeechRecognitionUnavailableException();
    }
  }

  /// Start listening for voice input
  /// 
  /// Parameters:
  /// - [onResult]: Callback function called with recognized text (final result)
  /// - [onError]: Callback function called when an error occurs
  /// - [onPartialResult]: Optional callback for real-time transcription updates
  /// 
  /// Throws VoiceSearchException for various error scenarios
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    Function(String)? onPartialResult,
  }) async {
    try {
      if (!_isInitialized) {
        try {
          await initialize();
        } catch (e) {
          if (e is VoiceSearchException) {
            onError(e.message);
            return;
          }
          throw SpeechRecognitionUnavailableException();
        }
      }

      if (_isListening) {
        developer.log(
          'Already listening, stopping previous session',
          name: 'VoiceSearchService',
        );
        await stopListening();
      }

      bool hasReceivedResult = false;
      _isListening = true;

      await _speechToText.listen(
        onResult: (result) {
          final recognizedText = result.recognizedWords;
          
          if (result.finalResult) {
            developer.log(
              'Speech recognized (final): $recognizedText',
              name: 'VoiceSearchService',
            );
            hasReceivedResult = true;
            onResult(recognizedText);
            _isListening = false;
          } else if (onPartialResult != null) {
            // Send partial results for real-time transcription
            developer.log(
              'Speech recognized (partial): $recognizedText',
              name: 'VoiceSearchService',
            );
            onPartialResult(recognizedText);
          }
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );

      developer.log(
        'Started listening for voice input',
        name: 'VoiceSearchService',
      );

      // Set up timeout handler
      Future.delayed(const Duration(seconds: 6), () {
        if (_isListening && !hasReceivedResult) {
          _isListening = false;
          onError(SpeechRecognitionTimeoutException().message);
        }
      });
    } catch (e) {
      _isListening = false;

      if (e is VoiceSearchException) {
        ErrorHandler.logError('VoiceSearchService.startListening', e);
        onError(e.message);
        return;
      }

      // Check for network errors
      if (ErrorHandler.isNetworkError(e)) {
        final networkError = NetworkErrorDuringRecognitionException();
        ErrorHandler.logError('VoiceSearchService.startListening', networkError,
            additionalInfo: {'originalError': e.toString()});
        onError(networkError.message);
        return;
      }

      // Check for permission errors
      if (ErrorHandler.isPermissionError(e)) {
        final permError = MicrophonePermissionDeniedException();
        ErrorHandler.logError('VoiceSearchService.startListening', permError);
        onError(permError.message);
        return;
      }

      ErrorHandler.logError('VoiceSearchService.startListening', e);
      onError('Failed to start voice recognition: ${ErrorHandler.getUserFriendlyMessage(e)}');
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      developer.log(
        'Stopped listening for voice input',
        name: 'VoiceSearchService',
      );
    } catch (e) {
      developer.log(
        'Error stopping voice listening: $e',
        name: 'VoiceSearchService',
        error: e,
      );
    }
  }

  /// Check if speech recognition is available on this device
  bool isAvailable() {
    return _isInitialized && _speechToText.isAvailable;
  }

  /// Parse voice command from recognized text
  /// 
  /// Recognizes commands like:
  /// - "navigate to [location]"
  /// - "navigate home"
  /// - "navigate to work"
  /// - "stop navigation"
  /// - "show nearby issues"
  /// - Any other text is treated as a search query
  VoiceCommand parseCommand(String text) {
    final lowerText = text.toLowerCase().trim();

    // Navigate home
    if (lowerText == 'navigate home' || 
        lowerText == 'go home' || 
        lowerText == 'take me home') {
      return VoiceCommand(
        type: VoiceCommandType.navigateHome,
        rawText: text,
      );
    }

    // Navigate to work
    if (lowerText == 'navigate to work' || 
        lowerText == 'navigate work' ||
        lowerText == 'go to work' || 
        lowerText == 'take me to work') {
      return VoiceCommand(
        type: VoiceCommandType.navigateWork,
        rawText: text,
      );
    }

    // Stop navigation
    if (lowerText == 'stop navigation' || 
        lowerText == 'stop' || 
        lowerText == 'cancel navigation' ||
        lowerText == 'end navigation') {
      return VoiceCommand(
        type: VoiceCommandType.stopNavigation,
        rawText: text,
      );
    }

    // Show nearby issues
    if (lowerText.contains('show nearby issues') || 
        lowerText.contains('nearby issues') ||
        lowerText.contains('show issues') ||
        lowerText.contains('road issues')) {
      return VoiceCommand(
        type: VoiceCommandType.showNearbyIssues,
        rawText: text,
      );
    }

    // Navigate to [location]
    if (lowerText.startsWith('navigate to ') || 
        lowerText.startsWith('go to ') ||
        lowerText.startsWith('take me to ')) {
      String location = '';
      
      if (lowerText.startsWith('navigate to ')) {
        // Find the position in the original text (case-insensitive)
        final startIndex = text.toLowerCase().indexOf('navigate to ') + 'navigate to '.length;
        location = text.substring(startIndex).trim();
      } else if (lowerText.startsWith('go to ')) {
        final startIndex = text.toLowerCase().indexOf('go to ') + 'go to '.length;
        location = text.substring(startIndex).trim();
      } else if (lowerText.startsWith('take me to ')) {
        final startIndex = text.toLowerCase().indexOf('take me to ') + 'take me to '.length;
        location = text.substring(startIndex).trim();
      }

      if (location.isNotEmpty) {
        return VoiceCommand(
          type: VoiceCommandType.navigateTo,
          location: location,
          rawText: text,
        );
      }
    }

    // Default to search for any other text
    return VoiceCommand(
      type: VoiceCommandType.search,
      location: text,
      rawText: text,
    );
  }

  /// Get current listening status
  bool get isListening => _isListening;

  /// Get initialization status
  bool get isInitialized => _isInitialized;
}
