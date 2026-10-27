import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';
import '../models/chat_message.dart';
import 'storage_service.dart';

/// Exception thrown when an AI API encounters an issue
class ChatApiException implements Exception {
  final String message;
  final int? statusCode;

  ChatApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

// Retain alias for backward compatibility
typedef GeminiApiException = ChatApiException;

/// Multi-provider AI Chat Service
class ChatService {
  final StorageService _storageService = StorageService();

  /// Send prompt with conversation history to the currently active provider & model
  Future<String> sendMessage({
    required String prompt,
    required List<ChatMessage> history,
  }) async {
    final provider = await _storageService.getActiveProvider();
    final model = await _storageService.getActiveModel(provider);
    final apiKey = await _storageService.getApiKeyForProvider(provider);

    if (apiKey.isEmpty) {
      throw ChatApiException(
        'API Key is missing for ${provider.displayName}. Please configure your API key in Settings.',
      );
    }

    if (provider == AiProvider.gemini) {
      return _sendGeminiMessage(prompt, history, model, apiKey);
    } else {
      return _sendOpenAiCompatibleMessage(provider, prompt, history, model, apiKey);
    }
  }

  /// Handles Google Gemini API
  Future<String> _sendGeminiMessage(
    String prompt,
    List<ChatMessage> history,
    String model,
    String apiKey,
  ) async {
    final url = Uri.parse(
      '${AiProvider.gemini.endpointUrl}/$model:generateContent?key=$apiKey',
    );

    final validHistory = history.where((msg) => !msg.isError).toList();
    final List<Map<String, dynamic>> contents = [];

    final recentTurns = validHistory.length > 10
        ? validHistory.sublist(validHistory.length - 10)
        : validHistory;

    for (final message in recentTurns) {
      contents.add(message.toGeminiContent());
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ]
    });

    final requestBody = jsonEncode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1000,
      },
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCandidate = candidates.first as Map<String, dynamic>;
          final content = firstCandidate['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;

          if (parts != null && parts.isNotEmpty) {
            final text = parts.first['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
        return 'No response text received from Gemini.';
      } else {
        final error = decoded['error'] as Map<String, dynamic>?;
        final errorMessage = error?['message'] as String? ?? 'Unknown error occurred.';

        if (response.statusCode == 400 || response.statusCode == 403) {
          throw ChatApiException(
            'Invalid API Key or permission denied: $errorMessage',
            response.statusCode,
          );
        } else if (response.statusCode == 429) {
          throw ChatApiException(
            'Gemini API rate limit reached. Please wait a moment and try again.',
            response.statusCode,
          );
        } else {
          throw ChatApiException(
            'Gemini error (${response.statusCode}): $errorMessage',
            response.statusCode,
          );
        }
      }
    } on http.ClientException catch (e) {
      throw ChatApiException('Network connection failed: ${e.message}');
    } catch (e) {
      if (e is ChatApiException) rethrow;
      throw ChatApiException('Unexpected error: $e');
    }
  }

  /// Handles OpenAI, Groq, and OpenRouter (OpenAI-compatible chat completion APIs)
  Future<String> _sendOpenAiCompatibleMessage(
    AiProvider provider,
    String prompt,
    List<ChatMessage> history,
    String model,
    String apiKey,
  ) async {
    final url = Uri.parse(provider.endpointUrl);

    final validHistory = history.where((msg) => !msg.isError).toList();
    final List<Map<String, dynamic>> messages = [];

    final recentTurns = validHistory.length > 10
        ? validHistory.sublist(validHistory.length - 10)
        : validHistory;

    for (final message in recentTurns) {
      messages.add(message.toOpenAiContent());
    }

    messages.add({
      'role': 'user',
      'content': prompt,
    });

    final requestBody = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 1000,
    });

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    if (provider == AiProvider.openrouter) {
      headers['HTTP-Referer'] = 'https://flutter.dev';
      headers['X-Title'] = 'Flutter Chatbot';
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final choices = decoded['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices.first as Map<String, dynamic>;
          final message = firstChoice['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;

          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
        return 'No response text received from ${provider.displayName}.';
      } else {
        final error = decoded['error'];
        String errorMessage = 'Unknown error';
        if (error is Map<String, dynamic>) {
          errorMessage = error['message']?.toString() ?? 'Error occurred.';
        } else if (error is String) {
          errorMessage = error;
        }

        if (response.statusCode == 401) {
          throw ChatApiException(
            'Invalid API Key for ${provider.displayName}: $errorMessage',
            response.statusCode,
          );
        } else if (response.statusCode == 429) {
          throw ChatApiException(
            'Rate limit reached for ${provider.displayName}. Please wait a moment.',
            response.statusCode,
          );
        } else {
          throw ChatApiException(
            '${provider.displayName} API error (${response.statusCode}): $errorMessage',
            response.statusCode,
          );
        }
      }
    } on http.ClientException catch (e) {
      throw ChatApiException('Network connection failed: ${e.message}');
    } catch (e) {
      if (e is ChatApiException) rethrow;
      throw ChatApiException('Unexpected error: $e');
    }
  }
}

// Maintain GeminiService class for backward compatibility
class GeminiService extends ChatService {}
