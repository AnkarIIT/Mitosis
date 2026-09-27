import 'package:flutter/services.dart';

/// Toggles Android's [WindowManager.LayoutParams.FLAG_SECURE] so that the
/// active NTA-style CBT screen cannot be captured by screenshots or screen
/// recording. On iOS this is a no-op (the native side is Android-only).
class SecureScreenService {
  static const MethodChannel _channel = MethodChannel('neet_mitos/security');

  /// Blocks screenshots / screen recording for the current activity window.
  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': true});
    } on PlatformException catch (e) {
      // No-op on platforms without the native handler (e.g. iOS/tests).
      assert(() {
        // ignore: avoid_print
        print('SecureScreenService.enable unsupported: ${e.message}');
        return true;
      }());
    } on MissingPluginException {
      // Native bridge absent — silently ignore.
    }
  }

  /// Re-enables screenshotting after the exam flow is left.
  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': false});
    } on PlatformException catch (e) {
      assert(() {
        // ignore: avoid_print
        print('SecureScreenService.disable unsupported: ${e.message}');
        return true;
      }());
    } on MissingPluginException {
      // Native bridge absent — silently ignore.
    }
  }
}
