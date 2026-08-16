import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service to store and retrieve sensitive data securely
/// Uses platform-level encryption (Keychain on iOS, Keystore on Android)
class SecureStorageService {
  static const String _geminiApiKeyKey = 'gemini_api_key';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            resetOnError: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // ============================================================================
  // Gemini API Key Management
  // ============================================================================

  /// Save Gemini API key securely to encrypted storage
  Future<void> saveGeminiApiKey(String key) async {
    try {
      final cleaned = key.replaceAll('\n', '').replaceAll('\r', '').trim();
      await _storage.write(key: _geminiApiKeyKey, value: cleaned);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to save API key: $e');
      rethrow;
    }
  }

  /// Retrieve Gemini API key from secure storage
  Future<String?> getGeminiApiKey() async {
    try {
      return await _storage.read(key: _geminiApiKeyKey);
    } catch (e) {
      return null;
    }
  }

  /// Delete Gemini API key from secure storage
  Future<void> deleteGeminiApiKey() async {
    try {
      await _storage.delete(key: _geminiApiKeyKey);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if Gemini API key exists
  Future<bool> hasGeminiApiKey() async {
    final key = await _storage.read(key: _geminiApiKeyKey);
    return key != null && key.isNotEmpty;
  }
}
