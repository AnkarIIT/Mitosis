import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/question_model.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'quiz_header.dart';
import 'question_card.dart';
import 'quiz_footer.dart';

class EnhancedQuizScreen extends ConsumerStatefulWidget {
  final List<Question>? questions;
  final String topicName;
  final String topicId;
  final String subject;
  final String? testType;

  const EnhancedQuizScreen({
    super.key,
    this.questions,
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

  bool _hasNavigatedToResults = false;
  bool _showPalette = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stopwatch = Stopwatch()..start();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.questions != null) {
          ref.read(quizProvider.notifier).initializeQuiz(widget.questions!);
        } else if (widget.topicId.isNotEmpty) {
          _loadQuestionsFromProvider();
        }
      }
    });
    _startTimer();
  }

  Future<void> _loadQuestionsFromProvider() async {
    final questions = await ref.read(questionsForTopicProvider(widget.topicId).future);
    if (mounted && questions.isNotEmpty) {
      ref.read(quizProvider.notifier).initializeQuiz(questions);
    }
  }

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

  void _showHint(Question question) async {
    final localExplanation = question.explanation?.trim();
    if (localExplanation != null && localExplanation.isNotEmpty) {
      _showHintDialog('$localExplanation\n\n(Offline hint)');
      return;
    }

    final hint = await ref.read(geminiServiceProvider).getQuizHint(
          question.questionText,
          question.options.join(', '),
        );
    _showHintDialog(hint);
  }

  void _showHintDialog(String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: AdaptiveColors.warning(context)),
            const SizedBox(width: 8),
            const Text('Hint'),
          ],
        ),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _navigateToResults() {
    final quizState = ref.read(quizProvider);
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

    final attempt = QuizAttempt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topicId: widget.topicId,
      subject: widget.subject,
      testType: widget.testType ?? (widget.topicId == 'mock_test' ? 'mock' : 'subject'),
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
    if (!mounted) return;
    context.go('/quiz/result', extra: attempt);
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
            ? "Excellent! You captured the core concept."
            : "Review the key terms in NCERT to improve.";
      });
      final isCorrect = _shortAnswerScore! >= 65;
      ref.read(quizProvider.notifier).selectAnswer(
            ref.read(quizProvider).currentIndex,
            studentAnswer,
            0,
            isCorrect: isCorrect,
          );
      if (isCorrect) _confettiController.play();
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

    if (quizState.isCompleted && !_hasNavigatedToResults) {
      _hasNavigatedToResults = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToResults());
    }

    final currentQuestion = quizState.questions[quizState.currentIndex];
    final isAnswered = quizState.selectedAnswers.containsKey(quizState.currentIndex);
    final selectedAnswer = quizState.selectedAnswers[quizState.currentIndex];
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.any((b) => b.questionId == currentQuestion.id);
    final isFlagged = quizState.flaggedQuestions.contains(quizState.currentIndex);

    return Scaffold(
      backgroundColor: AdaptiveColors.surfaceWarm(context),
      appBar: QuizAppBar(
        topicName: widget.topicName,
        elapsedSeconds: _elapsedSeconds,
        currentIndex: quizState.currentIndex,
        totalQuestions: quizState.questions.length,
        isBookmarked: isBookmarked,
        currentQuestion: currentQuestion,
        onClose: () => Navigator.maybePop(context),
        onBookmarkToggle: () {
          ref.read(bookmarksProvider.notifier).toggleBookmark(
                questionId: currentQuestion.id,
                subject: currentQuestion.subject,
                topicId: currentQuestion.topicId,
              );
        },
        onHintPressed: () => _showHint(currentQuestion),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                QuizProgressBar(currentIndex: quizState.currentIndex, totalQuestions: quizState.questions.length),
                const SizedBox(height: 8),
                // Timer bar with pulse when time is low
                _QuizTimerBar(elapsedSeconds: _elapsedSeconds),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuizQuestionCounter(currentIndex: quizState.currentIndex, totalQuestions: quizState.questions.length),
                    QuizScoreIndicator(selectedAnswer: selectedAnswer, correctAnswer: currentQuestion.correctAnswer),
                  ],
                ),
                const SizedBox(height: 32),
                if (currentQuestion.type == 'shortAnswer')
                  _buildShortAnswerInput(currentQuestion, isAnswered)
                else
                  QuestionCard(
                    question: currentQuestion,
                    isAnswered: isAnswered,
                    selectedAnswer: selectedAnswer,
                  ),
                if (isAnswered) _buildExplanation(currentQuestion),
              ],
            ),
          ),
          // Question palette overlay
          if (_showPalette) _buildQuestionPalette(context, quizState),
        ],
      ),
      floatingActionButton: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        colors: const [AppColors.primary, AppColors.success, AppColors.warning],
      ),
      bottomNavigationBar: QuizFooter(
        currentIndex: quizState.currentIndex,
        totalQuestions: quizState.questions.length,
        isAnswered: isAnswered,
        isLastQuestion: quizState.currentIndex == quizState.questions.length - 1,
        isFlagged: isFlagged,
        onPrevious: () => _navigateToQuestion(-1),
        onNext: () => _navigateToQuestion(1),
        onFlagToggle: () => ref.read(quizProvider.notifier).toggleFlag(quizState.currentIndex),
        onMarkForReviewAndNext: () => ref.read(quizProvider.notifier).markForReviewAndNext(),
        onSubmit: () {
          if (quizState.currentIndex < quizState.questions.length - 1) {
            _navigateToQuestion(1);
          } else {
            ref.read(quizProvider.notifier).completeQuiz();
          }
        },
        onPaletteToggle: () => setState(() => _showPalette = !_showPalette),
      ),
    );
  }

  Widget _buildShortAnswerInput(Question question, bool isAnswered) {
    return Column(
      children: [
        TextField(
          controller: _shortAnswerController,
          enabled: !isAnswered,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        if (!isAnswered)
          ElevatedButton(
            onPressed: _isEvaluatingShortAnswer ? null : () => _evaluateShortAnswer(_shortAnswerController.text, question.correctAnswer),
            child: _isEvaluatingShortAnswer ? const CircularProgressIndicator() : const Text('SUBMIT FOR AI EVALUATION'),
          ),
        if (isAnswered && _shortAnswerScore != null)
          Text('AI Score: ${_shortAnswerScore!.toStringAsFixed(0)}% - $_shortAnswerFeedback'),
      ],
    );
  }

  Widget _buildExplanation(Question question) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdaptiveColors.primary(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(question.explanation ?? 'No explanation available'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPalette(BuildContext context, QuizState quizState) {
    final total = quizState.questions.length;
    final answered = quizState.selectedAnswers.keys.toSet();
    final flagged = quizState.flaggedQuestions;
    final visited = quizState.visitedQuestions;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showPalette = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question Palette',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _showPalette = false),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _paletteLegendDot(AppColors.success, 'Answered'),
                          _paletteLegendDot(AppColors.error, 'Not Answered'),
                          _paletteLegendDot(AppColors.warning, 'Flagged'),
                          _paletteLegendDot(AppColors.primary, 'Current'),
                          _paletteLegendDot(AdaptiveColors.divider(context), 'Not Visited'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: quizState.questions.length,
                        itemBuilder: (context, index) {
                          final isCurrent = index == quizState.currentIndex;
                          final isAnswered = quizState.selectedAnswers.containsKey(index);
                          final isFlagged = quizState.flaggedQuestions.contains(index);
                          final isVisited = quizState.visitedQuestions.contains(index);

                          Color bg;
                          Color fg = Colors.white;
                          if (isAnswered && isFlagged) {
                            bg = AppColors.success;
                          } else if (isAnswered) {
                            bg = AppColors.success;
                          } else if (isFlagged) {
                            bg = AppColors.warning;
                          } else if (isVisited) {
                            bg = AppColors.error;
                          } else {
                            bg = AdaptiveColors.background(context);
                            fg = AdaptiveColors.textPrimary(context);
                          }

                          return InkWell(
                            onTap: () {
                              setState(() => _showPalette = false);
                              ref.read(quizProvider.notifier).goToQuestion(index);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AdaptiveColors.primary(context)
                                          : AdaptiveColors.divider(context),
                                      width: isCurrent ? 2.5 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: fg,
                                    ),
                                  ),
                                ),
                                if (isAnswered && isFlagged)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: const Icon(Icons.flag, size: 10, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

Widget _paletteLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AdaptiveColors.textSecondary(context))),
      ],
    );
  }
}

/// Timer bar that fills based on elapsed time and pulses red when < 30s remain.
class _QuizTimerBar extends StatelessWidget {
  final int elapsedSeconds;
  final int totalQuestions;

  const _QuizTimerBar({
    required this.elapsedSeconds,
    this.totalQuestions = 10,
  });

  @override
  Widget build(BuildContext context) {
    final timeLimit = totalQuestions * 60; // 1 min per question default
    final remaining = (timeLimit - elapsedSeconds).clamp(0, timeLimit);
    final fraction = elapsedSeconds / timeLimit;
    final isLow = remaining < 30;
    final color = isLow ? AppColors.error : SubjectColors.physics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time',
              style: TextStyle(color: AdaptiveColors.textSecondary(context), fontSize: 11),
            ),
            Text(
              _formatTime(remaining),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ).animate(onPlay: (c) => isLow ? c.repeat(reverse: true) : null)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1, 1.8),
              duration: AppDuration.fast,
              curve: Curves.easeInOut,
            )
            .fadeIn(duration: AppDuration.fast),
      ],
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
