import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for interacting with OpenRouter AI directly
class AiService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  String get _apiKey => dotenv.env['OPEN_ROUTER_API_KEY'] ?? '';

  AiService();

  /// Send a simple chat message to AI
  ///
  /// Returns the AI's response text or throws an exception on error
  Future<String> chat({
    required String prompt,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://pavra.app',
          'X-Title': 'Pavra App',
        },
        body: jsonEncode({
          'model': model ?? 'nvidia/nemotron-nano-12b-v2-vl:free',
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
      } else {
        throw AiException(
          'OpenRouter API error: ${response.statusCode}',
          details: response.body,
        );
      }
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('Network error: ${e.toString()}');
    }
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

  /// Send a chat message with conversation history
  ///
  /// [messages] should be a list of maps with 'role' and 'content' keys
  /// Example: [{'role': 'user', 'content': 'Hello'}, {'role': 'assistant', 'content': 'Hi!'}]
  Future<String> chatWithHistory({
    required List<Map<String, String>> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://pavra.app',
          'X-Title': 'Pavra App',
        },
        body: jsonEncode({
          'model': model ?? 'nvidia/nemotron-nano-12b-v2-vl:free',
          'messages': messages,
          'max_tokens': maxTokens ?? 1000,
          'temperature': temperature ?? 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractMessage(data);
      } else {
        throw AiException(
          'OpenRouter API error: ${response.statusCode}',
          details: response.body,
        );
      }
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('Network error: ${e.toString()}');
    }
  }

  /// Get list of available AI models
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
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
      } else {
        throw AiException('OpenRouter API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('Network error: ${e.toString()}');
    }
  }

  /// Analyze an image and extract issue information
  ///
  /// [imageUrl] - Public URL of the uploaded image
  /// [additionalContext] - Optional context about what to look for
  ///
  /// Returns a map with detected information:
  /// - description: AI-generated description of the issue
  /// - suggestedIssueTypes: List of suggested issue type names
  /// - severity: Suggested severity level (minor/low/moderate/high/critical)
  Future<Map<String, dynamic>> analyzeImage({
    required String imageUrl,
    String? additionalContext,
  }) async {
    try {
      final prompt = _buildImageAnalysisPrompt(additionalContext);

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
              'model': 'nvidia/nemotron-nano-12b-v2-vl:free',
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
      } else {
        throw AiException(
          'OpenRouter API error: ${response.statusCode}',
          details: response.body,
        );
      }
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('Image analysis failed: ${e.toString()}');
    }
  }

  /// Build prompt for image analysis
  String _buildImageAnalysisPrompt(String? additionalContext) {
    final basePrompt = '''
Analyze this image and identify any infrastructure or safety issues. Provide your response in the following JSON format:

{
  "description": "Brief description of what you see and the issue",
  "issueTypes": ["type1", "type2"],
  "severity": "minor|low|moderate|high|critical",
  "confidence": "low|medium|high"
}

Issue types can include: pothole, broken streetlight, damaged road, graffiti, illegal dumping, broken sidewalk, damaged signage, flooding, fallen tree, damaged fence, etc.

Severity levels:
- minor: Cosmetic issues, no immediate danger
- low: Minor inconvenience, no safety risk
- moderate: Noticeable issue, potential minor safety concern
- high: Significant issue, clear safety concern
- critical: Immediate danger, requires urgent attention
''';

    if (additionalContext != null && additionalContext.isNotEmpty) {
      return '$basePrompt\n\nAdditional context: $additionalContext';
    }

    return basePrompt;
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
