/// API & Network constants for the chatbot
class ApiConstants {
  /// Default Gemini model to use
  static const String geminiModel = 'gemini-1.5-flash';

  /// Google Generative Language API endpoint
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Key name used in the .env file
  static const String envApiKeyName = 'GEMINI_API_KEY';

  /// Key name used for persistent local storage (shared_preferences)
  static const String prefApiKey = 'user_gemini_api_key';

  /// Helpful link to obtain API key
  static const String getApiKeyUrl = 'https://aistudio.google.com/app/apikey';
}
