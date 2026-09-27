import 'dart:math';
import 'exam_engine_service.dart';

class SubjectAnalytics {
  final String subject;
  final int correct;
  final int incorrect;
  final int unanswered;
  final double averageTimeSeconds;

  const SubjectAnalytics({
    required this.subject,
    required this.correct,
    required this.incorrect,
    required this.unanswered,
    required this.averageTimeSeconds,
  });

  int get attempted => correct + incorrect;

  double get accuracy => attempted == 0 ? 0 : (correct / attempted) * 100;
}

class WeakTopic {
  final String topicId;
  final String topic;
  final String chapter;
  final int attempted;
  final int correct;
  final double accuracy;

  const WeakTopic({
    required this.topicId,
    required this.topic,
    required this.chapter,
    required this.attempted,
    required this.correct,
    required this.accuracy,
  });
}

class TestAnalytics {
  final ExamScore score;
  final double averageTimePerQuestion;
  final Map<String, SubjectAnalytics> subjects;
  final List<WeakTopic> weakTopics;
  final double percentileEstimate;
  final int airEstimate;

  /// Whether a percentile/AIR estimate should be shown. Only true for
  /// full-length mocks — short practice tests carry too little signal.
  final bool showRankEstimate;

  const TestAnalytics({
    required this.score,
    required this.averageTimePerQuestion,
    required this.subjects,
    required this.weakTopics,
    required this.percentileEstimate,
    required this.airEstimate,
    this.showRankEstimate = false,
  });
}

class TestAnalyticsService {
  static const double _neetApplicants = 2400000;

  static const List<MapEntry<double, double>> _percentileAnchors = [
    MapEntry(720, 99.99),
    MapEntry(700, 99.95),
    MapEntry(650, 98.5),
    MapEntry(600, 95.0),
    MapEntry(550, 89.0),
    MapEntry(500, 80.0),
    MapEntry(450, 68.0),
    MapEntry(400, 55.0),
    MapEntry(350, 42.0),
    MapEntry(300, 30.0),
    MapEntry(250, 20.0),
    MapEntry(200, 13.0),
    MapEntry(150, 8.0),
    MapEntry(100, 4.5),
    MapEntry(50, 2.0),
    MapEntry(0, 0.5),
  ];

  static TestAnalytics compute({
    required ExamScore score,
    required List<int> secondsPerQuestion,
  }) {
    final normalized = secondsPerQuestion.length == score.results.length
        ? secondsPerQuestion
        : List<int>.filled(score.results.length, 0);

    // Group by section name (Physics/Chemistry/Botany/Zoology) so Biology
    // splits into its two sections; fall back to the raw question subject when
    // no section mapping is available (e.g. a mixed practice test).
    final subjects = <String, SubjectAnalytics>{};
    final byGroupTime = <String, List<int>>{};
    for (int i = 0; i < score.results.length; i++) {
      final r = score.results[i];
      final key = _groupKey(score, i);
      byGroupTime.putIfAbsent(key, () => []).add(normalized[i]);
      final entry =
          subjects[key] ??
          SubjectAnalytics(
            subject: key,
            correct: 0,
            incorrect: 0,
            unanswered: 0,
            averageTimeSeconds: 0,
          );
      subjects[key] = SubjectAnalytics(
        subject: key,
        correct: entry.correct + (r.isCorrect ? 1 : 0),
        incorrect: entry.incorrect + (r.isIncorrect ? 1 : 0),
        unanswered: entry.unanswered + (r.isUnanswered ? 1 : 0),
        averageTimeSeconds: 0,
      );
    }

    for (final key in subjects.keys.toList()) {
      final times = byGroupTime[key] ?? [];
      final totalTime = times.fold(0, (a, b) => a + b);
      final old = subjects[key]!;
      subjects[key] = SubjectAnalytics(
        subject: key,
        correct: old.correct,
        incorrect: old.incorrect,
        unanswered: old.unanswered,
        averageTimeSeconds: times.isEmpty ? 0 : totalTime / times.length,
      );
    }

    final avgTime = score.results.isEmpty
        ? 0.0
        : normalized.fold(0, (a, b) => a + b) / normalized.length;

    // Rank estimate is only defensible for a full-length mock.
    final showRank = score.config.isFullLengthMock;
    final percentile = showRank
        ? estimatePercentile(score.rawScore, score.maxScore)
        : 0.0;
    final air = showRank ? estimateAir(percentile) : 0;

    return TestAnalytics(
      score: score,
      averageTimePerQuestion: avgTime,
      subjects: subjects,
      weakTopics: findWeakTopics(score),
      percentileEstimate: percentile,
      airEstimate: air,
      showRankEstimate: showRank,
    );
  }

  /// The breakdown group for result [i]: the section name when the score
  /// carries a section mapping, else the raw question subject.
  static String _groupKey(ExamScore score, int i) {
    if (score.sectionIndexByResult.length == score.results.length) {
      final sIdx = score.sectionIndexByResult[i];
      if (sIdx >= 0 && sIdx < score.config.sections.length) {
        return score.config.sections[sIdx].name;
      }
    }
    return score.results[i].question.subject;
  }

  static double estimatePercentile(int rawScore, int maxScore) {
    final equivalent = maxScore <= 0 ? 0.0 : (rawScore / maxScore) * 720;
    final clamped = equivalent.clamp(0.0, 720.0).toDouble();

    if (_percentileAnchors.isEmpty) return 0;
    if (clamped >= _percentileAnchors.first.key) {
      return _percentileAnchors.first.value;
    }
    if (clamped <= _percentileAnchors.last.key) {
      return _percentileAnchors.last.value;
    }
    for (int i = 0; i < _percentileAnchors.length - 1; i++) {
      final high = _percentileAnchors[i];
      final low = _percentileAnchors[i + 1];
      if (clamped <= high.key && clamped >= low.key) {
        final t = (clamped - low.key) / (high.key - low.key);
        return low.value + t * (high.value - low.value);
      }
    }
    return 0;
  }

  static int estimateAir(double percentile) {
    final rank = ((1 - percentile / 100) * _neetApplicants);
    return max(1, rank.round());
  }

  static List<WeakTopic> findWeakTopics(ExamScore score) {
    final groups = <String, List<QuestionResult>>{};
    for (final r in score.results) {
      if (r.isUnanswered) continue;
      groups.putIfAbsent(r.question.topicId, () => []).add(r);
    }

    final weak = <WeakTopic>[];
    groups.forEach((topicId, results) {
      final correct = results.where((r) => r.isCorrect).length;
      final accuracy = (correct / results.length) * 100;
      if (accuracy < 60) {
        final first = results.first.question;
        weak.add(
          WeakTopic(
            topicId: topicId,
            topic: first.topic,
            chapter: first.chapter,
            attempted: results.length,
            correct: correct,
            accuracy: accuracy,
          ),
        );
      }
    });

    weak.sort((a, b) {
      final byAccuracy = a.accuracy.compareTo(b.accuracy);
      if (byAccuracy != 0) return byAccuracy;
      return b.attempted.compareTo(a.attempted);
    });

    return weak.take(5).toList();
  }
}
