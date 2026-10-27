/// Represents a single chat message sent by either user or the AI bot
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  /// Convert ChatMessage to Gemini API Content JSON format
  Map<String, dynamic> toGeminiContent() {
    return {
      'role': isUser ? 'user' : 'model',
      'parts': [
        {'text': text}
      ]
    };
  }

  /// Convert ChatMessage to OpenAI-compatible messages format
  Map<String, dynamic> toOpenAiContent() {
    return {
      'role': isUser ? 'user' : 'assistant',
      'content': text,
    };
  }

  /// Create a copy with modified fields
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}
