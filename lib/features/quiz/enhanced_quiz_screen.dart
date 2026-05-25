import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/question_model.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import 'package:confetti/confetti.dart';

import '../test_series/test_result_screen.dart';

class EnhancedQuizScreen extends ConsumerStatefulWidget {
  final List<Question> questions;
  final String topicName;
  final String topicId;
  final String subject;

  const EnhancedQuizScreen({
    super.key,
    required this.questions,
    required this.topicName,
    required this.topicId,
    required this.subject,
  });

  @override
  ConsumerState<EnhancedQuizScreen> createState() => _EnhancedQuizScreenState();
}

class _EnhancedQuizScreenState extends ConsumerState<EnhancedQuizScreen>
    with WidgetsBindingObserver {
  late Stopwatch _stopwatch;
  int _elapsedSeconds = 0;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stopwatch = Stopwatch()..start();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(quizProvider.notifier).initializeQuiz(widget.questions);
      }
    });
    _startTimer();
  }

  bool _isGettingHint = false;

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _elapsedSeconds = _stopwatch.elapsed.inSeconds;
      });
      ref.read(quizProvider.notifier).updateTimeElapsed(_elapsedSeconds);
      return !ref.read(quizProvider).isCompleted && mounted;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatch.stop();
    _confettiController.dispose();
    super.dispose();
  }

  Widget _buildHintButton(Question question) {
    return IconButton(
      onPressed: _isGettingHint ? null : () => _showHint(question),
      icon: _isGettingHint
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : const Icon(Icons.lightbulb_outline, color: AppColors.primary),
      tooltip: 'Get a hint',
    );
  }

  void _showHint(Question question) async {
    setState(() => _isGettingHint = true);
    
    final hint = await ref.read(geminiServiceProvider).getQuizHint(
      question.questionText,
      question.options.join(', '),
    );
    
    if (!mounted) return;
    setState(() => _isGettingHint = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lightbulb, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Hint'),
          ],
        ),
        content: Text(hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _navigateToResults() {
    final quizState = ref.read(quizProvider);

    // Calculate subject-wise scores
    final Map<String, int> subjectScores = {};
    for (int i = 0; i < quizState.questions.length; i++) {
      final q = quizState.questions[i];
      final answer = quizState.selectedAnswers[i];
      if (answer == q.correctAnswer) {
        subjectScores[q.subject] = (subjectScores[q.subject] ?? 0) + 1;
      } else {
        subjectScores[q.subject] = subjectScores[q.subject] ?? 0;
      }
    }

    // Record this quiz attempt
    final attempt = QuizAttempt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topicId: widget.topicId,
      subject: widget.subject,
      testType: widget.topicId == 'mock_test' ? 'mock' : (widget.subject == 'Mixed' ? 'topic' : 'subject'),
      subjectScores: subjectScores,
      score: quizState.score,
      totalQuestions: quizState.questions.length,
      timeSpentSeconds: _elapsedSeconds,
      attemptedAt: DateTime.now(),
      selectedAnswers: quizState.selectedAnswers.values.toList(),
    );

    ref.read(userProgressProvider.notifier).recordQuizAttempt(attempt);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestResultScreen(attempt: attempt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    if (quizState.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (quizState.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToResults();
      });
    }

    final currentQuestion = quizState.questions[quizState.currentIndex];
    final isAnswered = quizState.selectedAnswers.containsKey(
      quizState.currentIndex,
    );
    final selectedAnswer = quizState.selectedAnswers[quizState.currentIndex];
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.any(
      (b) => b.questionId == currentQuestion.id,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text('Your progress will not be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (confirm ?? false) {
          ref.read(quizProvider.notifier).resetQuiz();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.topicName),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? AppColors.secondary : AppColors.textLight,
              ),
              tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Question',
              onPressed: () {
                ref
                    .read(bookmarksProvider.notifier)
                    .toggleBookmark(
                      questionId: currentQuestion.id,
                      subject: widget.subject,
                      topicId: widget.topicId,
                    );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Time', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(quizState.questions.length, (index) {
                    final bool isCurrent = index == quizState.currentIndex;
                    final bool isAnsweredPill = quizState.selectedAnswers.containsKey(index);
                    final bool isCorrectPill = isAnsweredPill && 
                        quizState.selectedAnswers[index] == quizState.questions[index].correctAnswer;
                    
                    Color pillColor = AppColors.surface;
                    Color pillBorderColor = AppColors.divider;
                    Color pillTextColor = AppColors.textSubtle;
                    
                    if (isCurrent) {
                      pillColor = AppColors.primary;
                      pillBorderColor = AppColors.primary;
                      pillTextColor = AppColors.textLight;
                    } else if (isAnsweredPill) {
                      pillColor = isCorrectPill ? AppColors.successLight : AppColors.errorLight;
                      pillBorderColor = isCorrectPill ? AppColors.success : AppColors.error;
                      pillTextColor = isCorrectPill ? AppColors.success : AppColors.error;
                    }

                    return GestureDetector(
                      onTap: () {
                        // Optional: Allow jumping to answered questions
                        // For now we just let them jump if we want, or do nothing.
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pillColor,
                          border: Border.all(color: pillBorderColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: pillTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Question
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentQuestion.questionText,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildHintButton(currentQuestion),
                ],
              ),
              const SizedBox(height: 24),

              // Options
              ...currentQuestion.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = selectedAnswer == option;
                final isCorrect = option == currentQuestion.correctAnswer;

                Color buttonColor = Colors.transparent;
                Color textColor = AppColors.textDark;

                if (isSelected && !isAnswered) {
                  // Highlight selected option before answering
                  buttonColor = AppColors.secondary.withValues(alpha: 0.5);
                  textColor = AppColors.textDark;
                } else if (isAnswered && isSelected) {
                  if (isCorrect) {
                    buttonColor = AppColors.success.withValues(alpha: 0.15);
                    textColor = AppColors.success;
                  } else {
                    buttonColor = AppColors.error.withValues(alpha: 0.15);
                    textColor = AppColors.error;
                  }
                } else if (isAnswered && isCorrect) {
                  buttonColor = AppColors.success.withValues(alpha: 0.15);
                  textColor = AppColors.success;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isAnswered
                          ? null
                          : () {
                              ref
                                  .read(quizProvider.notifier)
                                  .selectAnswer(quizState.currentIndex, option);
                              if (option == currentQuestion.correctAnswer) {
                                _confettiController.play();
                              }
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: isSelected && !isAnswered ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: buttonColor,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: TextStyle(
                                    color: textColor,
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
                                ),
                              ),
                            ),
                            if (isAnswered && isCorrect)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              )
                            else if (isAnswered && isSelected)
                              const Icon(
                                Icons.cancel,
                                color: AppColors.error,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Explanation (shown after answering)
              if (isAnswered)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Explanation',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentQuestion.explanation ??
                              'No explanation available',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (currentQuestion.ncertReference != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '📖 ${currentQuestion.ncertReference}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
        floatingActionButton: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.2,
          colors: const [
            AppColors.primary,
            AppColors.success,
            AppColors.warning,
            AppColors.chemistryAccent,
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Previous button
              if (quizState.currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(quizProvider.notifier).previousQuestion();
                    },
                    child: const Text('Previous'),
                  ),
                ),
              if (quizState.currentIndex > 0) const SizedBox(width: 12),

              // Next/Submit button
              Expanded(
                child: ElevatedButton(
                  onPressed: isAnswered
                      ? () {
                          if (quizState.currentIndex <
                              quizState.questions.length - 1) {
                            ref.read(quizProvider.notifier).nextQuestion();
                          } else {
                            ref.read(quizProvider.notifier).completeQuiz();
                          }
                        }
                      : null,
                  child: Text(
                    quizState.currentIndex == quizState.questions.length - 1
                        ? 'Submit Quiz'
                        : 'Next Question',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
