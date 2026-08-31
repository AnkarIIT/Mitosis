import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../models/batch_model.dart';
import '../services/gemini_proxy_service.dart';
import '../services/gemini_chat_service.dart';
import '../services/google_auth_service.dart';
import '../services/batch_service.dart';
import '../services/exam_checkpoint_service.dart';
import '../services/pyq_downloader_service.dart';
import '../services/quiz_session_service.dart';
import '../services/question_generation_service.dart';
import '../services/dpp_streak_service.dart';
import '../services/exam_blueprint_service.dart';
import '../database/question_repository.dart';
import '../services/auth_service.dart';
import 'core_providers.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final database = ref.watch(databaseProvider);
  return AuthService(database);
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final database = ref.watch(databaseProvider);
  return GoogleAuthService(database);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final geminiProxyServiceProvider = Provider<GeminiProxyService?>((ref) {
  if (!AppConfig.enableAiProxy) return null;
  return GeminiProxyService();
});

final batchServiceProvider = StateNotifierProvider<BatchService, UserBatch?>((
  ref,
) {
  return BatchService();
});

final examCheckpointServiceProvider = Provider<ExamCheckpointService>((ref) {
  return ExamCheckpointService();
});

/// Presence + payload of an in-progress CBT attempt, backing the "Resume Mock
/// Test" card. Invalidate after a test is submitted or discarded to refresh.
final activeCbtCheckpointProvider = FutureProvider<ExamCheckpoint?>((
  ref,
) async {
  final service = ref.watch(examCheckpointServiceProvider);
  return service.read();
});

final pyqDownloaderProvider = Provider<PyqDownloaderService>((ref) {
  final database = ref.watch(databaseProvider);
  final repo = QuestionRepository(database);
  return PyqDownloaderService(repo);
});

final quizSessionServiceProvider = Provider<QuizSessionService>((ref) {
  final database = ref.watch(databaseProvider);
  return QuizSessionService(database);
});

final questionGenerationServiceProvider = Provider<QuestionGenerationService?>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return QuestionGenerationService(gemini);
});

final dppStreakServiceProvider = Provider<DppStreakService>((ref) {
  final database = ref.watch(databaseProvider);
  return DppStreakService(database);
});

final examBlueprintServiceProvider = Provider<ExamBlueprintService>((ref) {
  return ExamBlueprintService();
});
