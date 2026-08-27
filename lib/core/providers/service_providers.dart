import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../models/batch_model.dart';
import '../services/gemini_proxy_service.dart';
import '../services/batch_service.dart';
import '../services/exam_checkpoint_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final geminiProxyServiceProvider = Provider<GeminiProxyService?>((ref) {
  if (!AppConfig.enableAiProxy) return null;
  return GeminiProxyService();
});

final batchServiceProvider = StateNotifierProvider<BatchService, UserBatch?>((ref) {
  return BatchService();
});

final examCheckpointServiceProvider = Provider<ExamCheckpointService>((ref) {
  return ExamCheckpointService();
});

/// Presence + payload of an in-progress CBT attempt, backing the "Resume Mock
/// Test" card. Invalidate after a test is submitted or discarded to refresh.
final activeCbtCheckpointProvider =
    FutureProvider<ExamCheckpoint?>((ref) async {
  final service = ref.watch(examCheckpointServiceProvider);
  return service.read();
});
