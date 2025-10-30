import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

/// OpenRouter AI endpoint for chat completions
class OpenRouterEndpoint extends Endpoint {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Get a random API key from the available keys
  String _getRandomApiKey() {
    final keys = <String>[];

    // Load all available keys from environment
    for (int i = 1; i <= 20; i++) {
      final key = Platform.environment['OPEN_ROUTER_KEY_$i'];
      if (key != null && key.isNotEmpty) {
        keys.add(key);
      }
    }

    if (keys.isEmpty) {
      throw Exception('No OpenRouter API keys found in environment variables');
    }

    // Return a random key for load balancing
    final random = Random();
    return keys[random.nextInt(keys.length)];
  }

  /// Get environment variable value
  String? _getEnv(String key) {
    return Platform.environment[key];
  }

  /// Send a chat completion request to OpenRouter
  ///
  /// [prompt] - The user's message/prompt
  /// [model] - The AI model to use (default: nvidia/nemotron-nano-12b-v2-vl:free)
  /// [maxTokens] - Maximum tokens in response (default: 1000)
  /// [temperature] - Sampling temperature 0-2 (default: 0.7)
  Future<Map<String, dynamic>> chat({
    required Session session,
    required String prompt,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    try {
      final apiKey = _getRandomApiKey();
      final selectedModel = model ??
          _getEnv('OPEN_ROUTER_DETECTION_MODEL') ??
          'nvidia/nemotron-nano-12b-v2-vl:free';

      session.log('Sending request to OpenRouter with model: $selectedModel');

      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': _getEnv('SERVERPOD_URL') ??
              'https://pavra-production.up.railway.app',
          'X-Title': 'Pavra App',
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': maxTokens ?? 1000,
          'temperature': temperature ?? 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        session.log('OpenRouter response received successfully');

        return {
          'success': true,
          'data': data,
          'message': _extractMessage(data),
          'model': selectedModel,
        };
      } else {
        session.log(
            'OpenRouter API error: ${response.statusCode} - ${response.body}',
            level: LogLevel.error);

        return {
          'success': false,
          'error': 'API request failed with status ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e, stackTrace) {
      session.log('Exception in OpenRouter chat: $e', level: LogLevel.error);
      session.log('Stack trace: $stackTrace', level: LogLevel.error);

      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}',
      };
    }
  }

  /// Send a chat completion with conversation history
  ///
  /// [messages] - List of message maps with 'role' and 'content' keys
  /// [model] - The AI model to use
  /// [maxTokens] - Maximum tokens in response
  /// [temperature] - Sampling temperature 0-2
  Future<Map<String, dynamic>> chatWithHistory({
    required Session session,
    required List<Map<String, dynamic>> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    try {
      final apiKey = _getRandomApiKey();
      final selectedModel = model ??
          _getEnv('OPEN_ROUTER_DETECTION_MODEL') ??
          'nvidia/nemotron-nano-12b-v2-vl:free';

      session.log(
          'Sending conversation to OpenRouter with ${messages.length} messages');

      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': _getEnv('SERVERPOD_URL') ??
              'https://pavra-production.up.railway.app',
          'X-Title': 'Pavra App',
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': messages,
          'max_tokens': maxTokens ?? 1000,
          'temperature': temperature ?? 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'data': data,
          'message': _extractMessage(data),
          'model': selectedModel,
        };
      } else {
        session.log('OpenRouter API error: ${response.statusCode}',
            level: LogLevel.error);

        return {
          'success': false,
          'error': 'API request failed with status ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e, stackTrace) {
      session.log('Exception in OpenRouter chatWithHistory: $e',
          level: LogLevel.error);
      session.log('Stack trace: $stackTrace', level: LogLevel.error);

      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}',
      };
    }
  }

  /// Extract the message content from OpenRouter response
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

  /// Send a chat completion with vision (image analysis)
  ///
  /// [textPrompt] - The text prompt/question about the image
  /// [imageUrl] - Public URL of the image to analyze
  /// [model] - The AI model to use (must support vision)
  /// [maxTokens] - Maximum tokens in response
  /// [temperature] - Sampling temperature 0-2
  Future<Map<String, dynamic>> chatWithVision({
    required Session session,
    required String textPrompt,
    required String imageUrl,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    try {
      final apiKey = _getRandomApiKey();
      final selectedModel = model ??
          _getEnv('OPEN_ROUTER_DETECTION_MODEL') ??
          'nvidia/nemotron-nano-12b-v2-vl:free';

      session.log(
          'Sending vision request to OpenRouter with model: $selectedModel');
      session.log('Image URL: $imageUrl');

      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': _getEnv('SERVERPOD_URL') ??
              'https://pavra-production.up.railway.app',
          'X-Title': 'Pavra App',
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': textPrompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': imageUrl,
                  }
                }
              ]
            }
          ],
          'max_tokens': maxTokens ?? 500,
          'temperature': temperature ?? 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        session.log('OpenRouter vision response received successfully');

        return {
          'success': true,
          'data': data,
          'message': _extractMessage(data),
          'model': selectedModel,
        };
      } else {
        session.log(
            'OpenRouter API error: ${response.statusCode} - ${response.body}',
            level: LogLevel.error);

        return {
          'success': false,
          'error': 'API request failed with status ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e, stackTrace) {
      session.log('Exception in OpenRouter chatWithVision: $e',
          level: LogLevel.error);
      session.log('Stack trace: $stackTrace', level: LogLevel.error);

      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}',
      };
    }
  }

  /// Get available models from OpenRouter
  Future<Map<String, dynamic>> getModels({
    required Session session,
  }) async {
    try {
      final apiKey = _getRandomApiKey();

      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'models': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch models: ${response.statusCode}',
        };
      }
    } catch (e) {
      session.log('Exception in getModels: $e', level: LogLevel.error);

      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}',
      };
    }
  }
}
