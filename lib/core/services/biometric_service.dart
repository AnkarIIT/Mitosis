import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

enum BiometricStatus { available, enrolledButUnavailable, unavailable, error }

/// Interface for secure storage operations needed by [BiometricService].
/// Allows test doubles without platform channels.
abstract class BiometricStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class _FlutterSecureStorageAdapter implements BiometricStorage {
  final FlutterSecureStorage _storage;
  _FlutterSecureStorageAdapter(this._storage);

  @override
  Future<String?> read({required String key}) async => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) async =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) async => _storage.delete(key: key);
}

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final BiometricStorage _secureStorage;
  static const String _biometricEnabledKey = 'neet_mitos_biometric_enabled';

  BiometricService([BiometricStorage? secureStorage])
    : _secureStorage =
          secureStorage ??
          _FlutterSecureStorageAdapter(
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            ),
          );

  /// Test-only constructor that bypasses platform channels.
  BiometricService.forTesting(BiometricStorage storage)
    : _secureStorage = storage;

  /// Whether the current platform has no biometric implementation.
  bool get _isWeb => kIsWeb;

  /// Returns true if the device has at least one biometric actually enrolled
  /// (fingerprint, face, iris, etc.). This is distinct from merely supporting
  /// biometric hardware — a device with only a PIN/pattern enrolled reports no
  /// enrolled biometrics.
  Future<bool> hasEnrolledBiometrics() async {
    if (_isWeb) return false;
    try {
      final available = await _auth.getAvailableBiometrics();
      final enrolled = available.isNotEmpty;
      debugPrint('Enrolled biometrics: $available');
      return enrolled;
    } on PlatformException catch (e) {
      debugPrint('Enrolled biometrics check failed: $e');
      return false;
    } on UnsupportedError {
      // Older platforms may not expose getAvailableBiometrics; fall back to the
      // capability check which is the best signal they provide.
      return isBiometricAvailable();
    }
  }

  Future<bool> isBiometricAvailable() async {
    if (_isWeb) return false;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Returns a detailed status so the UI can explain why biometric lock is
  /// unavailable instead of silently hiding the option.
  Future<BiometricStatus> getBiometricStatus() async {
    if (_isWeb) return BiometricStatus.unavailable;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool deviceSupported = await _auth.isDeviceSupported();

      if (!canAuthenticateWithBiometrics && !deviceSupported) {
        return BiometricStatus.unavailable;
      }

      final enrolled = await hasEnrolledBiometrics();
      if (enrolled) {
        return BiometricStatus.available;
      }

      // Hardware exists but no biometric is enrolled. On Android this often
      // means only PIN/pattern is set up.
      return BiometricStatus.enrolledButUnavailable;
    } on PlatformException catch (e) {
      debugPrint('Biometric status check failed: $e');
      return BiometricStatus.error;
    }
  }

  /// Authenticate with the strongest available local credential.
  ///
  /// Uses [AuthenticationOptions.biometricOnly] = false so the OS handles
  /// the full fallback chain: biometric → device credential (PIN/pattern).
  /// The user is never stuck on a failed biometric attempt — the system
  /// prompt automatically offers the device credential as a fallback.
  ///
  /// [AuthenticationOptions.useErrorDialogs] is false because the app
  /// provides its own error UI in the lock overlay; native error dialogs
  /// would create a confusing double-error experience.
  Future<bool> authenticate() async {
    if (_isWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access NEET Mitos',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth failed: $e');
      return false;
    } catch (e) {
      debugPrint('Biometric auth cancelled/failed: $e');
      return false;
    }
  }

  Future<bool> authenticateWithDeviceCredential() async {
    if (_isWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access NEET Mitos',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Device credential auth failed: $e');
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }
}
