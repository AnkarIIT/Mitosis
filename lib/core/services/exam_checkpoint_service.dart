import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'exam_engine_service.dart';

/// A snapshot of an in-progress CBT attempt, enough to restore the *exact*
/// same paper and remaining time after the app is killed or backgrounded.
///
/// The allocated question IDs are stored (not a re-run of the randomised
/// allocator) so resume reconstructs the identical question set. The timer is
/// stored as an absolute wall-clock deadline (epoch ms), so remaining time is
/// always `deadline - now` regardless of how long the app was gone.
class ExamCheckpoint {
  final String attemptId;
  final Map<String, dynamic> configJson;
  final List<List<String>> sectionQuestionIds;
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

  const ExamCheckpoint({
    required this.attemptId,
    required this.configJson,
    required this.sectionQuestionIds,
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
  });

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
      };

  factory ExamCheckpoint.fromJson(Map<String, dynamic> json) => ExamCheckpoint(
        attemptId: json['attemptId'] as String,
        configJson: (json['config'] as Map).cast<String, dynamic>(),
        sectionQuestionIds: (json['sectionQuestionIds'] as List)
            .map((s) => (s as List).map((e) => e as String).toList())
            .toList(),
        answersByIndex: (json['answers'] as Map).map(
          (k, v) => MapEntry(int.parse(k as String), v as String?),
        ),
        flagged:
            (json['flagged'] as List).map((e) => (e as num).toInt()).toList(),
        visited:
            (json['visited'] as List).map((e) => (e as num).toInt()).toList(),
        currentIndex: (json['currentIndex'] as num).toInt(),
        currentSection: (json['currentSection'] as num).toInt(),
        phase: json['phase'] as String,
        deadlineEpochMs: (json['deadlineEpochMs'] as num).toInt(),
        breakDeadlineEpochMs:
            (json['breakDeadlineEpochMs'] as num?)?.toInt(),
        sectionDeadlineEpochMs:
            (json['sectionDeadlineEpochMs'] as num?)?.toInt(),
        startedAtEpochMs: (json['startedAtEpochMs'] as num).toInt(),
        savedAtEpochMs: (json['savedAtEpochMs'] as num).toInt(),
      );
}

/// Persists the single active CBT checkpoint to [SharedPreferences].
///
/// Only one live mock at a time, so a single key is used. Chosen over a Drift
/// table: it's a transient blob, needs no migration, and mirrors how the
/// onboarding flags are already stored.
class ExamCheckpointService {
  static const String _key = 'cbt_active_checkpoint';

  Future<void> save(ExamCheckpoint checkpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(checkpoint.toJson()));
  }

  Future<ExamCheckpoint?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
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
