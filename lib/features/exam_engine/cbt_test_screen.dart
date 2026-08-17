import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/question_model.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/exam_engine_service.dart';
import '../../core/services/test_analytics_service.dart';
import '../../core/theme/app_colors.dart';

import 'package:go_router/go_router.dart';

enum _SessionPhase { taking, break_ }

class CbtTestScreen extends ConsumerStatefulWidget {
  final ExamConfig config;
  final List<Question> questionPool;

  const CbtTestScreen({
    super.key,
    required this.config,
    required this.questionPool,
  });

  @override
  ConsumerState<CbtTestScreen> createState() => _CbtTestScreenState();
}

class _CbtTestScreenState extends ConsumerState<CbtTestScreen>
    with WidgetsBindingObserver {
  static const _optionLabels = ['A', 'B', 'C', 'D'];

  late final List<List<Question>> _sectionQuestions;
  late final List<Question> _questions;
  late final List<int> _sectionStart;
  final Map<int, String> _answers = {};
  final Set<int> _flagged = {};
  late final List<int> _secondsPerQuestion;

  Timer? _ticker;
  _SessionPhase _phase = _SessionPhase.taking;
  int _remainingSeconds = 0;
  int _breakRemaining = 0;
  int _currentSection = 0;
  int _currentIndex = 0;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sectionQuestions = ExamEngineService.allocateQuestions(
      widget.questionPool,
      widget.config,
    );
    _questions = ExamEngineService.flattenAllocated(_sectionQuestions);
    _sectionStart = [];
    var acc = 0;
    for (final section in _sectionQuestions) {
      _sectionStart.add(acc);
      acc += section.length;
    }
    _secondsPerQuestion = List<int>.filled(_questions.length, 0);
    _remainingSeconds = widget.config.totalDurationSeconds;
    _skipEmptySections();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _ticker?.cancel();
      _ticker = null;
    } else if (state == AppLifecycleState.resumed &&
        _ticker == null &&
        !_submitted) {
      _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    }
  }

  void _skipEmptySections() {
    while (_currentSection < _sectionQuestions.length &&
        _sectionQuestions[_currentSection].isEmpty) {
      _currentSection++;
    }
    if (_currentSection >= _sectionQuestions.length) {
      _currentSection = 0;
    }
  }

  int _sectionOf(int globalIndex) {
    for (int i = _sectionStart.length - 1; i >= 0; i--) {
      if (globalIndex >= _sectionStart[i]) return i;
    }
    return 0;
  }

  ExamSection get _activeSection => widget.config.sections[_currentSection];

  bool get _isLastQuestionInSection =>
      _currentIndex >=
      _sectionStart[_currentSection] +
          _sectionQuestions[_currentSection].length -
          1;

  bool get _isLastSection => _currentSection == _sectionQuestions.length - 1;

  void _onTick(Timer timer) {
    if (!mounted || _submitted) return;

    if (_phase == _SessionPhase.break_) {
      if (_breakRemaining > 0) {
        setState(() {
          _breakRemaining--;
        });
        if (_breakRemaining <= 0) {
          _advanceToSection(_currentSection + 1);
        }
      }
      return;
    }

    setState(() {
      _remainingSeconds--;
      _secondsPerQuestion[_currentIndex] =
          _secondsPerQuestion[_currentIndex] + 1;
    });
    if (_remainingSeconds <= 0) {
      _submitTest(auto: true);
    }
  }

  void _selectAnswer(String option) {
    setState(() {
      if (_answers[_currentIndex] == option) {
        _answers.remove(_currentIndex);
      } else {
        _answers[_currentIndex] = option;
      }
    });
  }

  void _toggleFlag() {
    setState(() {
      if (_flagged.contains(_currentIndex)) {
        _flagged.remove(_currentIndex);
      } else {
        _flagged.add(_currentIndex);
      }
    });
  }

  void _goTo(int globalIndex) {
    setState(() {
      _currentIndex = globalIndex;
      _currentSection = _sectionOf(globalIndex);
    });
  }

  void _next() {
    if (!widget.config.sectionLock) {
      if (_currentIndex + 1 < _questions.length) {
        _goTo(_currentIndex + 1);
      }
      return;
    }
    if (!_isLastQuestionInSection) {
      _goTo(_currentIndex + 1);
      return;
    }
    if (_isLastSection) {
      _confirmSubmit();
      return;
    }
    _goToNextSection();
  }

  void _previous() {
    if (_currentIndex > 0) {
      _goTo(_currentIndex - 1);
    }
  }

  void _goToNextSection() {
    if (widget.config.breaksEnabled &&
        _currentSection == widget.config.breakAfterSectionIndex) {
      setState(() {
        _phase = _SessionPhase.break_;
        _breakRemaining = widget.config.breakDurationSeconds;
      });
      return;
    }
    _advanceToSection(_currentSection + 1);
  }

  void _advanceToSection(int index) {
    if (index >= _sectionQuestions.length) {
      _confirmSubmit();
      return;
    }
    setState(() {
      _currentSection = index;
      _currentIndex = _sectionStart[index];
      _phase = _SessionPhase.taking;
    });
  }

  void _skipBreak() {
    _advanceToSection(_currentSection + 1);
  }

  Future<void> _confirmSubmit() async {
    if (_submitting || _submitted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Text(
          'You have answered ${_answers.length} of ${_questions.length} questions.\n\n'
          'Once submitted, you cannot change your answers.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Keep Trying'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _submitTest();
    }
  }

  Future<void> _submitTest({bool auto = false}) async {
    if (_submitting || _submitted) return;
    _submitting = true;
    _ticker?.cancel();
    _ticker = null;

    final timeSpent =
        widget.config.totalDurationSeconds - _remainingSeconds;
    final score = ExamEngineService.grade(
      config: widget.config,
      questions: _questions,
      answersByIndex: _answers,
    );
    final analytics = TestAnalyticsService.compute(
      score: score,
      secondsPerQuestion: _secondsPerQuestion,
    );
    final attempt = QuizAttempt(
      id: 'cbt_${DateTime.now().millisecondsSinceEpoch}',
      topicId: widget.config.topicId,
      subject: widget.config.subjectLabel,
      testType: widget.config.testType,
      subjectScores: {
        for (final entry in analytics.subjects.entries)
          entry.key: entry.value.correct,
      },
      score: score.correct,
      incorrectCount: score.incorrect,
      totalQuestions: score.results.length,
      timeSpentSeconds: timeSpent < 0 ? 0 : timeSpent,
      attemptedAt: DateTime.now(),
      selectedAnswers: List.generate(
        _questions.length,
        (i) => _answers[i] ?? '',
      ),
    );

    await ref.read(userProgressProvider.notifier).recordQuizAttempt(
          attempt,
          questions: _questions,
          answersByIndex: _answers,
        );

    if (!mounted) return;
    _submitted = true;
    context.go('/cbt/result', extra: {
      'attempt': attempt,
      'analytics': analytics,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mock Test'), elevation: 0),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No questions available for this test.'),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_phase == _SessionPhase.break_) {
          _skipBreak();
          return;
        }
        final exit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Test?'),
            content: const Text(
              'Your progress will not be saved and the attempt will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          _ticker?.cancel();
          context.pop();
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.config.mode == ExamMode.neet
                    ? 'NEET Mock Test'
                    : 'CBT Practice',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.config.sectionLock
                    ? 'Section ${_currentSection + 1} of '
                        '${_sectionQuestions.length} • ${_activeSection.name}'
                    : _activeSection.name,
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            if (_submitting)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _confirmSubmit,
                child: const Text('Submit'),
              ),
          ],
        ),
        body: Column(
          children: [
            _buildTimerBar(),
            Expanded(
              child: _phase == _SessionPhase.break_
                  ? _buildBreakView()
                  : _buildQuestionView(),
            ),
            if (_phase != _SessionPhase.break_) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBar() {
    final remaining = _remainingSeconds < 0 ? 0 : _remainingSeconds;
    final total = widget.config.totalDurationSeconds;
    final progress = total <= 0 ? 1.0 : remaining / total;
    final color = remaining < 300
        ? AppColors.error
        : remaining < 600
            ? AppColors.warning
            : AppColors.primary;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time Remaining',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textSubtle),
              ),
              Text(
                _formatTime(remaining),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final question = _questions[_currentIndex];
    final selected = _answers[_currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _subjectColor(question.subject).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.subject,
                  style: TextStyle(
                    color: _subjectColor(question.subject),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.chapter,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'Q${_currentIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(question.options.length, (i) {
            final option = question.options[i];
            final isSelected = selected == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOptionTile(
                label: _optionLabels[i],
                option: option,
                isSelected: isSelected,
                onTap: () => _selectAnswer(option),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String label,
    required String option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? AppColors.primary : AppColors.divider;
    final bgColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.surface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSubtle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final visibleFrom = widget.config.sectionLock
        ? _sectionStart[_currentSection]
        : 0;
    final visibleTo = widget.config.sectionLock
        ? _sectionStart[_currentSection] +
            _sectionQuestions[_currentSection].length
        : _questions.length;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleTo - visibleFrom,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final globalIndex = visibleFrom + i;
                return _buildPaletteChip(globalIndex);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildControlButton(
                icon: Icons.flag_outlined,
                label: _flagged.contains(_currentIndex) ? 'Flagged' : 'Flag',
                color: _flagged.contains(_currentIndex)
                    ? AppColors.warning
                    : AppColors.textSubtle,
                onTap: _toggleFlag,
              ),
              const Spacer(),
              IconButton(
                onPressed: _currentIndex > 0 ? _previous : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              const SizedBox(width: 4),
              if (widget.config.sectionLock &&
                  _isLastQuestionInSection &&
                  !_isLastSection)
                ElevatedButton(
                  onPressed: _goToNextSection,
                  child: Text(
                    widget.config.breaksEnabled &&
                            _currentSection ==
                                widget.config.breakAfterSectionIndex
                        ? 'Break ▸'
                        : 'Next Section ▸',
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _next,
                  icon: const Icon(Icons.chevron_right),
                  label: Text(
                    widget.config.sectionLock && _isLastSection
                        ? 'Submit'
                        : 'Next',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteChip(int globalIndex) {
    final isCurrent = globalIndex == _currentIndex;
    final isAnswered = _answers.containsKey(globalIndex);
    final isFlagged = _flagged.contains(globalIndex);

    Color bg = AppColors.background;
    Color fg = AppColors.textDark;
    if (isAnswered) {
      bg = AppColors.primary;
      fg = Colors.white;
    }
    if (isCurrent) {
      bg = AppColors.warning.withValues(alpha: 0.9);
      fg = Colors.white;
    }
    if (isFlagged && !isCurrent) {
      bg = AppColors.warning;
      fg = Colors.white;
    }

    return InkWell(
      onTap: () {
        if (widget.config.sectionLock &&
            _sectionOf(globalIndex) != _currentSection) {
          return;
        }
        _goTo(globalIndex);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.divider,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Text(
          '${globalIndex + 1}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildBreakView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.coffee,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Break Time',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have completed ${_activeSection.name}. '
              'Stretch, hydrate, and get ready for the next section.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _formatTime(_breakRemaining),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next section starts automatically',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSubtle),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: _skipBreak,
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip Break'),
            ),
          ],
        ),
      ),
    );
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return AppColors.physicsAccent;
      case 'chemistry':
        return AppColors.chemistryAccent;
      case 'biology':
        return AppColors.biologyAccent;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final h = safe ~/ 3600;
    final m = (safe % 3600) ~/ 60;
    final s = safe % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}
