import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/core/services/biometric_service.dart';
import 'package:neet_mitos/core/services/gemini_chat_service.dart';

/// Mock [BiometricStorage] for tests.
class _MockBiometricStorage implements BiometricStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({required String key}) async => _storage[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete({required String key}) async => _storage.remove(key);
}

/// Mock [BiometricService] that always reports biometrics unavailable.
class MockBiometricService extends BiometricService {
  MockBiometricService() : super.forTesting(_MockBiometricStorage());

  @override
  Future<bool> hasEnrolledBiometrics() async => false;

  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<BiometricStatus> getBiometricStatus() async =>
      BiometricStatus.unavailable;

  @override
  Future<bool> authenticate() async => false;

  @override
  Future<bool> authenticateWithDeviceCredential() async => false;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}

  @override
  Future<bool> isBiometricEnabled() async => false;
}

/// Creates a [ProviderContainer] with all secure-storage-dependent providers overridden.
ProviderContainer createTestContainer({
  List<Override> additionalOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      biometricServiceProvider.overrideWith((ref) => MockBiometricService()),
      geminiServiceProvider.overrideWith((ref) {
        final proxy = ref.watch(geminiProxyServiceProvider);
        return GeminiChatService(proxy: proxy);
      }),
      ...additionalOverrides,
    ],
  );
}
