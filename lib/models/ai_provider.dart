/// Supported AI Providers
enum AiProvider {
  gemini('Google Gemini', 'gemini'),
  openai('OpenAI', 'openai'),
  groq('Groq (Fast)', 'groq'),
  openrouter('OpenRouter', 'openrouter');

  final String displayName;
  final String id;

  const AiProvider(this.displayName, this.id);

  static AiProvider fromId(String id) {
    return AiProvider.values.firstWhere(
      (p) => p.id == id,
      orElse: () => AiProvider.gemini,
    );
  }

  /// Default model for this provider
  String get defaultModel {
    switch (this) {
      case AiProvider.gemini:
        return 'gemini-1.5-flash';
      case AiProvider.openai:
        return 'gpt-4o-mini';
      case AiProvider.groq:
        return 'llama-3.3-70b-versatile';
      case AiProvider.openrouter:
        return 'meta-llama/llama-3.3-70b-instruct:free';
    }
  }

  /// List of popular predefined models for dropdown selection
  List<String> get availableModels {
    switch (this) {
      case AiProvider.gemini:
        return [
          'gemini-1.5-flash',
          'gemini-1.5-pro',
          'gemini-2.0-flash',
        ];
      case AiProvider.openai:
        return [
          'gpt-4o-mini',
          'gpt-4o',
          'gpt-3.5-turbo',
        ];
      case AiProvider.groq:
        return [
          'llama-3.3-70b-versatile',
          'llama-3.1-8b-instant',
          'mixtral-8x7b-32768',
        ];
      case AiProvider.openrouter:
        return [
          'meta-llama/llama-3.3-70b-instruct:free',
          'google/gemini-2.0-flash-exp:free',
          'anthropic/claude-3.5-sonnet',
          'deepseek/deepseek-chat',
        ];
    }
  }

  /// Environment variable key name in .env file
  String get envKeyName {
    switch (this) {
      case AiProvider.gemini:
        return 'GEMINI_API_KEY';
      case AiProvider.openai:
        return 'OPENAI_API_KEY';
      case AiProvider.groq:
        return 'GROQ_API_KEY';
      case AiProvider.openrouter:
        return 'OPENROUTER_API_KEY';
    }
  }

  /// Storage key name in SharedPreferences
  String get storageKeyName {
    return 'api_key_$id';
  }

  /// Web link to acquire an API key
  String get apiKeyUrl {
    switch (this) {
      case AiProvider.gemini:
        return 'https://aistudio.google.com/app/apikey';
      case AiProvider.openai:
        return 'https://platform.openai.com/api-keys';
      case AiProvider.groq:
        return 'https://console.groq.com/keys';
      case AiProvider.openrouter:
        return 'https://openrouter.ai/keys';
    }
  }

  /// REST Endpoint
  String get endpointUrl {
    switch (this) {
      case AiProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta/models';
      case AiProvider.openai:
        return 'https://api.openai.com/v1/chat/completions';
      case AiProvider.groq:
        return 'https://api.groq.com/openai/v1/chat/completions';
      case AiProvider.openrouter:
        return 'https://openrouter.ai/api/v1/chat/completions';
    }
  }
}
