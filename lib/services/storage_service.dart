import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/ai_provider.dart';

/// Service to manage persistent settings (active provider, model, and API keys)
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _prefActiveProvider = 'active_ai_provider';
  static const String _prefModelPrefix = 'active_model_';

  /// Get the active AI provider (defaults to Gemini)
  Future<AiProvider> getActiveProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerId = prefs.getString(_prefActiveProvider);
    if (providerId != null) {
      return AiProvider.fromId(providerId);
    }
    return AiProvider.gemini;
  }

  /// Set the active AI provider
  Future<void> setActiveProvider(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveProvider, provider.id);
  }

  /// Get the active model for a specific provider
  Future<String> getActiveModel(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString('$_prefModelPrefix${provider.id}');
    if (savedModel != null && savedModel.trim().isNotEmpty) {
      return savedModel.trim();
    }
    return provider.defaultModel;
  }

  /// Set the active model for a specific provider
  Future<void> setActiveModel(AiProvider provider, String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefModelPrefix${provider.id}', model.trim());
  }

  /// Retrieve the API key for a specific provider.
  /// Priority:
  /// 1. Saved key in SharedPreferences for this provider
  /// 2. If Gemini, check legacy SharedPreferences key
  /// 3. .env file key
  Future<String> getApiKeyForProvider(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Provider-specific key
    final providerKey = prefs.getString(provider.storageKeyName);
    if (providerKey != null && providerKey.trim().isNotEmpty) {
      return providerKey.trim();
    }

    // 2. Legacy Gemini key fallback
    if (provider == AiProvider.gemini) {
      final legacyKey = prefs.getString(ApiConstants.prefApiKey);
      if (legacyKey != null && legacyKey.trim().isNotEmpty) {
        return legacyKey.trim();
      }
    }

    // 3. .env variable
    final envKey = dotenv.env[provider.envKeyName];
    if (envKey != null && envKey.trim().isNotEmpty) {
      return envKey.trim();
    }

    return '';
  }

  /// Save API key for a specific provider
  Future<void> saveApiKeyForProvider(AiProvider provider, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(provider.storageKeyName, key.trim());
    if (provider == AiProvider.gemini) {
      await prefs.setString(ApiConstants.prefApiKey, key.trim());
    }
  }

  /// Clear API key for a specific provider
  Future<void> clearApiKeyForProvider(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(provider.storageKeyName);
    if (provider == AiProvider.gemini) {
      await prefs.remove(ApiConstants.prefApiKey);
    }
  }

  /// Convenience method for the currently active provider's API key
  Future<String> getApiKey() async {
    final activeProvider = await getActiveProvider();
    return getApiKeyForProvider(activeProvider);
  }

  /// Check if the currently active provider has an API key configured
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key.isNotEmpty;
  }
}
