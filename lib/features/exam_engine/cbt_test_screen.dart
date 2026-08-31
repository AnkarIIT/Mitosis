import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/question_model.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/exam_engine_service.dart';
import '../../core/services/exam_checkpoint_service.dart';
import '../../core/services/test_analytics_service.dart';
import '../../core/theme/app_colors.dart';

import 'package:go_router/go_router.dart';
import '../../core/database/drift_database.dart' as db;
import '../../core/theme/app_theme.dart';
import 'on_screen_calculator.dart';

enum _SessionPhase { taking, break_ }

class CbtTestScreen extends ConsumerStatefulWidget {
  final ExamConfig config;
  final List<Question> questionPool;

  /// When present, the screen restores this exact in-progress attempt (same
  /// questions, answers, flags and remaining time) instead of starting fresh.
  final ExamCheckpoint? resumeFrom;

  const CbtTestScreen({
    super.key,
    required this.config,
    required this.questionPool,
    this.resumeFrom,
  });

  @override
  ConsumerState<CbtTestScreen> createState() => _CbtTestScreenState();
}

class _CbtTestScreenState extends ConsumerState<CbtTestScreen>
    with WidgetsBindingObserver {
  static const _optionLabels = ['A', 'B', 'C', 'D'];

  Set<String>? _excludedIds;

  // Palette state colours (NTA-style).
  static const Color _cMarked = Color(0xFF7E57C2); // purple

  late final String _attemptId;
  late final int _seed;
  late final DateTime _startedAt;
  late final List<List<Question>> _sectionQuestions;
  late final List<Question> _questions;
  late final List<int> _sectionStart;
  final Map<int, String> _answers = {};
  final Set<int> _flagged = {};
  final Set<int> _visited = {};
  late final List<int> _secondsPerQuestion;

  Timer? _ticker;
  Timer? _autosaveTimer;
  _SessionPhase _phase = _SessionPhase.taking;

  /// Absolute wall-clock deadlines. Remaining time is always `deadline - now`,
  /// so there is no drift and no background truncation to compensate for.
  late DateTime _deadline;
  DateTime? _breakDeadline;
  DateTime? _sectionDeadline;

  /// When the user entered the current question — used to bank per-question
  /// time on leave/submit, which is accurate across backgrounding.
  DateTime? _questionEnteredAt;

  int _currentSection = 0;
  int _currentIndex = 0;
  bool _submitting = false;
  bool _submitted = false;
  bool _confirmDialogOpen = false;

  // Proctoring: fullscreen lock is on while the test is live, and leaving the
  // app (app-switch / background) during the answering phase counts as an
  // integrity violation. Count persists across crashes via the checkpoint.
  int _violations = 0;
  bool _fullscreenOn = false;

  bool get _checkpointable => widget.config.isFullLengthMock;

  int get _remainingSeconds {
    final diff = _deadline.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  int get _sectionRemainingSeconds {
    final d = _sectionDeadline;
    if (d == null) return -1; // no per-section limit
    final diff = d.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  int get _breakRemainingSeconds {
    final d = _breakDeadline;
    if (d == null) return 0;
    final diff = d.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _setFullscreen(true);

    // Exclude recently seen questions so each mock test feels fresh.
    final seen = ref.read(recentlySeenQuestionIdsProvider(null).future);
    seen.then((ids) {
      if (mounted) {
        setState(() => _excludedIds = ids);
      }
    });

    final resume = widget.resumeFrom;
    final rebuilt = resume != null ? _rebuildSections(resume) : null;

    // Check if we're replaying from a route with a seed
    final routeExtra =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final replaySeed = routeExtra?['seed'] as int?;
    final replayConfig = routeExtra?['config'] as ExamConfig?;
    final replayQuestionPool = routeExtra?['questionPool'] as List<Question>?;

    final bool isReplay = replaySeed != null;

    if (resume != null && rebuilt != null) {
      _attemptId = resume.attemptId;
      _seed = resume.attemptId.hashCode;
      _startedAt = DateTime.fromMillisecondsSinceEpoch(resume.startedAtEpochMs);
      _sectionQuestions = rebuilt;
      _deadline = DateTime.fromMillisecondsSinceEpoch(resume.deadlineEpochMs);
      _breakDeadline = resume.breakDeadlineEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(resume.breakDeadlineEpochMs!)
          : null;
      _sectionDeadline = resume.sectionDeadlineEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(resume.sectionDeadlineEpochMs!)
          : null;
      _phase = resume.phase == 'break_'
          ? _SessionPhase.break_
          : _SessionPhase.taking;
      for (final entry in resume.answersByIndex.entries) {
        final v = entry.value;
        if (v != null && v.isNotEmpty) _answers[entry.key] = v;
      }
      _flagged.addAll(resume.flagged);
      _visited.addAll(resume.visited);
      _violations = resume.violations;
    } else if (isReplay) {
      final seed = replaySeed;
      _attemptId = 'cbt_replay_${DateTime.now().millisecondsSinceEpoch}';
      _seed = seed;
      _startedAt = DateTime.now();
      final pool = replayQuestionPool ?? widget.questionPool;
      final config = replayConfig ?? widget.config;
      _sectionQuestions = ExamEngineService.allocateQuestions(
        pool,
        config,
        seed: _seed,
        excludedIds: _excludedIds,
      );
      _deadline = DateTime.now().add(
        Duration(seconds: config.totalDurationSeconds),
      );
      // Use the replay seed for the allocation
      _seed = seed;
    } else {
      _attemptId = 'cbt_${DateTime.now().millisecondsSinceEpoch}';
      _seed = DateTime.now().millisecondsSinceEpoch;
      _startedAt = DateTime.now();
      _sectionQuestions = ExamEngineService.allocateQuestions(
        widget.questionPool,
        widget.config,
        seed: _seed,
        excludedIds: _excludedIds,
      );
      _deadline = DateTime.now().add(
        Duration(seconds: widget.config.totalDurationSeconds),
      );
    }

    _questions = ExamEngineService.flattenAllocated(_sectionQuestions);
    _sectionStart = [];
    var acc = 0;
    for (final section in _sectionQuestions) {
      _sectionStart.add(acc);
      acc += section.length;
    }
    _secondsPerQuestion = List<int>.filled(_questions.length, 0);

    if (resume != null && rebuilt != null) {
      _currentSection = _sectionQuestions.isEmpty
          ? 0
          : resume.currentSection.clamp(0, _sectionQuestions.length - 1);
      _currentIndex = _questions.isEmpty
          ? 0
          : resume.currentIndex.clamp(0, _questions.length - 1);
    } else {
      _skipEmptySections();
      _currentIndex = _questions.isEmpty ? 0 : _sectionStart[_currentSection];
    }
    _initSectionDeadline();

    // 0.1: never start the ticker on an empty allocation — build() shows the
    // empty state and _onTick would otherwise index an empty list every second.
    if (_questions.isNotEmpty) {
      _visited.add(_currentIndex);
      _questionEnteredAt = DateTime.now();
      _startTicker();
      _startAutosave();
      if (_phase == _SessionPhase.taking && _remainingSeconds <= 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _submitTest(auto: true),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _autosaveTimer?.cancel();
    _setFullscreen(false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /// Turns the immersive fullscreen lock on (during the test) or off (when the
  /// screen is disposed) so the user can't peek at other apps' status bar /
  /// system UI. Restores normal chrome when the test ends.
  void _setFullscreen(bool on) {
    if (_fullscreenOn == on) return;
    _fullscreenOn = on;
    SystemChrome.setEnabledSystemUIMode(
      on ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    // Re-hide the overlays immediately so the change is visible without a
    // gesture; immersiveSticky already auto-hides but this makes it snappy.
    SystemChrome.restoreSystemUIOverlays();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_questions.isEmpty || _submitted) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Leaving the app during the answering phase is a proctoring violation.
      // We count it BEFORE backgrounding so a kill/resume can't dodge it.
      if (_phase == _SessionPhase.taking && !_submitting && !_submitted) {
        _violations++;
        if (mounted) setState(() {});
      }
      // Bank the current question's time and persist before we may be killed.
      _accrueTimeOnLeave();
      _questionEnteredAt = null;
      _ticker?.cancel();
      _ticker = null;
      _saveCheckpoint();
    } else if (state == AppLifecycleState.resumed) {
      _questionEnteredAt = DateTime.now();
      if (_phase == _SessionPhase.taking && _remainingSeconds <= 0) {
        _submitTest(auto: true);
        return;
      }
      if (_phase == _SessionPhase.break_ && _breakRemainingSeconds <= 0) {
        _advanceToSection(_currentSection + 1);
        return;
      }
      _startTicker();
      if (mounted) setState(() {});
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Setup helpers
  // ─────────────────────────────────────────────────────────────

  /// Rebuilds the per-section allocation from the checkpoint's saved question
  /// IDs. Returns null if any ID is missing from the pool (content changed),
  /// so we fall back to a fresh allocation rather than drift the indices.
  List<List<Question>>? _rebuildSections(ExamCheckpoint cp) {
    final byId = {for (final q in widget.questionPool) q.id: q};
    final rebuilt = <List<Question>>[];
    for (final ids in cp.sectionQuestionIds) {
      final sec = <Question>[];
      for (final id in ids) {
        final q = byId[id];
        if (q == null) return null;
        sec.add(q);
      }
      rebuilt.add(sec);
    }
    return rebuilt;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _startAutosave() {
    if (!_checkpointable) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _saveCheckpoint(),
    );
    _saveCheckpoint(); // initial save so a resume card exists immediately
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

  bool get _isLastQuestionOverall => widget.config.sectionLock
      ? _isLastSection && _isLastQuestionInSection
      : _currentIndex + 1 >= _questions.length;

  // ─────────────────────────────────────────────────────────────
  // Timekeeping
  // ─────────────────────────────────────────────────────────────

  void _initSectionDeadline() {
    final sectionDuration =
        widget.config.sections[_currentSection].durationSeconds;
    if (sectionDuration != null && sectionDuration > 0) {
      _sectionDeadline = DateTime.now().add(Duration(seconds: sectionDuration));
    } else {
      _sectionDeadline = null;
    }
  }

  void _onTick(Timer timer) {
    if (!mounted || _submitted) return;

    if (_phase == _SessionPhase.break_) {
      if (_breakRemainingSeconds <= 0) {
        _advanceToSection(_currentSection + 1);
      } else {
        setState(() {}); // repaint break countdown
      }
      return;
    }

    if (_sectionRemainingSeconds == 0) {
      _advanceToSection(_currentSection + 1);
      return;
    }

    if (_remainingSeconds <= 0) {
      _submitTest(auto: true);
      return;
    }
    setState(() {}); // repaint from wall clock — no arithmetic, no drift
  }

  void _accrueTimeOnLeave() {
    final enteredAt = _questionEnteredAt;
    if (enteredAt == null) return;
    if (_currentIndex >= 0 && _currentIndex < _secondsPerQuestion.length) {
      final delta = DateTime.now().difference(enteredAt).inSeconds;
      if (delta > 0 && delta < 86400) {
        _secondsPerQuestion[_currentIndex] += delta;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Answering & navigation
  // ─────────────────────────────────────────────────────────────

  void _selectAnswer(String option) {
    setState(() {
      _answers[_currentIndex] = option;
    });
    _saveCheckpoint();
  }

  void _clearResponse() {
    setState(() {
      _answers.remove(_currentIndex);
    });
    _saveCheckpoint();
  }

  void _toggleFlag() {
    setState(() {
      if (_flagged.contains(_currentIndex)) {
        _flagged.remove(_currentIndex);
      } else {
        _flagged.add(_currentIndex);
      }
    });
    _saveCheckpoint();
  }

  void _markForReviewAndNext() {
    setState(() {
      _flagged.add(_currentIndex);
    });
    _saveCheckpoint();
    _advance();
  }

  void _goTo(int globalIndex) {
    _accrueTimeOnLeave();
    setState(() {
      _currentIndex = globalIndex;
      _currentSection = _sectionOf(globalIndex);
      _visited.add(globalIndex);
    });
    _questionEnteredAt = DateTime.now();
    _saveCheckpoint();
  }

  /// Save & Next / Next Section / Submit, depending on position.
  void _advance() {
    if (_isLastQuestionOverall) {
      _confirmSubmit();
      return;
    }
    if (widget.config.sectionLock && _isLastQuestionInSection) {
      _goToNextSection();
      return;
    }
    if (_currentIndex + 1 < _questions.length) {
      _goTo(_currentIndex + 1);
    }
  }

  void _previous() {
    // 1.5: respect the section lock — never step before the section's first
    // question when locked.
    final lowerBound = widget.config.sectionLock
        ? _sectionStart[_currentSection]
        : 0;
    if (_currentIndex > lowerBound) {
      _goTo(_currentIndex - 1);
    }
  }

  void _goToNextSection() {
    if (widget.config.breaksEnabled &&
        _currentSection == widget.config.breakAfterSectionIndex) {
      _accrueTimeOnLeave();
      _questionEnteredAt = null;
      setState(() {
        _phase = _SessionPhase.break_;
        _breakDeadline = DateTime.now().add(
          Duration(seconds: widget.config.breakDurationSeconds),
        );
      });
      _saveCheckpoint();
      return;
    }
    _advanceToSection(_currentSection + 1);
  }

  void _advanceToSection(int index) {
    _accrueTimeOnLeave();
    var target = index;
    while (target < _sectionQuestions.length &&
        _sectionQuestions[target].isEmpty) {
      target++;
    }
    if (target >= _sectionQuestions.length) {
      _confirmSubmit();
      return;
    }
    setState(() {
      _currentSection = target;
      _currentIndex = _sectionStart[target];
      _visited.add(_currentIndex);
      _phase = _SessionPhase.taking;
      _breakDeadline = null;
    });
    _questionEnteredAt = DateTime.now();
    final sectionDuration = widget.config.sections[target].durationSeconds;
    if (sectionDuration != null && sectionDuration > 0) {
      _sectionDeadline = DateTime.now().add(Duration(seconds: sectionDuration));
    } else {
      _sectionDeadline = null;
    }
    _saveCheckpoint();
  }

  void _skipBreak() {
    _advanceToSection(_currentSection + 1);
  }

  // ─────────────────────────────────────────────────────────────
  // Checkpointing
  // ─────────────────────────────────────────────────────────────

  void _saveCheckpoint() {
    if (!_checkpointable || _submitted || !mounted || _questions.isEmpty) {
      return;
    }
    final cp = ExamCheckpoint(
      attemptId: _attemptId,
      configJson: widget.config.toJson(),
      sectionQuestionIds: [
        for (final sec in _sectionQuestions) [for (final q in sec) q.id],
      ],
      answersByIndex: {
        for (int i = 0; i < _questions.length; i++) i: _answers[i],
      },
      flagged: _flagged.toList(),
      visited: _visited.toList(),
      currentIndex: _currentIndex,
      currentSection: _currentSection,
      phase: _phase == _SessionPhase.break_ ? 'break_' : 'taking',
      deadlineEpochMs: _deadline.millisecondsSinceEpoch,
      breakDeadlineEpochMs: _breakDeadline?.millisecondsSinceEpoch,
      sectionDeadlineEpochMs: _sectionDeadline?.millisecondsSinceEpoch,
      startedAtEpochMs: _startedAt.millisecondsSinceEpoch,
      savedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      violations: _violations,
    );
    // Fire-and-forget; a failed autosave must never interrupt the test.
    ref.read(examCheckpointServiceProvider).save(cp).catchError((_) {});
  }

  Future<void> _clearCheckpoint() async {
    if (!_checkpointable) return;
    try {
      await ref.read(examCheckpointServiceProvider).clear();
    } catch (_) {}
    ref.invalidate(activeCbtCheckpointProvider);
  }

  // ─────────────────────────────────────────────────────────────
  // Submission
  // ─────────────────────────────────────────────────────────────

  void _openCalculator() {
    showOnScreenCalculator(context);
  }

  Future<void> _confirmSubmit() async {
    if (_submitting || _submitted) return;
    _confirmDialogOpen = true;    final confirmed = await showDialog<bool>(
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
    _confirmDialogOpen = false;
    // The deadline may have fired (auto-submit) while the dialog was open.
    if (_submitted || !mounted) return;
    if (confirmed == true) {
      await _submitTest();
    }
  }

  Future<void> _submitTest({bool auto = false}) async {
    if (_submitted) return;
    _submitted = true; // 1.6: synchronous guard — exactly one submit
    _accrueTimeOnLeave();
    _questionEnteredAt = null;
    _ticker?.cancel();
    _ticker = null;
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    if (mounted) setState(() => _submitting = true);

    final elapsed = widget.config.totalDurationSeconds - _remainingSeconds;
    final timeSpent = elapsed < 0 ? 0 : elapsed;

    final score = ExamEngineService.grade(
      config: widget.config,
      sectionQuestions: _sectionQuestions,
      answersByIndex: _answers,
    );
    final analytics = TestAnalyticsService.compute(
      score: score,
      secondsPerQuestion: _secondsPerQuestion,
    );

    // 2.3: per-section correct counts keyed by section name (analytics.subjects
    // is now section-keyed, so Botany and Zoology stay distinct).
    final subjectScores = {
      for (final entry in analytics.subjects.entries)
        entry.key: entry.value.correct,
    };

    final attempt = QuizAttempt(
      id: _attemptId,
      topicId: widget.config.topicId,
      subject: widget.config.subjectLabel,
      testType: widget.config.testType,
      subjectScores: subjectScores,
      score: score.correct,
      incorrectCount: score.incorrect,
      totalQuestions: score.results.length,
      timeSpentSeconds: timeSpent,
      attemptedAt: DateTime.now(),
      selectedAnswers: List.generate(
        _questions.length,
        (i) => _answers[i] ?? '',
      ),
      rawScore: score.rawScore,
      maxMarks: score.maxScore,
      seed: _seed,
    );

    await ref
        .read(userProgressProvider.notifier)
        .recordQuizAttempt(
          attempt,
          questions: _questions,
          answersByIndex: _answers,
          seed: _seed,
        );
    await _clearCheckpoint();

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final answer = _answers[i];
      final isCorrect = answer != null && answer == q.correctAnswer;
      if (!isCorrect) {
        final dbInstance = ref.read(databaseProvider);
        await dbInstance.addToErrorBook(
          db.ErrorBookCompanion.insert(
            questionId: q.id,
            addedAt: DateTime.now(),
          ),
        );
      }
    }

    if (!mounted) return;
    // Close the confirm dialog if the deadline fired while it was open.
    if (_confirmDialogOpen && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      _confirmDialogOpen = false;
    }
    context.go(
      '/cbt/result',
      extra: {
        'attempt': attempt,
        'analytics': analytics,
        'questions': _questions,
        'answersByIndex': _answers,
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mock Test'), elevation: 0),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No questions available for this test.\n\n'
              'Import or sync more questions and try again.',
              textAlign: TextAlign.center,
            ),
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
          _autosaveTimer?.cancel();
          await _clearCheckpoint();
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AdaptiveColors.surfaceWarm(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: AdaptiveColors.textPrimary(context)),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.config.mode == ExamMode.neet
                    ? 'NEET Mock Test'
                    : 'CBT Practice',
                style: TextStyle(
                  color: AdaptiveColors.textPrimary(context),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.config.sectionLock
                    ? 'Section ${_currentSection + 1} of '
                          '${_sectionQuestions.length} • ${_activeSection.name}'
                    : _activeSection.name,
                style: TextStyle(
                  color: AdaptiveColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            if (!_submitting)
              IconButton(
                tooltip: 'Calculator',
                icon: Icon(
                  Icons.calculate_outlined,
                  color: AdaptiveColors.textPrimary(context),
                ),
                onPressed: () => _openCalculator(),
              ),
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
    final remaining = _remainingSeconds;
    final total = widget.config.totalDurationSeconds;
    final progress = total <= 0 ? 1.0 : remaining / total;
    final color = remaining < 300
        ? AppColors.error
        : remaining < 600
        ? AppColors.warning
        : AppColors.primary;

    final sectionRemaining = _sectionRemainingSeconds;
    final sectionDuration =
        widget.config.sections[_currentSection].durationSeconds;

    return Container(
      color: AdaptiveColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionRemaining >= 0 ? 'Section Time' : 'Time Remaining',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
              ),
              Text(
                sectionRemaining >= 0
                    ? _formatTime(sectionRemaining)
                    : _formatTime(remaining),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: sectionRemaining >= 0 && sectionRemaining < 120
                      ? AppColors.error
                      : color,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (sectionRemaining >= 0 &&
              sectionDuration != null &&
              sectionDuration > 0) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: sectionDuration <= 0
                  ? 0.0
                  : (sectionDuration - sectionRemaining) / sectionDuration,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
              backgroundColor: AdaptiveColors.divider(context),
              valueColor: AlwaysStoppedAnimation(
                sectionRemaining < 120 ? AppColors.error : AppColors.primary,
              ),
            ),
          ],
          if (_violations > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gpp_maybe,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _violations == 1
                        ? 'Proctoring: You left the exam once'
                        : 'Proctoring: You left the exam $_violations times',
                    style: TextStyle(
                      fontSize: 12,
                      color: AdaptiveColors.textPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: AdaptiveColors.divider(context),
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
                  style: TextStyle(
                    color: AdaptiveColors.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'Q${_currentIndex + 1}/${_questions.length}',
                style: TextStyle(
                  color: AdaptiveColors.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Bookmark-style flag toggle: mark/unmark for review without
              // leaving the question (Mark & Next below both flags and advances).
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: _flagged.contains(_currentIndex)
                    ? 'Unmark for review'
                    : 'Mark for review',
                onPressed: _toggleFlag,
                icon: Icon(
                  _flagged.contains(_currentIndex)
                      ? Icons.flag
                      : Icons.flag_outlined,
                  size: 18,
                  color: _flagged.contains(_currentIndex)
                      ? _cMarked
                      : AdaptiveColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AdaptiveColors.textPrimary(context),
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
                label: i < _optionLabels.length ? _optionLabels[i] : '${i + 1}',
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
    final borderColor = isSelected
        ? AdaptiveColors.primary(context)
        : AdaptiveColors.divider(context);
    final bgColor = isSelected
        ? AdaptiveColors.primary(context).withValues(alpha: 0.08)
        : AdaptiveColors.surface(context);

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
                      ? AdaptiveColors.primary(context)
                      : AdaptiveColors.background(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AdaptiveColors.primary(context)
                        : AdaptiveColors.divider(context),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : AdaptiveColors.textSecondary(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: AdaptiveColors.textPrimary(context),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AdaptiveColors.primary(context),
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

    final hasAnswer = _answers.containsKey(_currentIndex);
    final lowerBound = widget.config.sectionLock
        ? _sectionStart[_currentSection]
        : 0;

    return Container(
      color: AdaptiveColors.surface(context),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPaletteLegend(),
          const SizedBox(height: 8),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasAnswer ? _clearResponse : null,
                  icon: const Icon(Icons.backspace_outlined, size: 16),
                  label: const Text('Clear', overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _markForReviewAndNext,
                  icon: Icon(
                    _flagged.contains(_currentIndex)
                        ? Icons.flag
                        : Icons.flag_outlined,
                    size: 16,
                    color: _cMarked,
                  ),
                  label: const Text(
                    'Mark & Next',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _currentIndex > lowerBound ? _previous : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              const Spacer(),
              _buildPrimaryAdvanceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAdvanceButton() {
    if (_isLastQuestionOverall) {
      return ElevatedButton.icon(
        onPressed: _confirmSubmit,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Submit'),
      );
    }
    if (widget.config.sectionLock && _isLastQuestionInSection) {
      final isBreak =
          widget.config.breaksEnabled &&
          _currentSection == widget.config.breakAfterSectionIndex;
      return ElevatedButton(
        onPressed: _goToNextSection,
        child: Text(isBreak ? 'Break ▸' : 'Next Section ▸'),
      );
    }
    return ElevatedButton.icon(
      onPressed: _advance,
      icon: const Icon(Icons.chevron_right),
      label: const Text('Save & Next'),
    );
  }

  Widget _buildPaletteLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        _legendDot(AppColors.success, 'Answered'),
        _legendDot(AppColors.error, 'Not answered'),
        _legendDot(_cMarked, 'Marked'),
        _legendDot(AdaptiveColors.divider(context), 'Not visited'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AdaptiveColors.textSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteChip(int globalIndex) {
    final isCurrent = globalIndex == _currentIndex;
    final isAnswered = _answers.containsKey(globalIndex);
    final isFlagged = _flagged.contains(globalIndex);
    final isVisited = _visited.contains(globalIndex);

    // Five NTA-style states.
    Color bg;
    Color fg = Colors.white;
    if (isAnswered && isFlagged) {
      bg = AppColors.success; // answered + marked (badge added below)
    } else if (isAnswered) {
      bg = AppColors.success;
    } else if (isFlagged) {
      bg = _cMarked;
    } else if (isVisited) {
      bg = AppColors.error;
    } else {
      bg = AdaptiveColors.background(context);
      fg = AdaptiveColors.textPrimary(context);
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? AdaptiveColors.primary(context)
                    : AdaptiveColors.divider(context),
                width: isCurrent ? 2.5 : 1,
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
          if (isAnswered && isFlagged)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _cMarked,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(Icons.flag, size: 8, color: Colors.white),
              ),
            ),
        ],
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
            const Icon(Icons.coffee, size: 64, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'Break Time',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have completed ${_activeSection.name}. '
              'Stretch, hydrate, and get ready for the next section.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _formatTime(_breakRemainingSeconds),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.primary(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next section starts automatically',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
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
