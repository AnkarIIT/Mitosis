import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/question_model.dart';
import '../../core/services/dpp_engine.dart';
import '../../core/theme/app_colors.dart';

class DppAttemptScreen extends ConsumerStatefulWidget {
  final DppResult dppResult;
  final int durationMinutes;
  final DppConfig? config;

  const DppAttemptScreen({
    super.key,
    required this.dppResult,
    this.durationMinutes = 20,
    this.config,
  });

  @override
  ConsumerState<DppAttemptScreen> createState() => _DppAttemptScreenState();
}

class _DppAttemptScreenState extends ConsumerState<DppAttemptScreen> {
  late final List<Question> _questions;
  late final int _durationSeconds;
  late DppAttemptState _attempt;
  Timer? _timer;
  DateTime? _deadline;
  bool _submitted = false;

  int get _currentQuestionIndex => _attempt.answersByIndex.keys.fold(
      0,
      (max, i) => i > max ? i : max,
    );

  @override
  void initState() {
    super.initState();
    _questions = widget.dppResult.questions;
    _durationSeconds = widget.durationMinutes * 60;
    _attempt = DppAttemptState(
      result: widget.dppResult,
      durationSeconds: _durationSeconds,
    );
    _deadline = DateTime.now().add(Duration(seconds: _durationSeconds));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _deadline!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _timer?.cancel();
        _autoSubmit();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _autoSubmit() async {
    if (_submitted) return;
    _submitted = true;
    _timer?.cancel();
    await _submitDpp(auto: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Question get _currentQuestion {
    final idx = _currentQuestionIndex;
    return idx < _questions.length ? _questions[idx] : _questions.last;
  }

  void _selectAnswer(String answer) {
    if (_attempt.answersByIndex.containsKey(_currentQuestionIndex)) return;
    setState(() {
      _attempt.answersByIndex[_currentQuestionIndex] = answer;
    });
  }

  Future<void> _submitDpp({bool auto = false}) async {
    final correct = <int>[];
    final incorrect = <int>[];
    final unattempted = <int>[];

    for (var i = 0; i < _questions.length; i++) {
      final answer = _attempt.answersByIndex[i];
      if (answer == null || answer.isEmpty) {
        unattempted.add(i);
      } else if (answer.trim() == _questions[i].correctAnswer.trim()) {
        correct.add(i);
      } else {
        incorrect.add(i);
      }
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DppReviewSheet(
        questions: _questions,
        answersByIndex: _attempt.answersByIndex,
        correctIndices: correct,
        incorrectIndices: incorrect,
        unattemptedIndices: unattempted,
        autoSubmitted: auto,
      ),
    );

    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _currentQuestion;
    final selectedAnswer = _attempt.answersByIndex[_currentQuestionIndex];
    final isAnswered = selectedAnswer != null;
    final remaining = _deadline!.difference(DateTime.now()).inSeconds;
    final progress = remaining <= 0 ? 1.0 : remaining / _durationSeconds;
    final timerColor = remaining < 60
        ? AppColors.error
        : remaining < 300
            ? AppColors.warning
            : AppColors.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('DPP - ${widget.dppResult.set.date}'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: timerColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Timer progress bar
            Container(
              height: 4,
              color: theme.dividerColor,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(timerColor),
              ),
            ),
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              minHeight: 6,
              backgroundColor: AppColors.divider,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Q${_currentQuestionIndex + 1}/${_questions.length}',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    question.subject,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _subjectColor(question.subject),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      question.questionText,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(question.options.length, (index) {
                      final option = question.options[index];
                      final optionLetter = String.fromCharCode(65 + index);
                      final isSelected = selectedAnswer == optionLetter;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          onTap: isAnswered ? null : () => _selectAnswer(optionLetter),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.divider,
                                  ),
                                  child: Center(
                                    child: Text(
                                      optionLetter,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(option)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom action bar
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isAnswered ? _submitDpp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isAnswered ? 'Submit DPP' : 'Select an answer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return AppColors.physicsAccent;
    if (s.contains('chem')) return AppColors.chemistryAccent;
    return AppColors.biologyAccent;
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit DPP?'),
        content: const Text('Your progress will be lost if timer hasn\'t expired.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _DppReviewSheet extends StatelessWidget {
  final List<Question> questions;
  final Map<int, String?> answersByIndex;
  final List<int> correctIndices;
  final List<int> incorrectIndices;
  final List<int> unattemptedIndices;
  final bool autoSubmitted;

  const _DppReviewSheet({
    required this.questions,
    required this.answersByIndex,
    required this.correctIndices,
    required this.incorrectIndices,
    required this.unattemptedIndices,
    this.autoSubmitted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = questions.length;
    final correct = correctIndices.length;
    final incorrect = incorrectIndices.length;
    final unattempted = unattemptedIndices.length;
    final accuracy = total > 0 ? ((correct / total) * 100) : 0.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (autoSubmitted)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_off_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Time\'s up! DPP auto-submitted.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'DPP Review',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(context, 'Correct', '$correct', AppColors.success),
                    _buildStat(context, 'Incorrect', '$incorrect', AppColors.error),
                    _buildStat(context, 'Skipped', '$unattempted', AppColors.warning),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total > 0 ? correct / total : 0,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                ),
                const SizedBox(height: 4),
                Text(
                  'Accuracy: ${accuracy.toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ...List.generate(questions.length, (index) {
                  final q = questions[index];
                  final userAnswer = answersByIndex[index];
                  final isCorrect = correctIndices.contains(index);
                  final isIncorrect = incorrectIndices.contains(index);

                  Color statusColor;
                  String statusText;
                  if (isCorrect) {
                    statusColor = AppColors.success;
                    statusText = 'Correct';
                  } else if (isIncorrect) {
                    statusColor = AppColors.error;
                    statusText = 'Incorrect';
                  } else {
                    statusColor = AppColors.warning;
                    statusText = 'Skipped';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        child: Icon(
                          isCorrect
                              ? Icons.check_rounded
                              : (isIncorrect ? Icons.close_rounded : Icons.remove_rounded),
                          color: statusColor,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        'Q${index + 1}. ${q.questionText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(statusText),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...q.options.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final option = entry.value;
                                final isUserChoice = userAnswer == String.fromCharCode(65 + idx);
                                final isCorrectOption = idx.toString() == q.correctAnswer;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCorrectOption
                                              ? AppColors.success
                                              : (isUserChoice ? AppColors.error : AppColors.divider),
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + idx),
                                            style: TextStyle(
                                              color: isCorrectOption || isUserChoice
                                                  ? Colors.white
                                                  : AppColors.textDark,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(option)),
                                    ],
                                  ),
                                );
                              }),
                              if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Divider(),
                                Text(
                                  'Explanation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(q.explanation!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back to DPP'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}