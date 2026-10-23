library chapter_quiz_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/chapter_model.dart';
import '../../core/providers/current_user_provider.dart';
import '../../core/providers/providers.dart';
import '../../core/services/chapter_service.dart';
import '../../core/theme/app_theme.dart';

class ChapterQuizScreen extends ConsumerStatefulWidget {
  final String chapterId;

  const ChapterQuizScreen({super.key, required this.chapterId});

  @override
  ConsumerState<ChapterQuizScreen> createState() => _ChapterQuizScreenState();
}

class _ChapterQuizScreenState extends ConsumerState<ChapterQuizScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  bool _submitted = false;

  /// True while stepping through the submitted paper. `_showExplanation` is
  /// meaningless outside review: before submit the student has not earned the
  /// explanation, and after it everything is shown regardless.
  bool _reviewing = false;
  bool get _showExplanation => _submitted && _reviewing;

  @override
  Widget build(BuildContext context) {
    final chapter = ChapterService.getChapter(widget.chapterId);
    if (chapter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chapter Not Found')),
        body: const Center(child: Text('Chapter not found')),
      );
    }

    final quiz = chapter.summaryQuiz;
    if (quiz.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Quiz Available')),
        body: const Center(
          child: Text('No summary quiz available for this chapter'),
        ),
      );
    }

    final currentQuestion = quiz[_currentIndex];
    final progress = (_currentIndex + 1) / quiz.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter Quiz: ${chapter.title}'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: _submitted
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => _showExitDialog(context),
              ),
        actions: [
          // Shown during review too, so the student can see where they are.
          if (!_submitted || _reviewing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Q${_currentIndex + 1}/${quiz.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AdaptiveColors.divider(context),
            valueColor: AlwaysStoppedAnimation(_subjectColor(chapter.subject)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildBody(chapter, currentQuestion),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (_submitted && !_reviewing)
          ? _buildResultBar(context)
          : _buildBottomNav(quiz.length),
    );
  }

  List<Widget> _buildBody(Chapter chapter, QuickCheck currentQuestion) {
    final widgets = <Widget>[
      // Question number
      Text(
        'Question ${_currentIndex + 1}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AdaptiveColors.textSecondary(context),
        ),
      ),
      const SizedBox(height: 8),
      // Question text
      Text(
        currentQuestion.questionText,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AdaptiveColors.textPrimary(context),
          height: 1.4,
        ),
      ),
      const SizedBox(height: 24),
      // Options
      ...List.generate(currentQuestion.options.length, (i) {
        final option = currentQuestion.options[i];
        final letter = String.fromCharCode(65 + i);
        final isSelected = _answers[_currentIndex] == letter;
        // QuickCheck.correctAnswer is the OPTION TEXT (chapter_service.dart
        // stores e.g. 'Nature'), not a letter or an index. Comparing it to
        // `letter` made this permanently false, so the green highlight never
        // rendered and every quiz scored 0%.
        final isCorrect = option == currentQuestion.correctAnswer;
        final showResult = _submitted || _showExplanation;

        Color bgColor;
        Color borderColor;
        if (showResult) {
          if (isCorrect) {
            bgColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green;
          } else if (isSelected) {
            bgColor = Colors.red.withValues(alpha: 0.1);
            borderColor = Colors.red;
          } else {
            bgColor = Colors.transparent;
            borderColor = AdaptiveColors.divider(context);
          }
        } else {
          bgColor = isSelected
              ? _subjectColor(chapter.subject).withValues(alpha: 0.1)
              : AdaptiveColors.surface(context);
          borderColor = isSelected
              ? _subjectColor(chapter.subject)
              : AdaptiveColors.divider(context);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: showResult
                  ? null
                  : () => setState(() => _answers[_currentIndex] = letter),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: showResult ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? _subjectColor(chapter.subject)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? _subjectColor(chapter.subject)
                              : AdaptiveColors.divider(context),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AdaptiveColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: AdaptiveColors.textPrimary(context),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (showResult && isCorrect)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 24,
                      )
                    else
                      (showResult && isSelected && !isCorrect)
                          ? const Icon(
                              Icons.cancel_rounded,
                              color: Colors.red,
                              size: 24,
                            )
                          : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
      // Explanation (conditionally shown)
      if (_submitted || _showExplanation) ...[
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: _subjectColor(chapter.subject),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentQuestion.explanation,
                style: TextStyle(
                  color: AdaptiveColors.textSecondary(context),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    ];

    return widgets;
  }

  Widget _buildBottomNav(int totalQuestions) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Previous'),
              onPressed: _currentIndex > 0
                  ? () => setState(() => _currentIndex--)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Next / Submit
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(
                _currentIndex == totalQuestions - 1 && !_submitted
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                _reviewing
                    ? 'Next'
                    : (_currentIndex == totalQuestions - 1 ? 'Submit' : 'Next'),
              ),
              onPressed: _reviewing
                  // Review mode: walk the submitted paper freely, no gating on
                  // whether the question was answered.
                  ? () => setState(() {
                      if (_currentIndex < totalQuestions - 1) {
                        _currentIndex++;
                      }
                    })
                  : (_answers.containsKey(_currentIndex)
                        ? () async {
                            if (_currentIndex == totalQuestions - 1) {
                              setState(() => _submitted = true);
                              // Nothing recorded the score anywhere, so a
                              // completed chapter never showed progress.
                              await _recordSummaryScore();
                            } else {
                              setState(() => _currentIndex++);
                            }
                          }
                        : null),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBar(BuildContext context) {
    final chapter = ChapterService.getChapter(widget.chapterId);
    final quiz = chapter!.summaryQuiz;
    int correct = 0;
    for (int i = 0; i < quiz.length; i++) {
      // _answers stores the LETTER; correctAnswer is the option TEXT. Compare
      // the option the letter points at, or the score is always 0. See the
      // matching fix in _buildOptions.
      final letter = _answers[i];
      if (letter == null || letter.isEmpty) continue;
      final idx = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
      if (idx < 0 || idx >= quiz[i].options.length) continue;
      if (quiz[i].options[idx] == quiz[i].correctAnswer) correct++;
    }
    final accuracy = quiz.isEmpty ? 0.0 : (correct / quiz.length) * 100;
    final passed = accuracy >= 70;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: passed
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: passed ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: passed ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            passed ? 'Well Done!' : 'Keep Practicing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: passed ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$correct / ${quiz.length} correct (${accuracy.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: 16,
              color: AdaptiveColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          // Without this the explanations were unreachable: after submit the
          // body rendered only the LAST question, so a student could not see
          // why any other answer was wrong.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Review Answers'),
              onPressed: () => setState(() {
                _reviewing = true;
                _currentIndex = 0;
              }),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Retake Quiz'),
              onPressed: () => setState(() {
                _submitted = false;
                _reviewing = false;
                _answers.clear();
                _currentIndex = 0;
              }),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Chapter'),
              onPressed: () =>
                  context.pushReplacement('/chapter/${widget.chapterId}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Persists the summary-quiz score so the chapter landing screen can show
  /// progress and completion. Never throws — a scoring failure must not strand
  /// the student on the result screen.
  Future<void> _recordSummaryScore() async {
    try {
      final chapter = ChapterService.getChapter(widget.chapterId);
      final quiz = chapter?.summaryQuiz ?? const <QuickCheck>[];
      if (quiz.isEmpty) return;
      var correct = 0;
      for (var i = 0; i < quiz.length; i++) {
        final letter = _answers[i];
        if (letter == null || letter.isEmpty) continue;
        final idx = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (idx < 0 || idx >= quiz[i].options.length) continue;
        if (quiz[i].options[idx] == quiz[i].correctAnswer) correct++;
      }
      final accuracy = (correct / quiz.length) * 100;
      final userId = ref.read(currentLocalUserIdProvider) ?? guestOwnerId;
      await ref
          .read(databaseProvider)
          .recordSummaryQuizScore(widget.chapterId, userId, accuracy.round());
      ref.invalidate(chapterProgressProvider(widget.chapterId));
    } catch (e) {
      debugPrint('chapter: failed to record summary quiz score: $e');
    }
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true && context.mounted) {
      context.go('/chapter/${widget.chapterId}');
    }
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return const Color(0xFF1E88E5);
      case 'chemistry':
        return const Color(0xFFE53935);
      case 'biology':
      case 'botany':
      case 'zoology':
        return const Color(0xFF009688);
      default:
        return const Color(0xFF1E88E5);
    }
  }
}
