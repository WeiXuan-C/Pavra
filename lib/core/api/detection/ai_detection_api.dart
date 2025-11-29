import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../../data/models/detection_exception.dart';
import '../../../data/models/detection_model.dart';
import '../../services/notification_helper_service.dart';
import 'detection_api_constants.dart';

/// AI Detection API
/// Handles HTTP communication with backend detection endpoint
class AiDetectionApi {
  final http.Client _client;
  final NotificationHelperService? _notificationHelper;

  AiDetectionApi({
    http.Client? client,
    NotificationHelperService? notificationHelper,
  })  : _client = client ?? http.Client(),
        _notificationHelper = notificationHelper;

  /// Detect road damage from image using OpenRouter vision model
  ///
  /// Sends compressed image directly to OpenRouter API for AI analysis
  ///
  /// Parameters:
  /// - [imageBase64]: Base64 encoded compressed image (<150KB)
  /// - [latitude]: GPS latitude coordinate
  /// - [longitude]: GPS longitude coordinate
  /// - [userId]: User ID from authentication
  /// - [timestamp]: Capture timestamp
  /// - [sensitivity]: Detection sensitivity level (1-5, default: 3)
  ///
  /// Returns: [DetectionModel] with AI analysis results
  ///
  /// Throws: [DetectionException] on error
  Future<DetectionModel> detectRoadDamage({
    required String imageBase64,
    required double latitude,
    required double longitude,
    required String userId,
    required DateTime timestamp,
    int sensitivity = DetectionApiConstants.defaultSensitivity,
  }) async {
    // Validate sensitivity
    if (sensitivity < 1 || sensitivity > 5) {
      throw DetectionException.api(
        'Invalid sensitivity level: $sensitivity. Must be between 1 and 5.',
      );
    }

    // Retry with key rotation on rate limit
    final maxAttempts = DetectionApiConstants.availableKeyCount;
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        developer.log(
          'Detection attempt ${attempts + 1}/$maxAttempts: userId=$userId, lat=$latitude, lng=$longitude, sensitivity=$sensitivity',
          name: 'AiDetectionApi',
        );

        // Get current API key
        final apiKey = DetectionApiConstants.getApiKey();

        // Prepare OpenRouter request payload
        final payload = {
          'model': DetectionApiConstants.imageModel,
          'messages': [
            {
              'role': 'system',
              'content': DetectionApiConstants.getSystemPrompt(sensitivity),
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyze this road image for damage or issues. Location: $latitude, $longitude',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$imageBase64',
                  },
                },
              ],
            },
          ],
          'temperature': 0.3, // Lower temperature for more consistent results
          'max_tokens': 500,
        };

        developer.log(
          'Calling OpenRouter with model: ${DetectionApiConstants.imageModel}',
          name: 'AiDetectionApi',
        );

        // Send POST request to OpenRouter
        final response = await _client
            .post(
              Uri.parse(DetectionApiConstants.detectUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
                'HTTP-Referer': 'https://roadguard.app',
                'X-Title': 'RoadGuard AI Detection',
              },
              body: jsonEncode(payload),
            )
            .timeout(
              DetectionApiConstants.requestTimeout,
              onTimeout: () {
                throw DetectionException.timeout(
                  'Detection request timed out after ${DetectionApiConstants.requestTimeout.inSeconds}s',
                );
              },
            );

        developer.log(
          'OpenRouter response status: ${response.statusCode}',
          name: 'AiDetectionApi',
        );

        // Handle response
        if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Extract AI response from OpenRouter format
        final choices = responseData['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw DetectionException.invalidResponse(
            'No choices in OpenRouter response',
          );
        }

        final message = choices[0]['message'] as Map<String, dynamic>?;
        if (message == null) {
          throw DetectionException.invalidResponse(
            'No message in OpenRouter response',
          );
        }

        final content = message['content'] as String?;
        if (content == null || content.isEmpty) {
          throw DetectionException.invalidResponse(
            'Empty content in OpenRouter response',
          );
        }

        developer.log(
          'AI response: $content',
          name: 'AiDetectionApi',
        );

        // Parse JSON from AI response
        Map<String, dynamic> detectionData;
        try {
          detectionData = _extractJsonFromResponse(content);
          
          developer.log(
            'Successfully parsed JSON: ${detectionData.keys.join(", ")}',
            name: 'AiDetectionApi',
          );
          
          // Validate required fields
          if (!detectionData.containsKey('issue_detected') ||
              !detectionData.containsKey('type') ||
              !detectionData.containsKey('severity') ||
              !detectionData.containsKey('confidence')) {
            throw FormatException('Missing required fields in AI response');
          }
        } catch (e) {
          developer.log(
            'Failed to parse AI response as JSON: $e\nRaw content: $content',
            name: 'AiDetectionApi',
            error: e,
          );
          
          // Fallback: Return a "normal" detection to avoid blocking the user
          developer.log(
            'Using fallback normal detection due to parse error',
            name: 'AiDetectionApi',
          );
          
          detectionData = {
            'issue_detected': false,
            'type': 'normal',
            'severity': 1,
            'confidence': 0.5,
            'description': 'Unable to analyze image properly. Please try again.',
            'suggested_action': 'Retake photo with better lighting and angle',
          };
        }

        // Add metadata to detection
        detectionData['id'] = '${userId}_${timestamp.millisecondsSinceEpoch}';
        detectionData['created_at'] = timestamp.toIso8601String();
        detectionData['latitude'] = latitude;
        detectionData['longitude'] = longitude;
        detectionData['image_url'] = ''; // Image URL would be set by backend if storing

        developer.log(
          'Detection successful: ${detectionData['type']}',
          name: 'AiDetectionApi',
        );

        // Parse detection model
        final detection = DetectionModel.fromJson(detectionData);

        // Trigger notification for critical or high severity detections
        // Requirements: 5.1, 5.2, 5.3, 5.4, 13.2
        try {
          if (_notificationHelper != null && detection.severity >= 4) {
            // Severity 4-5 is high/critical
            final severityLabel = detection.severity == 5 ? 'critical' : 'high';
            
            await _notificationHelper.notifyCriticalDetection(
              userId: userId,
              detectionId: detection.id,
              issueType: detection.type.value,
              severity: severityLabel,
              latitude: latitude,
              longitude: longitude,
              confidence: detection.confidence,
            );
          }
        } catch (e, stackTrace) {
          // Log error but don't throw - notification failures shouldn't disrupt detection
          developer.log(
            'Failed to send critical detection notification',
            name: 'AiDetectionApi',
            error: e,
            stackTrace: stackTrace,
          );
        }

          return detection;
        } else if (response.statusCode == 429) {
          // Rate limit exceeded - rotate key and retry
          attempts++;
          
          developer.log(
            'Rate limit hit (429), rotating to next API key (attempt $attempts/$maxAttempts)',
            name: 'AiDetectionApi',
          );
          
          if (attempts >= maxAttempts) {
            throw DetectionException.api(
              'Rate limit exceeded on all ${DetectionApiConstants.availableKeyCount} API keys. Please try again later.',
            );
          }
          
          // Rotate to next key and retry
          DetectionApiConstants.rotateApiKey();
          continue;
        } else if (response.statusCode == 401) {
          // Unauthorized - invalid API key, try next one
          attempts++;
          
          developer.log(
            'Invalid API key (401), rotating to next key (attempt $attempts/$maxAttempts)',
            name: 'AiDetectionApi',
          );
          
          if (attempts >= maxAttempts) {
            throw DetectionException.api(
              'All API keys are invalid. Please check your OpenRouter configuration.',
            );
          }
          
          // Rotate to next key and retry
          DetectionApiConstants.rotateApiKey();
          continue;
        } else if (response.statusCode == 400) {
          // Bad request - validation error (don't retry)
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = errorData['error']?['message'] ?? 'Invalid request';

          developer.log(
            'Validation error: $errorMessage',
            name: 'AiDetectionApi',
            error: errorMessage,
          );

          throw DetectionException.api(errorMessage);
        } else if (response.statusCode >= 500) {
          // Server error (don't retry with different keys)
          throw DetectionException.api(
            'OpenRouter server error (${response.statusCode}). Please try again.',
          );
        } else {
          // Other errors (don't retry)
          throw DetectionException.api(
            'Detection failed with status ${response.statusCode}',
          );
        }
      } on DetectionException {
        rethrow;
      } catch (e) {
        developer.log(
          'Error in detectRoadDamage attempt $attempts: $e',
          name: 'AiDetectionApi',
          error: e,
        );

        if (e.toString().contains('SocketException') ||
            e.toString().contains('NetworkException')) {
          throw DetectionException.network(
            'Network error. Please check your connection.',
            e,
          );
        }

        throw DetectionException.unknown(
          'Unexpected error during detection: ${e.toString()}',
          e,
        );
      }
    }

    // Should never reach here
    throw DetectionException.api(
      'All ${DetectionApiConstants.availableKeyCount} API keys exhausted',
    );
  }

  /// Get detection history for user
  ///
  /// NOTE: Since we're calling OpenRouter directly without a backend,
  /// history is managed locally in the AiDetectionProvider.
  /// This method returns an empty list as a placeholder.
  ///
  /// For persistent history across app restarts, consider implementing
  /// local database storage (e.g., SQLite, Hive, or shared_preferences).
  ///
  /// Parameters:
  /// - [userId]: User ID to fetch history for
  /// - [limit]: Maximum number of results (default: 50, max: 100)
  /// - [issueType]: Optional filter by detection type (e.g., 'pothole', 'road_crack')
  /// - [startDate]: Optional filter by start date
  /// - [endDate]: Optional filter by end date
  ///
  /// Returns: Empty list (history is managed in-memory by AiDetectionProvider)
  Future<List<DetectionModel>> getDetectionHistory({
    required String userId,
    int limit = DetectionApiConstants.defaultHistoryLimit,
    String? issueType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log(
      'getDetectionHistory called - returning empty list (history managed locally)',
      name: 'AiDetectionApi',
    );

    // Return empty list since we don't have a backend
    // History is managed in-memory by AiDetectionProvider
    return [];
  }

  /// Extract JSON object from AI response
  /// Handles various formats: plain JSON, markdown code blocks, text with JSON
  Map<String, dynamic> _extractJsonFromResponse(String content) {
    String jsonStr = content.trim();
    
    developer.log(
      'Extracting JSON from response (length: ${jsonStr.length})',
      name: 'AiDetectionApi',
    );
    
    // Remove markdown code blocks
    if (jsonStr.contains('```json')) {
      final parts = jsonStr.split('```json');
      if (parts.length > 1) {
        jsonStr = parts[1].split('```')[0].trim();
      }
    } else if (jsonStr.contains('```')) {
      final parts = jsonStr.split('```');
      if (parts.length > 1) {
        jsonStr = parts[1].split('```')[0].trim();
      }
    }
    
    // Find JSON object boundaries
    final jsonStart = jsonStr.indexOf('{');
    final jsonEnd = jsonStr.lastIndexOf('}');
    
    if (jsonStart == -1 || jsonEnd == -1 || jsonStart >= jsonEnd) {
      throw FormatException('No valid JSON object found in response');
    }
    
    jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
    
    developer.log(
      'Extracted JSON string: ${jsonStr.substring(0, jsonStr.length > 200 ? 200 : jsonStr.length)}...',
      name: 'AiDetectionApi',
    );
    
    // Parse JSON
    final parsed = jsonDecode(jsonStr);
    if (parsed is! Map<String, dynamic>) {
      throw FormatException('Parsed JSON is not an object');
    }
    
    return parsed;
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
