import 'package:flutter/foundation.dart';

import '../models/question_model.dart';
import 'gemini_proxy_service.dart';

// =============================================================================
//  ExplanationSeeder — batch-fills `explanation` for questions missing one
// =============================================================================
//  Uses the gemini-proxy service (T2/T3) so cache hits are free and the
//  per-user rate limit is automatically enforced.
//
//  The seeder is naturally *resumable*: it only picks up questions whose
//  explanation is still null/empty, so re-running after a partial failure
//  (rate-limit, network error) continues where it left off.
//
//  Typical usage:
//    final seeder = ExplanationSeeder(
//      getQuestions: repository.getAllQuestionsFromDb,
//      updateExplanation: repository.updateQuestionExplanation,
//      proxy: GeminiProxyService(),
//    );
//    final result = await seeder.seedAll();
// =============================================================================

/// Result returned by [ExplanationSeeder.seedAll].
class SeederResult {
  const SeederResult({
    required this.total,
    required this.generated,
    required this.failed,
    required this.rateLimited,
  });

  /// Questions that were missing an explanation at the start of the run.
  final int total;

  /// Successfully generated and stored.
  final int generated;

  /// Failed validation or returned an error from the proxy.
  final int failed;

  /// Stopped early because the proxy returned 429 (rate-limited).
  final int rateLimited;

  bool get isComplete => generated + failed >= total;
}

typedef GetQuestions = Future<List<Question>> Function();
typedef UpdateExplanation =
    Future<void> Function(String questionId, String explanation);

class ExplanationSeeder {
  ExplanationSeeder({
    required this.getQuestions,
    required this.updateExplanation,
    this.proxy,
    this.onProgress,
    this.delayBetweenRequests = const Duration(seconds: 2),
    this.maxRetries = 2,
  });

  final GetQuestions getQuestions;
  final UpdateExplanation updateExplanation;
  final GeminiProxyService? proxy;
  final void Function(int completed, int total)? onProgress;
  final Duration delayBetweenRequests;
  final int maxRetries;

  bool _cancelled = false;

  /// Cancels the current [seedAll] run after the in-flight request completes.
  void cancel() => _cancelled = true;

  // --------------------------------------------------------------------------
  // Public
  // --------------------------------------------------------------------------

  /// Iterates every active question missing an explanation, generates one
  /// via the proxy, and writes it to the local database.
  Future<SeederResult> seedAll({bool forceRefresh = false}) async {
    final effectiveProxy = proxy;
    if (effectiveProxy == null || !effectiveProxy.isConfigured) {
      return const SeederResult(
        total: 0,
        generated: 0,
        failed: 0,
        rateLimited: 0,
      );
    }
    _cancelled = false;
    final all = await getQuestions();
    final needsExplanation = forceRefresh
        ? all
        : all.where((q) => _needsExplanation(q)).toList();

    var generated = 0;
    var failed = 0;
    var rateLimited = 0;

    for (var i = 0; i < needsExplanation.length; i++) {
      if (_cancelled) break;

      final q = needsExplanation[i];
      onProgress?.call(i, needsExplanation.length);

      final explanation = await _generateForQuestion(q);

      if (explanation != null) {
        await updateExplanation(q.id, explanation);
        generated++;
      } else {
        failed++;
      }

      // Respect the rate limit: pause between requests.
      if (i < needsExplanation.length - 1 && !_cancelled) {
        await Future<void>.delayed(delayBetweenRequests);
      }

      // If the proxy returned rate-limited, stop early so we don't waste
      // requests. The caller can re-invoke later to continue.
      if (_lastResult == GeminiProxySource.rateLimited) {
        rateLimited = needsExplanation.length - i - 1;
        break;
      }
    }

    onProgress?.call(needsExplanation.length, needsExplanation.length);

    return SeederResult(
      total: needsExplanation.length,
      generated: generated,
      failed: failed,
      rateLimited: rateLimited,
    );
  }

  // --------------------------------------------------------------------------
  // Private
  // --------------------------------------------------------------------------

  /// Tracks the source of the most recent proxy call so rate-limit detection
  /// can break the outer loop.
  GeminiProxySource _lastResult = GeminiProxySource.cache;

  Future<String?> _generateForQuestion(Question q) async {
    final effectiveProxy = proxy;
    if (effectiveProxy == null || !effectiveProxy.isConfigured) return null;
    final prompt = _buildPrompt(q);

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final result = await effectiveProxy.generate(
        prompt: prompt,
        systemPrompt: _systemPrompt,
        questionId: q.id,
      );

      _lastResult = result.source;

      switch (result.source) {
        case GeminiProxySource.cache:
        case GeminiProxySource.live:
          if (_isValid(result.text)) return result.text;
          // Invalid response — retry once if we have retries left.
          if (attempt < maxRetries) continue;
          debugPrint('⚠️ Invalid explanation for Q${q.id}, skipped.');
          return null;
        case GeminiProxySource.rateLimited:
          return null;
        case GeminiProxySource.error:
          if (attempt < maxRetries) {
            await Future<void>.delayed(delayBetweenRequests * 2);
            continue;
          }
          return null;
        case GeminiProxySource.offline:
          return null;
      }
    }
    return null;
  }

  static bool _needsExplanation(Question q) {
    final e = q.explanation;
    return e == null || e.trim().isEmpty;
  }

  static bool _isValid(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 20) return false;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('error:') || lower.startsWith('sorry')) return false;
    if (lower.contains("couldn't generate") || lower.contains('unable')) {
      return false;
    }
    return true;
  }

  // --------------------------------------------------------------------------
  // Prompt engineering
  // --------------------------------------------------------------------------

  static const _systemPrompt =
      'You are an expert NEET tutor and NCERT content specialist. '
      'Provide accurate, concise, NCERT-grounded explanations.';

  static String _buildPrompt(Question q) {
    final optionsStr = q.options
        .asMap()
        .entries
        .map((e) {
          final letter = String.fromCharCode(65 + e.key);
          return '$letter. ${e.value}';
        })
        .join('\n');

    return '''
You are generating an explanation for a NEET MCQ. Follow these rules exactly:
1. Start by stating why the correct answer is right, referencing the NCERT concept.
2. Then briefly state why EACH wrong option is wrong (one sentence each).
3. Keep the total explanation under 150 words.
4. Ground every statement in NCERT content.
5. Return ONLY the plain explanation text — no headings, no markdown, no bullet symbols.

Question: ${q.questionText}

$optionsStr

Correct Answer: ${q.correctAnswer}
Subject: ${q.subject} | Chapter: ${q.chapter} | Topic: ${q.topic}''';
  }
}
