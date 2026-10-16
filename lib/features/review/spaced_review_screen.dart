import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/question_model.dart';
import '../../core/utils/answer_normalizer.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Spaced-repetition review session over currently due cards.
///
/// Each answer is scheduled through the SM-2 engine (via
/// [SpacedReviewRecorder]) and the Error Book is kept in sync automatically.
class SpacedReviewScreen extends ConsumerStatefulWidget {
  const SpacedReviewScreen({super.key});

  @override
  ConsumerState<SpacedReviewScreen> createState() => _SpacedReviewScreenState();
}

class _SpacedReviewScreenState extends ConsumerState<SpacedReviewScreen> {
  final TextEditingController _shortAnswerController = TextEditingController();

  List<Question> _queue = const [];
  int _index = 0;
  String? _selected;
  bool _answered = false;
  bool _sessionDone = false;
  final Map<String, bool> _results = {};

  @override
  void dispose() {
    _shortAnswerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(Question question, String answer) async {
    if (_answered) return;
    // Only route through AnswerNormalizer when the card actually has options.
    // For a free-text card `options` is empty, so `optionIndex` returns null for
    // both sides and `isCorrect` is ALWAYS false — every short answer was
    // recorded wrong, downgraded by SM-2 regardless of what the student wrote.
    final isCorrect = question.options.isEmpty
        ? answer.trim().toLowerCase() ==
              question.correctAnswer.trim().toLowerCase()
        : AnswerNormalizer.isCorrect(answer, question);
    setState(() {
      _selected = answer;
      _answered = true;
      _results[question.id] = isCorrect;
    });
    await ref
        .read(spacedReviewRecorderProvider)
        .recordAnswer(questionId: question.id, isCorrect: isCorrect);
  }

  void _selectOption(String option) {
    if (_answered) return;
    setState(() => _selected = option);
  }

  void _confirmSelection(Question question) {
    if (_answered || _selected == null) return;
    _submitAnswer(question, _selected!);
  }

  void _changeSelection() {
    if (_answered) return;
    setState(() => _selected = null);
  }

  void _next() {
    if (_index + 1 >= _queue.length) {
      setState(() => _sessionDone = true);
    } else {
      setState(() {
        _index += 1;
        _selected = null;
        _answered = false;
        _shortAnswerController.clear();
      });
    }
  }

  void _submitShortAnswer(Question question) {
    final answer = _shortAnswerController.text.trim();
    if (answer.isEmpty) return;
    _submitAnswer(question, answer);
  }

  @override
  Widget build(BuildContext context) {
    final dueAsync = ref.watch(dueCardsProvider);

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: const Text('Review Session'),
        actions: [
          IconButton(
            tooltip: 'Error Book',
            icon: const Icon(Icons.book_outlined),
            onPressed: () => context.push('/error-book'),
          ),
        ],
      ),
      body: dueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load review: $e')),
        data: (due) => _buildContent(due),
      ),
    );
  }

  Widget _buildContent(List<Question> due) {
    // `_sessionDone` must be checked FIRST, and "all caught up" is only true
    // when there is no session in flight. Answering a card reschedules it and
    // invalidates `dueCardsProvider`, so `due` empties for a few frames right
    // after the LAST card is answered — long before the student taps "Finish
    // Review" (which is what sets `_sessionDone`). The old code returned
    // _buildEmptyState() in that window, yanking the result banner, the
    // explanation and the Finish button out from under them, and made
    // _buildSummary() effectively unreachable.
    if (_sessionDone) return _buildSummary();

    if (due.isEmpty && _queue.isEmpty) return _buildEmptyState();

    if (_queue.isEmpty) {
      _queue = due;
      _results.clear();
    }
    // Guard against a provider re-emit that is shorter than the live index.
    if (_index >= _queue.length) _index = _queue.length - 1;

    final question = _queue[_index];
    final isMcq = question.options.isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _queue.length,
                    minHeight: 8,
                    backgroundColor: AdaptiveColors.outlineVariant(
                      context,
                    ).withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Card ${_index + 1} of ${_queue.length}',
                      style: TextStyle(
                        color: AdaptiveColors.textSecondary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_answered)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _results[question.id] == true
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _results[question.id] == true
                              ? 'Correct'
                              : 'Incorrect',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _results[question.id] == true
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${question.subject} • ${question.chapter}',
                    style: TextStyle(
                      color: AdaptiveColors.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AdaptiveColors.textPrimary(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (isMcq)
                    ..._buildMcqOptions(question)
                  else
                    _buildShortAnswerInput(question),
                  if (_answered) _buildExplanation(question),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_answered)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _index + 1 >= _queue.length ? 'Finish Review' : 'Next Card',
                  ),
                ),
              ),
            ),
          // Two-step MCQ confirmation: tapping an option only selects it.
          // The answer is recorded only after an explicit Confirm, so an
          // accidental tap can be changed before any feedback is given.
          if (!_answered && isMcq && _selected != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _changeSelection,
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => _confirmSelection(question),
                      child: const Text('Confirm answer'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMcqOptions(Question question) {
    return question.options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final isSelected = _selected == option;
      final isCorrect = AnswerNormalizer.isCorrect(option, question);

      Color borderColor = AdaptiveColors.outline(context);
      Color bgColor = AdaptiveColors.surface(context);
      Color textColor = AdaptiveColors.textPrimary(context);

      if (isSelected && !_answered) {
        borderColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.05);
      } else if (_answered) {
        if (isCorrect) {
          borderColor = AppColors.success;
          bgColor = AppColors.success.withValues(alpha: 0.05);
          textColor = AppColors.success;
        } else if (isSelected) {
          borderColor = AppColors.error;
          bgColor = AppColors.error.withValues(alpha: 0.05);
          textColor = AppColors.error;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _answered ? null : () => _selectOption(option),
            borderRadius: AppRadius.mdAll,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? borderColor : Colors.transparent,
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_answered && isCorrect)
                    const Icon(Icons.check_circle, color: AppColors.success)
                  else if (_answered && isSelected)
                    const Icon(Icons.cancel, color: AppColors.error),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildShortAnswerInput(Question question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _shortAnswerController,
          enabled: !_answered,
          decoration: const InputDecoration(
            hintText: 'Type your answer...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: _answered ? null : (v) => _submitShortAnswer(question),
        ),
        if (!_answered)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => _submitShortAnswer(question),
                child: const Text('Check Answer'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExplanation(Question question) {
    final isCorrect = _results[question.id] == true;
    final explanation = question.explanation ?? 'No explanation available.';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isCorrect ? AppColors.success : AppColors.primary).withValues(
            alpha: 0.08,
          ),
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: (isCorrect ? AppColors.success : AppColors.primary)
                .withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect
                      ? Icons.check_circle_outline
                      : Icons.lightbulb_outline,
                  size: 20,
                  color: isCorrect ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? 'Great job!' : 'Explanation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppColors.success : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isCorrect)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Correct answer: ${question.correctAnswer}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AdaptiveColors.textPrimary(context),
                  ),
                ),
              ),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 14,
                color: AdaptiveColors.textPrimary(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final correct = _results.values.where((c) => c).length;
    final total = _results.length;
    final percent = total == 0 ? 0 : (correct / total * 100).round();

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                percent >= 80 ? Icons.emoji_events : Icons.refresh,
                size: 64,
                color: percent >= 80 ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Review Complete',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$correct of $total correct ($percent%)',
                style: TextStyle(
                  fontSize: 16,
                  color: AdaptiveColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No questions are due right now. Questions you miss during '
              'quizzes are scheduled here for review at growing intervals '
              '(1 → 3 → 7 → 21 days).',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AdaptiveColors.textSecondary(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
