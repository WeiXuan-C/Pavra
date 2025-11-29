import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Detection API Constants
/// Configuration for OpenRouter AI detection API
class DetectionApiConstants {
  DetectionApiConstants._();

  /// OpenRouter API base URL
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  /// OpenRouter chat completions endpoint
  static String get detectUrl => '$openRouterBaseUrl/chat/completions';

  // Key rotation state
  static int _currentKeyIndex = 0;
  static List<String>? _cachedKeys;

  /// Load all available API keys from environment
  static List<String> _loadApiKeys() {
    if (_cachedKeys != null) return _cachedKeys!;
    
    final keys = <String>[];
    for (int i = 1; i <= 20; i++) {
      final key = dotenv.env['OPEN_ROUTER_KEY_$i'];
      if (key != null && key.isNotEmpty) {
        keys.add(key);
      }
    }
    
    if (keys.isEmpty) {
      throw Exception(
        'No OpenRouter API keys found in environment variables. '
        'Please add OPEN_ROUTER_KEY_1 (or more) to your .env file.',
      );
    }
    
    _cachedKeys = keys;
    return keys;
  }

  /// Get OpenRouter API key with rotation support
  /// Cycles through available keys (OPEN_ROUTER_KEY_1 to OPEN_ROUTER_KEY_20)
  static String getApiKey() {
    final keys = _loadApiKeys();
    final key = keys[_currentKeyIndex % keys.length];
    return key;
  }

  /// Rotate to next API key (call this when rate limit is hit)
  static void rotateApiKey() {
    final keys = _loadApiKeys();
    _currentKeyIndex = (_currentKeyIndex + 1) % keys.length;
  }

  /// Get total number of available API keys
  static int get availableKeyCount => _loadApiKeys().length;

  /// Get OpenRouter image model
  static String get imageModel {
    final model = dotenv.env['OPEN_ROUTER_IMAGE_MODEL'];
    if (model == null || model.isEmpty) {
      // Default to Google Gemini 2.0 Flash free vision model
      return 'google/gemini-2.0-flash-exp:free';
    }
    return model;
  }

  /// Request timeout duration (reduced for better UX)
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 10);

  /// Maximum image size for upload (5MB)
  static const int maxImageSizeBytes = 5 * 1024 * 1024;

  /// Default sensitivity level (1-5 scale)
  static const int defaultSensitivity = 3;

  /// Default history limit
  static const int defaultHistoryLimit = 50;

  /// Maximum history limit
  static const int maxHistoryLimit = 100;

  /// System prompt for road damage detection
  static String getSystemPrompt(int sensitivity) {
    final confidenceThreshold = _getConfidenceThreshold(sensitivity);
    
    return '''You are an AI road damage detection system. Analyze the provided road image and detect any issues.

Detection Types:
- pothole: Holes or depressions in the road surface
- road_crack: Cracks or fissures in the pavement
- uneven_surface: Bumps, dips, or irregular road surface
- flood: Water accumulation or flooding on the road
- accident: Vehicle accidents or collisions
- debris: Objects or materials blocking the road
- obstacle: Physical barriers or obstructions
- normal: No issues detected

Severity Scale (1-5):
1 = Minor issue, no immediate action needed
2 = Noticeable issue, monitor
3 = Moderate issue, plan repair
4 = Serious issue, repair soon
5 = Critical issue, immediate attention required

Confidence Threshold: Report only detections with confidence > $confidenceThreshold

CRITICAL: Respond with ONLY valid JSON. Do not include any text before or after the JSON object. No explanations, no markdown, no code blocks.

Required JSON format:
{
  "issue_detected": true/false,
  "type": "detection_type",
  "severity": 1-5,
  "confidence": 0.0-1.0,
  "description": "Brief description of the issue",
  "suggested_action": "Recommended action to take"
}

If no issue is detected, use:
{
  "issue_detected": false,
  "type": "normal",
  "severity": 1,
  "confidence": 0.95,
  "description": "Road surface appears normal with no significant issues detected",
  "suggested_action": "Continue regular monitoring"
}

Remember: Output ONLY the JSON object, nothing else.''';
  }

  static double _getConfidenceThreshold(int sensitivity) {
    switch (sensitivity) {
      case 1:
        return 0.9; // Very conservative
      case 2:
        return 0.8;
      case 3:
        return 0.7; // Balanced
      case 4:
        return 0.6;
      case 5:
        return 0.5; // Very sensitive
      default:
        return 0.7;
    }
  }
}
