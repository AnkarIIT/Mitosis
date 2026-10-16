import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question_model.dart';
import 'exam_engine_service.dart';

/// A snapshot of an in-progress CBT attempt, enough to restore the *exact*
/// same paper and remaining time after the app is killed or backgrounded.
///
/// Full question snapshots are stored (not just IDs) so resume works even if
/// the question pool changes between sessions. The timer is stored as an
/// absolute wall-clock deadline (epoch ms), so remaining time is always
/// `deadline - now` regardless of how long the app was gone.
class ExamCheckpoint {
  final String attemptId;
  final Map<String, dynamic> configJson;
  final List<List<String>> sectionQuestionIds;

  /// Full question snapshots per section. Stored so resume works even if the
  /// question pool changes (questions updated/deleted) between sessions.
  final List<List<Question>> sectionQuestions;

  final Map<int, String?> answersByIndex;
  final List<int> flagged;
  final List<int> visited;
  final int currentIndex;
  final int currentSection;
  final String phase;
  final int deadlineEpochMs;
  final int? breakDeadlineEpochMs;
  final int? sectionDeadlineEpochMs;
  final int startedAtEpochMs;
  final int savedAtEpochMs;

  /// Per-question timing in seconds (index -> seconds spent).
  final Map<int, int> secondsPerQuestion;

  /// Count of proctoring violations (app switched away / backgrounded) during
  /// the active test. Persisted so they survive a crash or resume.
  final int violations;

  /// Schema version of this checkpoint. Bumped whenever the persisted shape
  /// changes so `fromJson`/[ExamCheckpointService] can migrate or safely drop
  /// stale checkpoints from an older app build.
  final int version;

  const ExamCheckpoint({
    required this.attemptId,
    required this.configJson,
    required this.sectionQuestionIds,
    required this.sectionQuestions,
    required this.answersByIndex,
    required this.flagged,
    required this.visited,
    required this.currentIndex,
    required this.currentSection,
    required this.phase,
    required this.deadlineEpochMs,
    required this.startedAtEpochMs,
    required this.savedAtEpochMs,
    this.breakDeadlineEpochMs,
    this.sectionDeadlineEpochMs,
    this.secondsPerQuestion = const {},
    this.violations = 0,
    this.version = kCurrentCheckpointVersion,
  });

  /// Current checkpoint schema version.
  static const int kCurrentCheckpointVersion = 3;

  /// The oldest checkpoint version this build can still read. Anything older
  /// is treated as incompatible and discarded by the service's `read()`.
  static const int kMinSupportedCheckpointVersion = 1;

  ExamConfig get config => ExamConfig.fromJson(configJson);

  /// Whole seconds left until the deadline at [now], clamped to ≥ 0.
  int remainingSecondsAt(DateTime now) {
    final ms = deadlineEpochMs - now.millisecondsSinceEpoch;
    return ms <= 0 ? 0 : ms ~/ 1000;
  }

  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'config': configJson,
    'sectionQuestionIds': sectionQuestionIds,
    'sectionQuestions': [
      for (final section in sectionQuestions)
        [for (final q in section) q.toJson()],
    ],
    'answers': answersByIndex.map((k, v) => MapEntry(k.toString(), v)),
    'flagged': flagged,
    'visited': visited,
    'currentIndex': currentIndex,
    'currentSection': currentSection,
    'phase': phase,
    'deadlineEpochMs': deadlineEpochMs,
    'breakDeadlineEpochMs': breakDeadlineEpochMs,
    'sectionDeadlineEpochMs': sectionDeadlineEpochMs,
    'startedAtEpochMs': startedAtEpochMs,
    'savedAtEpochMs': savedAtEpochMs,
    'violations': violations,
    'secondsPerQuestion': secondsPerQuestion.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'version': version,
  };

  factory ExamCheckpoint.fromJson(Map<String, dynamic> json) {
    // Parse section questions if present (v3+), otherwise fall back to IDs only.
    final sectionQuestionsJson = json['sectionQuestions'] as List?;
    final sectionQuestions = sectionQuestionsJson != null
        ? sectionQuestionsJson
              .map(
                (section) => (section as List)
                    .map(
                      (q) =>
                          Question.fromJson((q as Map).cast<String, dynamic>()),
                    )
                    .toList(),
              )
              .toList()
        : const <List<Question>>[];

    return ExamCheckpoint(
      attemptId: json['attemptId'] as String,
      configJson: (json['config'] as Map).cast<String, dynamic>(),
      sectionQuestionIds: (json['sectionQuestionIds'] as List)
          .map((s) => (s as List).map((e) => e as String).toList())
          .toList(),
      sectionQuestions: sectionQuestions,
      answersByIndex: (json['answers'] as Map).map(
        (k, v) => MapEntry(int.parse(k as String), v as String?),
      ),
      flagged: (json['flagged'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
      visited: (json['visited'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
      currentIndex: (json['currentIndex'] as num).toInt(),
      currentSection: (json['currentSection'] as num).toInt(),
      phase: json['phase'] as String,
      deadlineEpochMs: (json['deadlineEpochMs'] as num).toInt(),
      breakDeadlineEpochMs: (json['breakDeadlineEpochMs'] as num?)?.toInt(),
      sectionDeadlineEpochMs: (json['sectionDeadlineEpochMs'] as num?)?.toInt(),
      startedAtEpochMs: (json['startedAtEpochMs'] as num).toInt(),
      savedAtEpochMs: (json['savedAtEpochMs'] as num).toInt(),
      violations: (json['violations'] as num?)?.toInt() ?? 0,
      secondsPerQuestion:
          (json['secondsPerQuestion'] as Map?)?.map(
            (k, v) => MapEntry(int.parse(k as String), (v as num).toInt()),
          ) ??
          {},
      // Checkpoints saved before the `version` field existed default to v1.
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Persists the single active CBT checkpoint to [SharedPreferences].
///
/// Only one live mock *per user* at a time, so the key is suffixed with the
/// owner id. A single global key meant one user's in-progress mock stayed
/// visible to the next person to sign in on the same device. Chosen over a
/// Drift table: it's a transient blob, needs no migration, and mirrors how the
/// onboarding flags are already stored.
class ExamCheckpointService {
  static const String _keyPrefix = 'cbt_active_checkpoint';

  /// Owner of the checkpoint. Guest is `-1`, matching `guestOwnerId`.
  final int userId;

  ExamCheckpointService({this.userId = -1});

  String get _key => '$_keyPrefix-$userId';

  /// Maximum number of save attempts before giving up.
  static const int _maxSaveAttempts = 3;

  /// Delay between save retries.
  static const Duration _retryDelay = Duration(milliseconds: 100);

  /// Saves the checkpoint with retry logic. Returns true if the save succeeded.
  ///
  /// Retries up to [_maxSaveAttempts] times with a [_retryDelay] between
  /// attempts. This ensures that transient SharedPreferences failures don't
  /// silently lose exam progress.
  Future<bool> save(ExamCheckpoint checkpoint) async {
    final json = jsonEncode(checkpoint.toJson());
    for (int attempt = 1; attempt <= _maxSaveAttempts; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, json);
        return true;
      } catch (e) {
        if (attempt == _maxSaveAttempts) {
          debugPrint(
            'CBT checkpoint save failed after $_maxSaveAttempts attempts: $e',
          );
          return false;
        }
        await Future.delayed(_retryDelay);
      }
    }
    return false;
  }

  Future<ExamCheckpoint?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final version = (json['version'] as num?)?.toInt() ?? 1;
      // Drop checkpoints from older, incompatible schema versions.
      if (version < ExamCheckpoint.kMinSupportedCheckpointVersion) {
        await prefs.remove(_key);
        return null;
      }
      return ExamCheckpoint.fromJson(json);
    } catch (_) {
      // Corrupt/incompatible checkpoint — drop it so we don't keep failing.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<bool> hasCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return raw != null && raw.isNotEmpty;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
