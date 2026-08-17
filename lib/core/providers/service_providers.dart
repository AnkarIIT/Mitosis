import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../services/gemini_proxy_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final geminiProxyServiceProvider = Provider<GeminiProxyService>((ref) {
  return GeminiProxyService();
});
