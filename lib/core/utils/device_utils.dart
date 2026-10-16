import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Device detection utilities for exam environment enforcement.
class DeviceUtils {
  DeviceUtils._();

  /// True on desktop platforms (Windows, macOS, Linux) or web.
  /// These form factors can simulate the NTA CBT environment properly.
  static bool get isDesktopOrWeb {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  /// True on mobile (Android, iOS). These form factors cannot properly
  /// simulate the NTA CBT environment (no fullscreen lock, no keyboard).
  static bool get isMobile => !isDesktopOrWeb;

  /// Whether the current platform can enforce strict exam conditions.
  static bool get canEnforceStrictMode => isDesktopOrWeb;
}
