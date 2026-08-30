import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage;
  static const String _biometricEnabledKey = 'neet_mitos_biometric_enabled';

  BiometricService([FlutterSecureStorage? secureStorage])
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      // First check if biometric is actually available
      final available = await isBiometricAvailable();
      if (!available) {
        debugPrint('Biometric not available, falling back to device credential');
        return await authenticateWithDeviceCredential();
      }

      return await _auth.authenticate(
        localizedReason: 'Authenticate to access NEET Mitos',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth failed: $e');
      // Fallback to device credential (PIN/pattern)
      return await authenticateWithDeviceCredential();
    }
  }

  Future<bool> authenticateWithDeviceCredential() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access NEET Mitos',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
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
