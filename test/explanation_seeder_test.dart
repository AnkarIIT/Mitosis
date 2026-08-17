import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/services/explanation_seeder.dart';
import 'package:neet_mitos/core/services/gemini_proxy_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Question _q(int id, {String? explanation}) {
  return Question(
    id: id,
    subject: 'Biology',
    chapter: 'The Living World',
    topic: 'Taxonomy',
    topicId: 't_$id',
    questionText: 'Which of the following is used for hierarchical classification?',
    options: const ['A. Systematics', 'B. Cladistics', 'C. Numerical taxonomy', 'D. Phylogenetics'],
    correctAnswer: 'B',
    explanation: explanation,
    difficulty: 'Medium',
    tags: const [],
    type: 'mcq',
  );
}

void main() {
  // ---- helpers ----

  GeminiProxyService makeProxy(Map<String, dynamic> response) {
    return GeminiProxyService(
      invoker: (name, {body}) async => response,
      configured: true,
    );
  }

  GeminiProxyService makeProxySequence(List<Map<String, dynamic>> responses) {
    var idx = 0;
    return GeminiProxyService(
      invoker: (name, {body}) async {
        if (idx < responses.length) return responses[idx++];
        return {'source': 'cache', 'response': 'fallback'};
      },
      configured: true,
    );
  }

  // ---- tests ----

  group('ExplanationSeeder.seedAll', () {
    test('skips questions that already have an explanation', () async {
      final questions = [_q(1, explanation: 'Already explained'), _q(2)];
      var updatedIds = <int>[];

      final seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (id, _) async { updatedIds.add(id); },
        proxy: makeProxy({'source': 'gemini', 'response': 'Generated explanation text here.'}),
      );

      final result = await seeder.seedAll();

      expect(result.total, 1);
      expect(result.generated, 1);
      expect(updatedIds, [2]);
    });

    test('forceRefresh regenerates all explanations', () async {
      final questions = [_q(1, explanation: 'Old explanation'), _q(2)];
      var updatedIds = <int>[];

      final seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (id, _) async { updatedIds.add(id); },
        proxy: makeProxy({'source': 'gemini', 'response': 'Fresh explanation text here.'}),
      );

      final result = await seeder.seedAll(forceRefresh: true);

      expect(result.total, 2);
      expect(updatedIds, [1, 2]);
    });

    test('rejects responses that are too short', () async {
      final questions = [_q(1)];
      var updated = false;

      final seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (_, _) async { updated = true; },
        proxy: makeProxy({'source': 'gemini', 'response': 'Too short'}),
      );

      final result = await seeder.seedAll();

      expect(result.generated, 0);
      expect(result.failed, 1);
      expect(updated, isFalse);
    });

    test('rejects responses that start with "Error:"', () async {
      final questions = [_q(1)];

      final seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (_, _) async {},
        proxy: makeProxy({'source': 'gemini', 'response': 'Error: something went wrong'}),
      );

      final result = await seeder.seedAll();

      expect(result.generated, 0);
      expect(result.failed, 1);
    });

    test('retries on error and succeeds on second attempt', () async {
      final questions = [_q(1)];
      var updated = false;

      final seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (_, _) async { updated = true; },
        proxy: makeProxySequence([
          {'source': 'gemini', 'response': 'Error: transient failure'},
          {'source': 'gemini', 'response': 'Valid explanation generated here with enough text.'},
        ]),
        maxRetries: 1,
      );

      final result = await seeder.seedAll();

      expect(result.generated, 1);
      expect(updated, isTrue);
    });

    test('stops early on rate limit', () async {
      final questions = [_q(1), _q(2), _q(3)];
      final updatedIds = <int>[];
      var callCount = 0;

      final seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (id, _) async { updatedIds.add(id); },
        proxy: GeminiProxyService(
          configured: true,
          invoker: (name, {body}) async {
            callCount++;
            if (callCount == 1) {
              return {'source': 'gemini', 'response': 'Valid explanation for question one.'};
            }
            throw const FunctionException(status: 429);
          },
        ),
        delayBetweenRequests: Duration.zero,
      );

      final result = await seeder.seedAll();

      expect(result.generated, 1);
      expect(result.rateLimited, 1);
      expect(updatedIds, [1]);
    });

    test('progress callback is invoked for each question', () async {
      final questions = [_q(1), _q(2)];
      final progressLog = <(int, int)>[];

      final seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (_, _) async {},
        proxy: makeProxy({'source': 'cache', 'response': 'Cached explanation text here.'}),
        delayBetweenRequests: Duration.zero,
        onProgress: (done, total) => progressLog.add((done, total)),
      );

      await seeder.seedAll();

      expect(progressLog, isNotEmpty);
      expect(progressLog.last.$1, progressLog.last.$2);
    });

    test('cancel stops the seeder early', () async {
      final questions = [_q(1), _q(2), _q(3)];
      final updatedIds = <int>[];

      late ExplanationSeeder seeder;
      seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (id, _) async {
          updatedIds.add(id);
          if (id == 1) seeder.cancel();
        },
        proxy: makeProxy({'source': 'gemini', 'response': 'Explanation text generated for question.'}),
        delayBetweenRequests: Duration.zero,
      );

      final result = await seeder.seedAll();

      expect(updatedIds.length, lessThanOrEqualTo(2));
      expect(result.isComplete, isFalse);
    });

    test('returns all zeros when nothing needs explanation', () async {
      final questions = [
        _q(1, explanation: 'Already has one'),
        _q(2, explanation: 'Also done'),
      ];

      final seeder = ExplanationSeeder(
        getQuestions: () async => questions,
        updateExplanation: (_, _) async {},
        proxy: makeProxy({'source': 'cache', 'response': 'x'}),
      );

      final result = await seeder.seedAll();

      expect(result.total, 0);
      expect(result.isComplete, isTrue);
    });
  });
}
