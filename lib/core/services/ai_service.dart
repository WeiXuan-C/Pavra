import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for interacting with OpenRouter AI directly
class AiService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static int _currentKeyIndex = 0;
  static final List<String> _apiKeys = [];

  AiService() {
    _loadApiKeys();
  }

  /// Load all available API keys from environment
  void _loadApiKeys() {
    if (_apiKeys.isNotEmpty) return; // Already loaded

    for (int i = 1; i <= 20; i++) {
      final key = dotenv.env['OPEN_ROUTER_KEY_$i'];
      if (key != null && key.isNotEmpty) {
        _apiKeys.add(key);
      }
    }

    if (_apiKeys.isEmpty) {
      throw AiException(
        'No OpenRouter API keys found',
        details:
            'Please add OPEN_ROUTER_KEY_1, OPEN_ROUTER_KEY_2, etc. to your .env file',
      );
    }
  }

  /// Get current API key
  String get _apiKey {
    if (_apiKeys.isEmpty) _loadApiKeys();
    return _apiKeys[_currentKeyIndex % _apiKeys.length];
  }

  /// Rotate to next API key
  void _rotateApiKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
  }

  /// Send a simple chat message to AI with automatic key rotation on rate limit
  ///
  /// Returns the AI's response text or throws an exception on error
  Future<String> chat({
    required String prompt,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    return _retryWithKeyRotation(() async {
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://pavra.app',
          'X-Title': 'Pavra App',
        },
        body: jsonEncode({
          'model': model ?? 'google/gemma-3-4b-it:free',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens ?? 1000,
          'temperature': temperature ?? 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractMessage(data);
      } else if (response.statusCode == 429 || response.statusCode == 401) {
        // Rate limit or auth error - rotate key and retry
        throw _RateLimitException(response.statusCode, response.body);
      } else {
        throw AiException(
          'OpenRouter API error: ${response.statusCode}',
          details: response.body,
        );
      }
    });
  }

  /// Extract message from OpenRouter response
  String _extractMessage(Map<String, dynamic> data) {
    try {
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        if (message != null) {
          return message['content'] as String? ?? '';
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Send a chat message with conversation history with automatic key rotation
  ///
  /// [messages] should be a list of maps with 'role' and 'content' keys
  /// Example: [{'role': 'user', 'content': 'Hello'}, {'role': 'assistant', 'content': 'Hi!'}]
  Future<String> chatWithHistory({
    required List<Map<String, String>> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    return _retryWithKeyRotation(() async {
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://pavra.app',
          'X-Title': 'Pavra App',
        },
        body: jsonEncode({
          'model': model ?? 'google/gemma-3-4b-it:free',
          'messages': messages,
          'max_tokens': maxTokens ?? 1000,
          'temperature': temperature ?? 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractMessage(data);
      } else if (response.statusCode == 429 || response.statusCode == 401) {
        throw _RateLimitException(response.statusCode, response.body);
      } else {
        throw AiException(
          'OpenRouter API error: ${response.statusCode}',
          details: response.body,
        );
      }
    });
  }

  /// Get list of available AI models with automatic key rotation
  Future<List<Map<String, dynamic>>> getModels() async {
    return _retryWithKeyRotation(() async {
      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
      } else if (response.statusCode == 429 || response.statusCode == 401) {
        throw _RateLimitException(response.statusCode, response.body);
      } else {
        throw AiException('OpenRouter API error: ${response.statusCode}');
      }
    });
  }

  /// Retry logic with automatic API key rotation on rate limit
  Future<T> _retryWithKeyRotation<T>(Future<T> Function() operation) async {
    int attempts = 0;
    final maxAttempts = _apiKeys.length; // Try all keys once

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } on _RateLimitException catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          throw AiException(
            'All API keys exhausted',
            details: 'Tried ${_apiKeys.length} keys. Last error: ${e.details}',
          );
        }
        // Rotate to next key and retry
        _rotateApiKey();
        continue;
      } catch (e) {
        if (e is AiException) rethrow;
        throw AiException('Network error: ${e.toString()}');
      }
    }

    throw AiException('Max retry attempts reached');
  }

  /// Analyze an image and extract issue information with automatic key rotation
  ///
  /// [imageUrl] - Public URL of the uploaded image
  /// [additionalContext] - Optional context about what to look for
  /// [availableIssueTypes] - List of available issue type names from database
  ///
  /// Returns a map with detected information:
  /// - description: AI-generated description in English
  /// - issueTypes: List of matched issue type names from availableIssueTypes
  /// - severity: Suggested severity level (minor/low/moderate/high/critical)
  /// - confidence: AI's confidence level (low/medium/high)
  Future<Map<String, dynamic>> analyzeImage({
    required String imageUrl,
    String? additionalContext,
    List<String>? availableIssueTypes,
  }) async {
    final prompt = _buildImageAnalysisPrompt(
      additionalContext,
      availableIssueTypes,
    );

    return _retryWithKeyRotation(() async {
      final response = await http
          .post(
            Uri.parse(_openRouterUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://pavra.app',
              'X-Title': 'Pavra App',
            },
            body: jsonEncode({
              'model': 'google/gemma-3-4b-it:free',
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': prompt},
                    {
                      'type': 'image_url',
                      'image_url': {'url': imageUrl},
                    },
                  ],
                },
              ],
              'max_tokens': 500,
              'temperature': 0.3,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw AiException('Request timeout - AI analysis took too long');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final aiResponse = _extractMessage(data);
        return _parseImageAnalysisResponse(aiResponse);
      } else if (response.statusCode == 429 || response.statusCode == 401) {
        throw _RateLimitException(response.statusCode, response.body);
      } else {
        throw AiException(
          'OpenRouter API error: ${response.statusCode}',
          details: response.body,
        );
      }
    });
  }

  /// Build prompt for image analysis
  String _buildImageAnalysisPrompt(
    String? additionalContext,
    List<String>? availableIssueTypes,
  ) {
    final issueTypesSection =
        availableIssueTypes != null && availableIssueTypes.isNotEmpty
        ? '''
IMPORTANT: You MUST select issue types ONLY from this list:
${availableIssueTypes.map((type) => '- $type').join('\n')}

Select 1-3 most relevant types from the above list that match what you see in the image.
'''
        : '''
Issue types can include: pothole, broken streetlight, damaged road, graffiti, illegal dumping, broken sidewalk, damaged signage, flooding, fallen tree, damaged fence, etc.
''';

    final basePrompt =
        '''
Analyze this image and identify any infrastructure or safety issues. Provide your response in the following JSON format:

{
  "description": "Brief description in English",
  "issueTypes": ["type1", "type2"],
  "severity": "minor|low|moderate|high|critical",
  "confidence": "low|medium|high"
}

$issueTypesSection

Severity levels:
- minor: Cosmetic issues, no immediate danger
- low: Minor inconvenience, no safety risk
- moderate: Noticeable issue, potential minor safety concern
- high: Significant issue, clear safety concern
- critical: Immediate danger, requires urgent attention

Confidence levels:
- low: Uncertain about the issue or type
- medium: Reasonably confident
- high: Very confident in the assessment
''';

    if (additionalContext != null && additionalContext.isNotEmpty) {
      return '$basePrompt\n\nAdditional context: $additionalContext';
    }

    return basePrompt;
  }

  /// Parse AI response into structured data
  /// Translate text to Chinese
  Future<String> translateToZh(String text) async {
    return _retryWithKeyRotation(() async {
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://pavra.app',
          'X-Title': 'Pavra App',
        },
        body: jsonEncode({
          'model': 'google/gemma-3-4b-it:free',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Translate the following text to Chinese (Simplified):\n\n$text\n\nProvide ONLY the translation, no explanations.',
            },
          ],
          'max_tokens': 200,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractMessage(data).trim();
      } else if (response.statusCode == 429 || response.statusCode == 401) {
        throw _RateLimitException(response.statusCode, response.body);
      } else {
        throw AiException(
          'OpenRouter API error: ${response.statusCode}',
          details: response.body,
        );
      }
    });
  }

  /// Parse AI response into structured data
  Map<String, dynamic> _parseImageAnalysisResponse(String aiResponse) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(aiResponse);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        return {
          'description': parsed['description'] as String? ?? '',
          'issueTypes':
              (parsed['issueTypes'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          'severity': parsed['severity'] as String? ?? 'moderate',
          'confidence': parsed['confidence'] as String? ?? 'medium',
        };
      }

      // Fallback: return raw response
      return {
        'description': aiResponse,
        'issueTypes': <String>[],
        'severity': 'moderate',
        'confidence': 'low',
      };
    } catch (e) {
      // If parsing fails, return raw response
      return {
        'description': aiResponse,
        'issueTypes': <String>[],
        'severity': 'moderate',
        'confidence': 'low',
      };
    }
  }
}

/// Custom exception for AI service errors
class AiException implements Exception {
  final String message;
  final String? details;

  AiException(this.message, {this.details});

  @override
  String toString() {
    if (details != null) {
      return 'AiException: $message\nDetails: $details';
    }
    return 'AiException: $message';
  }
}

/// Internal exception for rate limit detection
class _RateLimitException implements Exception {
  final int statusCode;
  final String details;

  _RateLimitException(this.statusCode, this.details);
}
