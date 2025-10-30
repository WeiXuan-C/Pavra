import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with OpenRouter AI through Serverpod backend
class AiService {
  final String serverUrl;

  AiService({this.serverUrl = 'https://pavra-production.up.railway.app'});

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
        Uri.parse('$serverUrl/openrouter/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          if (model != null) 'model': model,
          if (maxTokens != null) 'maxTokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          return data['message'] as String? ?? '';
        } else {
          throw AiException(
            data['error'] as String? ?? 'Unknown error',
            details: data['details'] as String?,
          );
        }
      } else {
        throw AiException(
          'Server error: ${response.statusCode}',
          details: response.body,
        );
      }
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('Network error: ${e.toString()}');
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
        Uri.parse('$serverUrl/openrouter/chatWithHistory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': messages,
          if (model != null) 'model': model,
          if (maxTokens != null) 'maxTokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          return data['message'] as String? ?? '';
        } else {
          throw AiException(
            data['error'] as String? ?? 'Unknown error',
            details: data['details'] as String?,
          );
        }
      } else {
        throw AiException(
          'Server error: ${response.statusCode}',
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
        Uri.parse('$serverUrl/openrouter/getModels'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['models'] as List? ?? []);
        } else {
          throw AiException(data['error'] as String? ?? 'Unknown error');
        }
      } else {
        throw AiException('Server error: ${response.statusCode}');
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

      final response = await http.post(
        Uri.parse('$serverUrl/openrouter/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': '$prompt\n\nImage URL: $imageUrl',
          'model': 'nvidia/nemotron-nano-12b-v2-vl:free', // Vision model
          'temperature': 0.3, // Lower for more factual analysis
          'maxTokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final aiResponse = data['message'] as String? ?? '';
          return _parseImageAnalysisResponse(aiResponse);
        } else {
          throw AiException(
            data['error'] as String? ?? 'Unknown error',
            details: data['details'] as String?,
          );
        }
      } else {
        throw AiException(
          'Server error: ${response.statusCode}',
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
