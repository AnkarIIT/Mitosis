import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _lastAuthAttemptKey = 'last_auth_attempt';
  static const String _authFailureCountKey = 'auth_failure_count';

  /// Check if the device is potentially compromised (root/jailbreak)
  /// Note: This is a basic check. For production, use specialized packages.
  Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false;
    
    try {
      if (Platform.isAndroid) {
        final paths = [
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su'
        ];
        for (var path in paths) {
          if (File(path).existsSync()) return true;
        }
      }
    } catch (_) {}
    
    return false;
  }

  /// Rate limiting for login/OTP attempts
  Future<bool> isRateLimited() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAttempt = prefs.getInt(_lastAuthAttemptKey) ?? 0;
    final failureCount = prefs.getInt(_authFailureCountKey) ?? 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (failureCount >= 5) {
      // 5 failures: 15-minute cooldown
      if (now - lastAttempt < 15 * 60 * 1000) return true;
      // Reset if cooldown passed
      await prefs.setInt(_authFailureCountKey, 0);
    } else if (failureCount >= 3) {
      // 3 failures: 1-minute cooldown
      if (now - lastAttempt < 60 * 1000) return true;
    }
    
    return false;
  }

  Future<void> recordAuthFailure() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_authFailureCountKey) ?? 0) + 1;
    await prefs.setInt(_authFailureCountKey, count);
    await prefs.setInt(_lastAuthAttemptKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearAuthFailures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authFailureCountKey);
    await prefs.remove(_lastAuthAttemptKey);
  }
}
