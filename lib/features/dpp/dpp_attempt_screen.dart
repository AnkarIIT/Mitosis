import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/drift_database.dart' as db;
import '../../core/providers/core_providers.dart';
import '../../core/models/question_model.dart';
import '../../core/services/dpp_engine.dart';
import '../../core/services/result_export_service.dart';
import '../../core/theme/app_colors.dart';
import 'package:drift/drift.dart' hide Column;

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
  int _currentQuestionIndex = 0;

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

  void _selectAnswer(String selectedValue) {
    setState(() {
      _attempt.answersByIndex[_currentQuestionIndex] = selectedValue;
    });
  }

  static bool _checkAnswerCorrect(Question q, String? userVal) {
    if (userVal == null || userVal.isEmpty) return false;
    final cleanUser = userVal.trim().toLowerCase();
    final cleanCorrect = q.correctAnswer.trim().toLowerCase();

    if (cleanUser == cleanCorrect) return true;

    // Check letter vs option text vs option index (0, 1, 2, 3 or A, B, C, D)
    if (userVal.length == 1) {
      final letterCode = userVal.toUpperCase().codeUnitAt(0);
      if (letterCode >= 65 && letterCode <= 68) {
        final idx = letterCode - 65;
        // Check if correctAnswer is index string ('0', '1', '2', '3')
        if (cleanCorrect == idx.toString()) return true;
        // Check if correctAnswer matches option text at index
        if (idx < q.options.length && q.options[idx].trim().toLowerCase() == cleanCorrect) {
          return true;
        }
      }
    }

    // Check if userVal is option text matching correctAnswer
    return false;
  }

  Future<void> _submitDpp({bool auto = false}) async {
    final correct = <int>[];
    final incorrect = <int>[];
    final unattempted = <int>[];

    for (var i = 0; i < _questions.length; i++) {
      final answer = _attempt.answersByIndex[i];
      if (answer == null || answer.isEmpty) {
        unattempted.add(i);
      } else if (_checkAnswerCorrect(_questions[i], answer)) {
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

    await _persistDppResult(
      correctCount: correct.length,
      incorrectCount: incorrect.length,
      unattemptedCount: unattempted.length,
    );

    if (!mounted) return;
    context.go('/');
  }

  Future<void> _persistDppResult({
    required int correctCount,
    required int incorrectCount,
    required int unattemptedCount,
  }) async {
    try {
      final database = ref.read(databaseProvider);
      final set = widget.dppResult.set;
      final timeSpent = _durationSeconds - _deadline!.difference(DateTime.now()).inSeconds;
      final safeTime = timeSpent > 0 ? timeSpent : _durationSeconds;

      await (database.update(database.dppSets)..where((t) => t.id.equals(set.id))).write(
        db.DppSetsCompanion(
          correctCount: Value(correctCount),
          incorrectCount: Value(incorrectCount),
          unattemptedCount: Value(unattemptedCount),
          timeSpentSeconds: Value(safeTime),
          isCompleted: Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await database.insertQuizAttempt(
        db.QuizAttemptsCompanion.insert(
          topicId: 'dpp_${set.subject.toLowerCase()}',
          subject: set.subject,
          testType: const Value('dpp'),
          score: correctCount,
          incorrectCount: Value(incorrectCount),
          totalQuestions: _questions.length,
          timeSpentSeconds: safeTime,
          attemptedAt: DateTime.now(),
          selectedAnswers: jsonEncode(List<String>.filled(_questions.length, '')),
          rawScore: Value(correctCount * 4 - incorrectCount),
          maxMarks: Value(_questions.length * 4),
        ),
      );

      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final answer = _attempt.answersByIndex[i];
        final isCorrect = answer != null && answer == q.correctAnswer;
        if (!isCorrect) {
          await database.addToErrorBook(db.ErrorBookCompanion.insert(
            questionId: q.id,
            addedAt: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Error persisting DPP result: $e');
    }
  }

  Future<void> _exportCsv() async {
    try {
      final path = await ResultExportService.exportDppResultToCsv(
        _questions,
        _attempt.answersByIndex,
        widget.dppResult.set.subject,
      );

      if (!mounted) return;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export CSV.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exported to: $path'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            if (_submitted)
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Export CSV',
                onPressed: () => _exportCsv(),
              ),
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
                          onTap: () => _selectAnswer(optionLetter),
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
            // Navigation & action bar
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
                  OutlinedButton(
                    onPressed: _currentQuestionIndex > 0
                        ? () => setState(() => _currentQuestionIndex--)
                        : null,
                    child: const Text('Prev'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentQuestionIndex < _questions.length - 1
                          ? () => setState(() => _currentQuestionIndex++)
                          : () => _submitDpp(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentQuestionIndex < _questions.length - 1
                            ? 'Next'
                            : 'Submit DPP',
                      ),
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