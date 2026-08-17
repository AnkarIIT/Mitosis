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

  /// Optional override for the recorded attempt's testType. When null it is
  /// derived from [topicId]/[subject] as before.
  final String? testType;

  const EnhancedQuizScreen({
    super.key,
    required this.questions,
    required this.topicName,
    required this.topicId,
    required this.subject,
    this.testType,
  });

  @override
  ConsumerState<EnhancedQuizScreen> createState() => _EnhancedQuizScreenState();
}

class _EnhancedQuizScreenState extends ConsumerState<EnhancedQuizScreen>
    with WidgetsBindingObserver {
  late Stopwatch _stopwatch;
  int _elapsedSeconds = 0;
  late ConfettiController _confettiController;
  final TextEditingController _shortAnswerController = TextEditingController();
  bool _isEvaluatingShortAnswer = false;
  double? _shortAnswerScore;
  String? _shortAnswerFeedback;

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
    _shortAnswerController.dispose();
    super.dispose();
  }

  void _navigateToQuestion(int delta) {
    setState(() {
      _shortAnswerController.clear();
      _shortAnswerScore = null;
      _shortAnswerFeedback = null;
    });
    if (delta < 0) {
      ref.read(quizProvider.notifier).previousQuestion();
    } else {
      ref.read(quizProvider.notifier).nextQuestion();
    }
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
    // T1 offline tier: serve the pre-seeded explanation already stored in the
    // local database ($0, works with no network). Only falls back to live AI
    // when the question has no saved explanation.
    final localExplanation = question.explanation?.trim();
    if (localExplanation != null && localExplanation.isNotEmpty) {
      if (!mounted) return;
      _showHintDialog(
        '$localExplanation'
        '\n\n(From your saved explanation — offline.)',
      );
      return;
    }

    setState(() => _isGettingHint = true);

    final hint = await ref.read(geminiServiceProvider).getQuizHint(
      question.questionText,
      question.options.join(', '),
    );

    if (!mounted) return;
    setState(() => _isGettingHint = false);

    _showHintDialog(hint);
  }

  void _showHintDialog(String content) {
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
        content: SingleChildScrollView(
          child: Text(content),
        ),
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

    // Calculate subject-wise scores using the same correctness used for scoring
    final Map<String, int> subjectScores = {};
    for (int i = 0; i < quizState.questions.length; i++) {
      final q = quizState.questions[i];
      final isCorrect = quizState.answerResults[i] ?? false;
      if (isCorrect) {
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
      testType: widget.testType ??
          (widget.topicId == 'mock_test'
              ? 'mock'
              : (widget.subject == 'Mixed' ? 'topic' : 'subject')),
      subjectScores: subjectScores,
      score: quizState.score,
      incorrectCount: quizState.incorrectCount,
      totalQuestions: quizState.questions.length,
      timeSpentSeconds: _elapsedSeconds,
      attemptedAt: DateTime.now(),
      selectedAnswers: List.generate(
        quizState.questions.length,
        (i) => quizState.selectedAnswers[i] ?? '',
      ),
    );

    ref.read(userProgressProvider.notifier).recordQuizAttempt(attempt);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestResultScreen(attempt: attempt),
      ),
    );
  }

  Future<void> _evaluateShortAnswer(String studentAnswer, String correctAnswer) async {
    setState(() {
      _isEvaluatingShortAnswer = true;
      _shortAnswerScore = null;
      _shortAnswerFeedback = null;
    });

    try {
      final score = await ref.read(mlServiceProvider).evaluateShortAnswer(studentAnswer, correctAnswer);
      
      if (!mounted) return;
      
      setState(() {
        _shortAnswerScore = score * 100;
        _isEvaluatingShortAnswer = false;
        _shortAnswerFeedback = _shortAnswerScore! >= 65 
            ? "Excellent! You captured the core concept correctly." 
            : "Review the key terms in the NCERT summary to improve your score.";
      });

      // Update quiz state (score it as correct if >= 65%)
      ref.read(quizProvider.notifier).selectAnswer(
        ref.read(quizProvider).currentIndex,
        studentAnswer,
        0, // time spent placeholder
        isCorrect: _shortAnswerScore! >= 65,
      );
      
      if (_shortAnswerScore! >= 65) {
        _confettiController.play();
      }
    } catch (e) {
      if (mounted) setState(() => _isEvaluatingShortAnswer = false);
    }
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
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceWarm,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textDark),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Column(
            children: [
              Text(
                widget.topicName,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatTime(_elapsedSeconds),
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            _buildHintButton(currentQuestion),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? AppColors.primary : AppColors.textSubtle,
              ),
              onPressed: () {
                ref.read(bookmarksProvider.notifier).toggleBookmark(
                  questionId: currentQuestion.id,
                  subject: currentQuestion.subject,
                  topicId: currentQuestion.topicId,
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (quizState.currentIndex + 1) / quizState.questions.length,
                  minHeight: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${quizState.currentIndex + 1} of ${quizState.questions.length}',
                    style: const TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isAnswered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selectedAnswer == currentQuestion.correctAnswer 
                          ? AppColors.success.withValues(alpha: 0.1) 
                          : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedAnswer == currentQuestion.correctAnswer ? '+4 NEET' : '-1 NEET',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: selectedAnswer == currentQuestion.correctAnswer ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Question Text
              Text(
                currentQuestion.questionText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Options / Answer Input
              if (currentQuestion.type == 'shortAnswer')
                _buildShortAnswerInput(currentQuestion, isAnswered)
              else
                ...currentQuestion.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = selectedAnswer == option;
                final isCorrect = option == currentQuestion.correctAnswer;

                Color borderColor = AppColors.divider;
                Color bgColor = Colors.white;
                Color textColor = AppColors.textDark;

                if (isSelected && !isAnswered) {
                  borderColor = AppColors.primary;
                  bgColor = AppColors.primary.withValues(alpha: 0.05);
                } else if (isAnswered) {
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isAnswered
                            ? null
                            : () {
                                ref.read(quizProvider.notifier).selectAnswer(quizState.currentIndex, option, 0); // 0 as default time spent
                                if (option == currentQuestion.correctAnswer) {
                                  _confettiController.play();
                                }
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                            boxShadow: isSelected && !isAnswered ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ] : null,
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
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isAnswered && isCorrect)
                                const Icon(Icons.check_circle, color: AppColors.success)
                              else if (isAnswered && isSelected)
                                const Icon(Icons.cancel, color: AppColors.error),
                            ],
                          ),
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
                    onPressed: () => _navigateToQuestion(-1),
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
                            _navigateToQuestion(1);
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

  Widget _buildShortAnswerInput(Question question, bool isAnswered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _shortAnswerController,
          enabled: !isAnswered,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!isAnswered)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isEvaluatingShortAnswer 
                  ? null 
                  : () => _evaluateShortAnswer(_shortAnswerController.text, question.correctAnswer),
              child: _isEvaluatingShortAnswer 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT FOR AI EVALUATION'),
            ),
          ),
        if (isAnswered && _shortAnswerScore != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (_shortAnswerScore! >= 65 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (_shortAnswerScore! >= 65 ? AppColors.success : AppColors.error).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _shortAnswerScore! >= 65 ? Icons.stars : Icons.info_outline,
                      color: _shortAnswerScore! >= 65 ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Score: ${_shortAnswerScore!.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _shortAnswerScore! >= 65 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _shortAnswerFeedback ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
