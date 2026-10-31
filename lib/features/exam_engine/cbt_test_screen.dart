import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/question_model.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/exam_engine_service.dart';
import '../../core/services/exam_checkpoint_service.dart';
import '../../core/services/secure_screen_service.dart';
import '../../core/services/question_inventory_service.dart';
import '../../core/services/test_analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

import 'package:go_router/go_router.dart';
import 'nta_palette.dart';
import 'on_screen_calculator.dart';

enum _SessionPhase { taking, break_ }

class CbtTestScreen extends ConsumerStatefulWidget {
  final ExamConfig config;
  final List<Question> questionPool;

  /// When present, the screen restores this exact in-progress attempt (same
  /// questions, answers, flags and remaining time) instead of starting fresh.
  final ExamCheckpoint? resumeFrom;

  /// Enforces strict exam conditions: fullscreen lock, no screenshot,
  /// no backgrounding, violation tracking. Defaults to true on desktop/web.
  final bool strictMode;

  const CbtTestScreen({
    super.key,
    required this.config,
    required this.questionPool,
    this.resumeFrom,
    this.strictMode = false,
  });

  @override
  ConsumerState<CbtTestScreen> createState() => _CbtTestScreenState();
}

class _CbtTestScreenState extends ConsumerState<CbtTestScreen>
    with WidgetsBindingObserver {
  Set<String>? _excludedIds;

  // Palette state colours (NTA-style).
  static const Color _cMarked = NtaPaletteColors.marked;

  late final String _attemptId;
  late final int _seed;
  late final DateTime _startedAt;
  late final List<List<Question>> _sectionQuestions;
  late final List<Question> _questions;
  late final List<int> _sectionStart;
  final Map<int, String> _answers = {};
  /// Options the candidate has clicked but not yet committed. NTA's CBT does
  /// not record an answer on selection: the palette only turns green after
  /// SAVE & NEXT or SAVE & MARK FOR REVIEW. Keeping the click here — instead
  /// of writing straight into [_answers] — makes the app tell the truth about
  /// what is stored, and trains the habit the real paper demands.
  final Map<int, String> _drafts = {};
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
  bool _warningOpen = false;

  /// NTA-style time warnings. Fired once each, only for full-length mocks and
  /// only while the candidate is answering (never during a break).
  bool _warned15 = false;
  bool _warned5 = false;

  /// True once `_questions`/`_deadline` have been assigned. Question allocation
  /// needs an async read (recently-seen exclusion), so `build()` and the
  /// lifecycle callback must not touch the `late` fields before then.
  bool _ready = false;

  // Proctoring: fullscreen lock is on while the test is live, and leaving the
  // app (app-switch / background) during the answering phase counts as an
  // integrity violation. Count persists across crashes via the checkpoint.
  int _violations = 0;
  bool _fullscreenOn = false;

  /// Wide-layout state of the `>` handle between the question pane and the
  /// palette panel — NTA's own collapse control.
  bool _paletteCollapsed = false;

  bool get _checkpointable => widget.config.isFullLengthMock;

  int get _remainingSeconds {
    // Round UP. `.inSeconds` truncates, so the clock reads 0 while up to 999ms
    // of time is actually left and auto-submit fired up to a second early.
    final ms = _deadline.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / 1000).ceil();
  }

  int get _sectionRemainingSeconds {
    final d = _sectionDeadline;
    if (d == null) return -1; // no per-section limit
    final ms = d.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / 1000).ceil();
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
    SecureScreenService.enable();

    // Strict mode: enforce additional proctoring on desktop/web
    if (widget.strictMode == true) {
      _enforceStrictMode();
    }

    _initializeExam();
  }

  /// Enforces strict exam conditions for desktop/web to simulate NTA CBT.
  void _enforceStrictMode() {
    // Already in immersive fullscreen via _setFullscreen
    // Additional: disable text selection, context menu, keyboard shortcuts
    // Note: Flutter web has limited control over browser-level shortcuts
    debugPrint('STRICT MODE: NTA CBT environment enforced (desktop/web)');
  }

  /// Allocates questions and restores session state.
  ///
  /// Runs async because excluding recently-seen questions needs a provider read
  /// that must complete *before* allocation. It used to be fire-and-forget, so
  /// `_excludedIds` was still null when `allocateQuestions` ran and the
  /// exclusion never applied. `_ready` gates `build()` and the lifecycle
  /// callback until the `late` fields are populated.
  Future<void> _initializeExam() async {
    final resume = widget.resumeFrom;
    final rebuilt = resume != null ? _rebuildSections(resume) : null;

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
      // NB: _secondsPerQuestion is `late final` and sized from _questions, which
      // is only assigned after this block. It is restored further below, once
      // _questions exists. Assigning it here threw LateInitializationError on
      // every resume.
    } else {
      _attemptId = 'cbt_${DateTime.now().millisecondsSinceEpoch}';
      _seed = DateTime.now().millisecondsSinceEpoch;
      _startedAt = DateTime.now();

      // Check question inventory for NEET 2024 mocks before allocating.
      if (ExamEngineService.isNeet2024(widget.config)) {
        final inventory = await ref
            .read(questionInventoryServiceProvider)
            .checkNeet2024Readiness();
        if (!inventory.isReady && mounted) {
          final shortages = ref
              .read(questionInventoryServiceProvider)
              .getShortageMessages(inventory);
          final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Insufficient Questions'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Not enough questions available for a full NEET 2024 mock.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...shortages.map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• $s', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please import more questions or sync from cloud before starting.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => context.pop(true),
                  child: const Text('Start Anyway'),
                ),
              ],
            ),
          );
          if (confirmed != true) {
            if (!mounted) return;
            context.pop(); // Go back to home
            return;
          }
        }
      }

      // Resolved BEFORE allocation so the exclusion actually applies.
      try {
        final seen = await ref.read(
          recentlySeenQuestionIdsProvider(null).future,
        );
        if (!mounted) return;
        _excludedIds = seen;
      } catch (_) {
        // Freshness is a nicety, not correctness — fall back to the full pool.
      }
      if (!mounted) return;

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

    if (resume != null && rebuilt != null) {
      _secondsPerQuestion = List<int>.filled(_questions.length, 0);
      for (final entry in resume.secondsPerQuestion.entries) {
        if (entry.key >= 0 && entry.key < _secondsPerQuestion.length) {
          _secondsPerQuestion[entry.key] = entry.value;
        }
      }
    } else {
      _secondsPerQuestion = List<int>.filled(_questions.length, 0);
    }

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
    // Only initialize section deadline if not resuming, or if no deadline was restored
    if (resume == null || _sectionDeadline == null) {
      _initSectionDeadline();
    }

    // Mark ready BEFORE starting the ticker. _onTick and
    // didChangeAppLifecycleState both bail on `!_ready`; setting it afterwards
    // made correctness depend on there being no event-loop turn between the two
    // statements.
    _ready = true;

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

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _autosaveTimer?.cancel();
    _setFullscreen(false);
    SecureScreenService.disable();
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
    if (!_ready || _questions.isEmpty || _submitted) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Leaving the app during the answering phase is a proctoring violation.
      //
      // Count ONLY on paused/detached. Flutter synthesizes `hidden` around
      // `inactive` on both iOS and Android, so a single Home-press round trip
      // emitted inactive -> hidden -> paused -> hidden -> inactive -> resumed
      // and the old branch counted `hidden` too: 3 violations for one app
      // switch, against an instructions screen that warns that more than 3 may
      // terminate the test.
      final isFullBackground =
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached;
      if (isFullBackground &&
          _phase == _SessionPhase.taking &&
          !_submitting &&
          !_submitted) {
        _violations++;
        if (mounted) setState(() {});
      }
      // Bank the current question's time and persist before we may be killed.
      // The save is fire-and-forget because lifecycle callbacks are synchronous,
      // but SharedPreferences writes are fast and the next user action will
      // also trigger a save, so the risk of data loss is minimal.
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

  /// Rebuilds the per-section allocation from the checkpoint.
  ///
  /// For v3+ checkpoints, uses the stored full question snapshots — resume
  /// works even if the question pool has changed. For older checkpoints,
  /// falls back to looking up IDs in the current pool; returns null if any ID
  /// is missing so we start fresh rather than drift indices.
  List<List<Question>>? _rebuildSections(ExamCheckpoint cp) {
    // v3+: full snapshots stored in the checkpoint itself.
    if (cp.sectionQuestions.isNotEmpty &&
        cp.sectionQuestions.length == cp.sectionQuestionIds.length) {
      return cp.sectionQuestions;
    }
    // v1/v2: look up IDs in the current pool.
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
    // Initial save so a resume card exists immediately. Fire-and-forget is fine
    // here because the first user action will also trigger a save.
    _saveCheckpoint();
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

  /// For NEET 2024: sections 0-3 = Section A block, 4-7 = Section B block
  bool get _isNeet2024 => ExamEngineService.isNeet2024(widget.config);
  int get _currentBlock => ExamEngineService.getNeet2024Block(_currentSection);
  bool get _inABlock => _currentBlock == 0;
  bool get _inBBlock => _currentBlock == 1;
  bool get _isABlockLastQuestion =>
      _inABlock && _isLastQuestionInSection && _currentSection == 3;
  bool get _isBBlockLastQuestion =>
      _inBBlock && _isLastQuestionInSection && _currentSection == 7;

  bool get _isLastQuestionInSection =>
      _currentIndex >=
      _sectionStart[_currentSection] +
          _sectionQuestions[_currentSection].length -
          1;

  bool get _isLastSection => _currentSection == _sectionQuestions.length - 1;

  bool get _isLastQuestionOverall {
    if (_isNeet2024) {
      return _isBBlockLastQuestion;
    }
    return widget.config.sectionLock
        ? _isLastSection && _isLastQuestionInSection
        : _currentIndex + 1 >= _questions.length;
  }

  /// Lower bound for navigation (Previous button).
  int get _navigationLowerBound {
    if (_isNeet2024) {
      if (_inBBlock &&
          _currentSection == 4 &&
          _currentIndex == _sectionStart[4]) {
        return _currentIndex; // Cannot go back to A-block from start of B-block
      }
      return _sectionStart[_currentSection];
    }
    return widget.config.sectionLock ? _sectionStart[_currentSection] : 0;
  }

  // ─────────────────────────────────────────────────────────────
  // Timekeeping
  // ─────────────────────────────────────────────────────────────

  /// Arms (or clears) the per-section deadline for section [index].
  ///
  /// Only meaningful when the paper actually locks by section.
  /// `ExamConfig.neet()` defaults `sectionLock` to false — the palette shows
  /// every question in one strip and free navigation is permitted — yet the
  /// deadline was still armed and enforced, silently teleporting the student to
  /// the next section at t+45min no matter where they had navigated to.
  void _armSectionDeadlineFor(int index) {
    if (!widget.config.sectionLock) {
      _sectionDeadline = null;
      return;
    }
    final sectionDuration = widget.config.sections[index].durationSeconds;
    _sectionDeadline = (sectionDuration != null && sectionDuration > 0)
        ? DateTime.now().add(Duration(seconds: sectionDuration))
        : null;
  }

  void _initSectionDeadline() => _armSectionDeadlineFor(_currentSection);

  Future<void> _onTick(Timer timer) async {
    if (!_ready || !mounted || _submitted) return;

    if (_phase == _SessionPhase.break_) {
      if (_breakRemainingSeconds <= 0) {
        _advanceToSection(_currentSection + 1);
      } else {
        setState(() {}); // repaint break countdown
      }
      return;
    }

    // The overall deadline is the hard bound, so it is checked FIRST. Previously
    // the section check returned early, which meant an expiring final section
    // masked auto-submit entirely: _advanceToSection could not find a next
    // section, left _sectionDeadline armed, and re-entered this branch every
    // second, stacking a new "Submit Test?" dialog on each tick.
    if (_remainingSeconds <= 0) {
      _submitTest(auto: true);
      return;
    }

    if (_sectionRemainingSeconds == 0) {
      await _advanceToSection(_currentSection + 1);
      return;
    }
    _maybeWarnTimeLeft();
    setState(() {}); // repaint from wall clock — no arithmetic, no drift
  }

  /// 15-minute and 5-minute warnings, as NTA shows them. Only full mocks get
  /// them: a 10-minute practice paper should not open with a "15 minutes left"
  /// popup, and short drills are not the exam the warning prepares you for.
  void _maybeWarnTimeLeft() {
    if (!_checkpointable ||
        _submitted ||
        _submitting ||
        _warningOpen ||
        _confirmDialogOpen ||
        _phase != _SessionPhase.taking) {
      return;
    }
    final remaining = _remainingSeconds;
    if (!_warned5 && remaining <= 300) {
      _warned5 = true;
      _warned15 = true;
      _showTimeWarning(5);
    } else if (!_warned15 && remaining <= 900) {
      _warned15 = true;
      _showTimeWarning(15);
    }
  }

  Future<void> _showTimeWarning(int minutes) async {
    if (!mounted) return;
    _warningOpen = true;
    final urgent = minutes <= 5;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Theme(
          data: _ntaTheme,
          child: AlertDialog(
            icon: Icon(
              Icons.timer_outlined,
              color: urgent ? NtaExamColors.danger : NtaExamColors.accent,
            ),
            title: Text('$minutes minutes remaining'),
            content: Text(
              urgent
                  ? 'Only $minutes minutes are left. Save your answers now. '
                        'The test is submitted automatically when the timer '
                        'reaches zero.'
                  : 'You have $minutes minutes left. Check the questions you '
                        'marked for review before submitting.',
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
    _warningOpen = false;
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

  /// Guards mutations that would desync the graded result from what the user
  /// sees. `score` is computed synchronously at submit, but the *live* `_answers`
  /// map is handed to the result screen — so a post-submit edit showed a
  /// different answer from the one that was actually scored.
  bool get _locked => _submitting || _submitted;

  Future<void> _selectAnswer(String option) async {
    if (_locked) return;
    setState(() {
      _drafts[_currentIndex] = option;
    });
    await _saveCheckpoint();
  }

  /// Moves the pending selection into the answer sheet. Called by SAVE & NEXT
  /// and SAVE & MARK FOR REVIEW, never by a plain click.
  void _commitCurrent() {
    final draft = _drafts.remove(_currentIndex);
    if (draft != null) {
      _answers[_currentIndex] = draft;
    }
  }

  Future<void> _clearResponse() async {
    if (_locked) return;
    setState(() {
      _drafts.remove(_currentIndex);
      _answers.remove(_currentIndex);
    });
    await _saveCheckpoint();
  }

  Future<void> _toggleFlag() async {
    setState(() {
      if (_flagged.contains(_currentIndex)) {
        _flagged.remove(_currentIndex);
      } else {
        _flagged.add(_currentIndex);
      }
    });
    await _saveCheckpoint();
  }

  Future<void> _markForReviewAndNext() async {
    setState(() {
      // MARK FOR REVIEW & NEXT flags without storing an answer.
      _drafts.remove(_currentIndex);
      _flagged.add(_currentIndex);
    });
    await _saveCheckpoint();
    _advance();
  }

  /// SAVE & NEXT: store the pending selection, then move on.
  Future<void> _saveAndNext() async {
    if (_locked) return;
    setState(_commitCurrent);
    await _saveCheckpoint();
    _advance();
  }

  /// SAVE & MARK FOR REVIEW: keeps whatever answer is selected and flags the
  /// question, then stays on it. That "stays" is the whole difference from
  /// MARK FOR REVIEW & NEXT, and it is what the real CBT does.
  Future<void> _saveAndMarkForReview() async {
    if (_locked) return;
    setState(() {
      _commitCurrent();
      _flagged.add(_currentIndex);
    });
    await _saveCheckpoint();
    _showNotice('Response saved and marked for review.');
  }

  Future<void> _goTo(int globalIndex) async {
    _accrueTimeOnLeave();

    // NEET 2024: enforce A-block/B-block navigation
    if (_isNeet2024) {
      final targetSection = _sectionOf(globalIndex);
      final targetBlock = ExamEngineService.getNeet2024Block(targetSection);

      // Cannot jump to B-block until A-block is explicitly advanced past
      if (_inABlock && targetBlock == 1 && !_isABlockLastQuestion) {
        // Never fail silently: a palette tap that does nothing reads as a bug.
        _showNotice('Submit Section A to unlock Section B.');
        return;
      }
      // Once in B-block, cannot go back to A-block via palette
      if (_inBBlock && targetBlock == 0) {
        _showNotice('Section A is closed once Section B has started.');
        return;
      }
    }

    // The draft belongs to the question being left, so read it before the
    // index moves.
    final droppedDraft = _drafts.remove(_currentIndex) != null;

    setState(() {
      _currentIndex = globalIndex;
      _currentSection = _sectionOf(globalIndex);
      _visited.add(globalIndex);
    });
    _questionEnteredAt = DateTime.now();
    await _saveCheckpoint();

    if (droppedDraft) {
      // Never lose a click silently: the real CBT drops unsaved selections,
      // and a student who has only ever used this app needs to be told.
      _showNotice('Answer not saved. Use SAVE & NEXT to store it.');
    }
  }

  /// Save & Next / Next Section / Submit, depending on position.
  void _advance() {
    if (_isLastQuestionOverall) {
      _confirmSubmit();
      return;
    }

    // NEET 2024: explicit A-block -> B-block transition
    if (_isNeet2024 && _isABlockLastQuestion) {
      _goToBBlock();
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
    // NEET 2024: respect block boundaries
    if (_isNeet2024) {
      if (_inBBlock &&
          _currentSection == 4 &&
          _currentIndex == _sectionStart[4]) {
        // At start of B-block, don't go back to A-block via Previous
        return;
      }
      // Within A-block, normal navigation
      final lowerBound = _sectionStart[_currentSection];
      if (_currentIndex > lowerBound) {
        _goTo(_currentIndex - 1);
      }
      return;
    }

    // Legacy logic
    final lowerBound = widget.config.sectionLock
        ? _sectionStart[_currentSection]
        : 0;
    if (_currentIndex > lowerBound) {
      _goTo(_currentIndex - 1);
    }
  }

  /// Explicit transition from A-block (section 3) to B-block (section 4).
  Future<void> _goToBBlock() async {
    if (!_isNeet2024 || !_isABlockLastQuestion) return;
    _accrueTimeOnLeave();
    setState(() {
      _currentSection = 4;
      _currentIndex = _sectionStart[4];
      _visited.add(_currentIndex);
      _phase = _SessionPhase.taking;
      _breakDeadline = null;
    });
    _questionEnteredAt = DateTime.now();
    _armSectionDeadlineFor(4);
    await _saveCheckpoint();
  }

  Future<void> _goToNextSection() async {
    // NEET 2024 doesn't use scheduled breaks
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
      await _saveCheckpoint();
      return;
    }
    await _advanceToSection(_currentSection + 1);
  }

  Future<void> _advanceToSection(int index) async {
    _accrueTimeOnLeave();

    // NEET 2024: enforce block progression.
    //
    // This must not be a silent `return`. The section deadline is still armed
    // at this point, so _onTick would call back here once per second for the
    // rest of the paper: the student sees a frozen clock, is never told their
    // block time expired, and is never advanced. Treat it exactly like
    // "no next section" — disarm the timer and escalate to a prompt, so the
    // student is never left stuck and can still choose to move on.
    if (_isNeet2024 && _inABlock && index >= 4) {
      setState(() => _sectionDeadline = null);
      if (_isABlockLastQuestion) {
        await _goToBBlock();
      } else {
        _confirmSubmit();
      }
      return;
    }

    var target = index;
    // Never skip ACROSS the A→B boundary while in block A. Skipping an empty
    // section 3 would land directly in section 4, bypassing the block
    // transition that only `_goToBBlock` is allowed to perform.
    final hardLimit =
        (_isNeet2024 && _inABlock && 4 <= _sectionQuestions.length)
        ? 4
        : _sectionQuestions.length;
    while (target < hardLimit && _sectionQuestions[target].isEmpty) {
      target++;
    }

    // Out of questions: either we hit the block boundary, or the paper ended.
    // `target >= hardLimit` short-circuits, so the second clause is never
    // evaluated with an out-of-range index.
    if (target >= hardLimit || _sectionQuestions[target].isEmpty) {
      setState(() => _sectionDeadline = null);
      if (_isNeet2024 && _inABlock) {
        if (_isABlockLastQuestion) {
          await _goToBBlock();
        } else {
          _confirmSubmit();
        }
      } else {
        _confirmSubmit();
      }
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
    _armSectionDeadlineFor(target);
    await _saveCheckpoint();
  }

  void _skipBreak() {
    _advanceToSection(_currentSection + 1);
  }

  // ─────────────────────────────────────────────────────────────
  // Checkpointing
  // ─────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────────
  // Checkpointing
  //
  // A full-length mock stores the complete question snapshot: measured at
  // ~159 KB of JSON, ~3.9 ms to encode, plus a SharedPreferences write of that
  // whole payload. That ran on EVERY answer tap, palette jump, flag toggle and
  // Mark & Next — and the call sites awaited it, so navigation blocked on a
  // disk write.
  //
  // Simply dropping the `await` is not safe: two rapid saves can land out of
  // order, leaving the checkpoint holding stale state — worse than the latency
  // it removes.
  //
  // So saves are coalesced behind a single in-flight writer: at most one
  // encode+write runs at a time, a save requested during one is recorded as
  // "dirty" and retried once when it finishes, and a caller awaiting during a
  // save returns immediately instead of queueing behind the disk.
  // ─────────────────────────────────────────────────────────────────────────────

  bool _checkpointWriteInFlight = false;
  bool _checkpointDirty = false;

  Future<bool> _saveCheckpoint() {
    if (!_checkpointable || _submitted || !mounted || _questions.isEmpty) {
      return Future<bool>.value(false);
    }
    if (_checkpointWriteInFlight) {
      // A write is already running. Ensure the newest state is written once it
      // finishes, rather than starting a competing one that could interleave.
      _checkpointDirty = true;
      return Future<bool>.value(false);
    }
    _checkpointWriteInFlight = true;
    return _writeCheckpoint().whenComplete(() {
      _checkpointWriteInFlight = false;
      if (_checkpointDirty && !_submitted && mounted) {
        _checkpointDirty = false;
        unawaited(_saveCheckpoint());
      }
    });
  }

  Future<bool> _writeCheckpoint() async {
    final cp = ExamCheckpoint(
      attemptId: _attemptId,
      configJson: widget.config.toJson(),
      sectionQuestionIds: [
        for (final sec in _sectionQuestions) [for (final q in sec) q.id],
      ],
      sectionQuestions: _sectionQuestions,
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
      secondsPerQuestion: Map<int, int>.from(_secondsPerQuestion.asMap()),
    );
    return ref.read(examCheckpointServiceProvider).save(cp);
  }

  Future<void> _clearCheckpoint() async {
    if (!_checkpointable) return;
    try {
      await ref.read(examCheckpointServiceProvider).clear();
    } catch (error) {
      debugPrint('CBT checkpoint clear failed: $error');
    }
    ref.invalidate(activeCbtCheckpointProvider);
  }

  // ─────────────────────────────────────────────────────────────
  // Submission
  // ─────────────────────────────────────────────────────────────

  void _openCalculator() {
    showOnScreenCalculator(context);
  }

  Future<void> _confirmSubmit() async {
    if (_submitting || _submitted || _warningOpen) return;
    _confirmDialogOpen = true;
    final summary = _summaryFor(
      List<int>.generate(_questions.length, (i) => i),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var declared = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Theme(
              data: _ntaTheme,
              child: AlertDialog(
                title: const Text('Submit Test?'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review your attempt before submitting. '
                        'Answers cannot be changed afterwards.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AdaptiveColors.textSecondary(dialogContext),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_drafts.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE0A800)),
                          ),
                          child: Text(
                            '${_drafts.length} selected '
                            '${_drafts.length == 1 ? 'answer was' : 'answers were'} '
                            'never saved and will be marked Not Answered. '
                            'Close this and press SAVE & NEXT to keep '
                            '${_drafts.length == 1 ? 'it' : 'them'}.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: Color(0xFF8A5B00),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _summaryRow(
                        dialogContext,
                        'No. of Questions',
                        summary.total,
                        bold: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: NtaCountRow(
                          state: NtaPaletteState.notVisited,
                          count: summary.notVisited,
                          fontSize: 12.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: NtaCountRow(
                          state: NtaPaletteState.notAnswered,
                          count: summary.notAnswered,
                          fontSize: 12.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: NtaCountRow(
                          state: NtaPaletteState.answered,
                          count: summary.answered,
                          fontSize: 12.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: NtaCountRow(
                          state: NtaPaletteState.marked,
                          count: summary.marked,
                          fontSize: 12.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: NtaCountRow(
                          state: NtaPaletteState.answeredMarked,
                          count: summary.answeredMarked,
                          note: 'will be considered for evaluation',
                          fontSize: 12.5,
                        ),
                      ),
                      const Divider(height: 24),
                      InkWell(
                        onTap: () => setDialogState(() => declared = !declared),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: declared,
                              onChanged: (value) => setDialogState(
                                () => declared = value ?? false,
                              ),
                            ),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'I have read and understood the '
                                  'instructions. I declare that I am not in '
                                  'possession of, or indulging in, any unfair '
                                  'means.',
                                  style: TextStyle(fontSize: 12, height: 1.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('No, Go Back'),
                  ),
                  FilledButton(
                    onPressed: declared
                        ? () => Navigator.of(dialogContext).pop(true)
                        : null,
                    child: const Text('Yes, Submit'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _confirmDialogOpen = false;
    // The deadline may have fired (auto-submit) while the dialog was open.
    if (_submitted || !mounted) return;
    if (confirmed == true) {
      await _submitTest();
    }
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    int value, {
    Color? color,
    bool bold = false,
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              note == null ? label : '$label\n$note',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: AdaptiveColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color == null
                  ? AdaptiveColors.surfaceContainerHighest(context)
                  : color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color ?? AdaptiveColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTest({bool auto = false}) async {
    if (_submitted) return;
    _submitted = true; // synchronous guard — exactly one submit per session
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

    // per-section correct counts keyed by section name (analytics.subjects
    // is now section-keyed, so Botany and Zoology stay distinct).
    final subjectScores = <String, int>{
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

    // Persist the attempt. If this fails, we retry up to 3 times before
    // giving up — a lost attempt is a lost user session.
    bool recorded = false;
    for (int attemptNum = 1; attemptNum <= 3 && !recorded; attemptNum++) {
      try {
        await ref
            .read(userProgressProvider.notifier)
            .recordQuizAttempt(
              attempt,
              questions: _questions,
              answersByIndex: _answers,
              seed: _seed,
            );
        recorded = true;
      } catch (e) {
        if (attemptNum == 3) {
          debugPrint('Failed to record quiz attempt after 3 attempts: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save attempt after 3 attempts. '
                'Your progress is saved locally and will retry on next launch.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
          // DO NOT clear checkpoint — keep it for retry on next launch.
          // But the screen MUST be un-wedged: `_submitting` gates the app bar
          // (the Submit button is replaced by a spinner), and `_locked` blocks
          // answering, advancing and re-confirming. Leaving both set produced a
          // screen that looked alive but could never be submitted again — and
          // the only escape was the exit dialog, which *destroys* the very
          // checkpoint this comment says to preserve.
          setState(() {
            _submitting = false;
            _submitted = false;
          });
          return;
        } else {
          await Future.delayed(Duration(milliseconds: 100 * attemptNum));
        }
      }
    }

    // Only clear checkpoint AFTER successful save
    await _clearCheckpoint();

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

  /// The NTA light theme used by the paper, its dialogs and its sheets. Kept in
  /// one place so a dialog opened from the screen's own context (which sits
  /// above the in-tree `Theme`) still matches the exam chrome in dark mode.
  ThemeData get _ntaTheme => AppTheme.lightTheme.copyWith(
    scaffoldBackgroundColor: NtaExamColors.page,
    colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
      primary: NtaExamColors.accent,
      surface: NtaExamColors.surface,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        await _requestExit();
      },
      child: Theme(
        // The paper screen is deliberately NTA light even when the rest of the
        // app is in dark mode: it is an exam interface, and candidates should
        // see the same blue-on-white chrome they will meet on the real CBT.
        // The app's font and text scale are preserved.
        data: _ntaTheme,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: NtaExamColors.surface,
            body: Column(
              children: [
                // 1. Thin navy strip with the Home link.
                Container(
                  color: NtaExamColors.navy,
                  child: SafeArea(bottom: false, child: _buildTopBar(context)),
                ),
                // 2. White logo band.
                _buildLogoBand(context),
                // 3. Candidate strip: photo, identity, subject, clock.
                _buildCandidateStrip(context),
                // 4. Section tabs (an addition — the reference paper was a
                //    single-section JEE paper, NEET needs them).
                _buildSectionBar(context),
                if (_violations > 0) _buildViolationBanner(context),
                Expanded(
                  child: _phase == _SessionPhase.break_
                      ? _buildBreakView()
                      : LayoutBuilder(
                          builder: (context, constraints) => _buildQuestionArea(
                            context,
                            isWide: constraints.maxWidth >= 760,
                          ),
                        ),
                ),
                // 5. Copyright strip.
                Container(
                  color: NtaExamColors.navy,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 2),
                    child: _buildFooterBar(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Exit confirmation, shared by the system back gesture (PopScope) and the
  /// Home link in the top strip.
  Future<void> _requestExit() async {
    if (!_ready || _questions.isEmpty) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    if (_phase == _SessionPhase.break_) {
      _skipBreak();
      return;
    }
    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: _ntaTheme,
        child: AlertDialog(
          title: const Text('Exit Test?'),
          content: Text(
            _checkpointable
                ? 'Your answers are auto-saved. You can resume this attempt '
                      'later from the mock test screen.'
                : 'This practice paper is not saved. Leaving now loses the '
                      'attempt.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
    if (exit != true || !mounted) return;
    _ticker?.cancel();
    _autosaveTimer?.cancel();
    await _clearCheckpoint();
    if (mounted) Navigator.of(context).pop();
  }

  // ─────────────────────────────────────────────────────────────
  // Exam chrome (NTA-style)
  // ─────────────────────────────────────────────────────────────

  /// 1. Thin navy strip. The reference page carries its Home link here, and it
  /// is the only way out of a live paper, so it routes through the same
  /// confirmation as the system back gesture.
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: NtaExamColors.navy,
      child: Row(
        children: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _requestExit,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. White logo band. A real CBT page carries the agency and ministry
  /// lockups here; this app ships no government artwork, so the same two-block
  /// composition is rebuilt from type.
  Widget _buildLogoBand(BuildContext context) {
    const agency = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'National Testing Agency',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: NtaExamColors.navy,
          ),
        ),
        Text(
          'Excellence In Assessment',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8.5,
            height: 1.25,
            color: NtaExamColors.green,
          ),
        ),
      ],
    );
    const ministry = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ministry of Education',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: NtaExamColors.text,
          ),
        ),
        Text(
          'Government of India',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8.5,
            height: 1.25,
            color: NtaExamColors.textMuted,
          ),
        ),
      ],
    );

    return Container(
      color: NtaExamColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NtaExamColors.navy,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NTA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: agency),
              if (wide) ...[
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: NtaExamColors.border,
                ),
                const Expanded(child: ministry),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 3. Candidate strip: photo box, identity, exam, subject and the remaining
  /// clock as a blue pill — the layout every NTA candidate knows.
  Widget _buildCandidateStrip(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final name = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : (user?.username ?? (auth.isGuest ? 'Guest Candidate' : 'Candidate'));
    final examName = widget.config.mode == ExamMode.neet
        ? 'NEET (UG) Mock Test'
        : 'CBT Practice';
    final subject = widget.config.subjectLabel.trim().isEmpty
        ? widget.config.testType
        : widget.config.subjectLabel.trim();
    final remaining = _remainingSeconds;
    final urgent = remaining <= 300;

    return Container(
      color: const Color(0xFFF4F6F9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NtaExamColors.surface,
              border: Border.all(color: NtaExamColors.chromeBorder),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.person, size: 38, color: Color(0xFF8A9099)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _candidateRow(
                  'Candidate Name',
                  name,
                  NtaExamColors.valueOrange,
                ),
                _candidateRow('Exam Name', examName, NtaExamColors.valueBlue),
                _candidateRow(
                  'Subject Name',
                  subject,
                  NtaExamColors.valueOrange,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  // Wrap, not Row: at 360px with 1.3x text the label plus the
                  // pill can exceed the column, and a wrap drops the pill to
                  // the next line instead of overflowing the strip.
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      _candidateLabel('Remaining Time'),
                      const Text(
                        ' : ',
                        style: TextStyle(
                          fontSize: 11,
                          color: NtaExamColors.text,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: urgent
                              ? NtaExamColors.danger
                              : NtaExamColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _formatClock(remaining),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            // Capped so the identity labels always keep a usable width: the
            // language box plus two icon buttons would otherwise take a third
            // of a 360px strip and squeeze the values to an ellipsis.
            constraints: const BoxConstraints(maxWidth: 104),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLanguageBox(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Calculator',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 34,
                      ),
                      icon: const Icon(
                        Icons.calculate_outlined,
                        size: 20,
                        color: NtaExamColors.navy,
                      ),
                      onPressed: _openCalculator,
                    ),
                    IconButton(
                      tooltip: 'Question palette',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 34,
                      ),
                      icon: Badge.count(
                        count: _answers.length,
                        isLabelVisible: _answers.isNotEmpty,
                        backgroundColor: NtaPaletteColors.answered,
                        child: const Icon(
                          Icons.grid_view_rounded,
                          size: 20,
                          color: NtaExamColors.navy,
                        ),
                      ),
                      onPressed: _showPaletteSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidateRow(String label, String value, Color valueColor) {
    // Wrap rather than Row: the label and the separator are fixed width, so on
    // a narrow strip the value drops to its own line instead of overflowing.
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 0,
        children: [
          _candidateLabel(label),
          const Text(
            ' : ',
            style: TextStyle(fontSize: 11, color: NtaExamColors.text),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidateLabel(String label) => Text(
    label,
    maxLines: 1,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: NtaExamColors.text,
    ),
  );

  Widget _buildLanguageBox() {
    return Material(
      color: NtaExamColors.surface,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: _showLanguageSheet,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: NtaExamColors.chromeBorder),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'English',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NtaExamColors.text,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: NtaExamColors.text,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The dropdown is kept because candidates look for it; it opens and says
  /// plainly that this paper has one language rather than doing nothing.
  void _showLanguageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NtaExamColors.surface,
      builder: (sheetContext) => Theme(
        data: _ntaTheme,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Language',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NtaExamColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FB),
                    border: Border.all(color: NtaExamColors.accent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: NtaExamColors.accent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'English',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: NtaExamColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This paper is available in English only.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: NtaExamColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navy copyright strip. The reference page credits the testing agency; this
  /// app is not the agency, so the line carries the app's own name.
  Widget _buildFooterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: NtaExamColors.navy,
      child: const Text(
        '© All Rights Reserved - NEET Mitos',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9.5,
          letterSpacing: 0.2,
          color: Colors.white70,
        ),
      ),
    );
  }

  /// 4. Section tabs. The reference paper is a single-section JEE paper and has
  /// no tabs, but NEET cannot be sat without them, so the strip is kept and
  /// dressed in the same grey/blue tab chrome as the rest of the page.
  Widget _buildSectionBar(BuildContext context) {
    final sectionRemaining = _sectionRemainingSeconds;
    final showTabs = _sectionQuestions.length > 1;
    if (!showTabs && sectionRemaining < 0) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        color: NtaExamColors.surface,
        border: Border(bottom: BorderSide(color: NtaExamColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTabs) SizedBox(height: 42, child: _buildSectionTabs(context)),
          if (sectionRemaining >= 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: sectionRemaining < 120
                  ? const Color(0xFFFDECEC)
                  : const Color(0xFFF4F7FB),
              child: Text(
                'Section time left : ${_formatTime(sectionRemaining)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: sectionRemaining < 120
                      ? NtaExamColors.danger
                      : NtaExamColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs(BuildContext context) {
    if (_sectionQuestions.length <= 1) return const SizedBox.shrink();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      itemCount: _sectionQuestions.length,
      separatorBuilder: (_, _) => const SizedBox(width: 4),
      itemBuilder: (context, i) {
        final isActive = i == _currentSection;
        final isLocked = _isSectionLocked(i);
        final start = _sectionStart[i];
        final end = start + _sectionQuestions[i].length;
        var answered = 0;
        for (var q = start; q < end; q++) {
          if (_answers.containsKey(q)) answered++;
        }
        final foreground = isActive
            ? Colors.white
            : (isLocked ? NtaExamColors.textMuted : NtaExamColors.text);
        return Material(
          color: isActive
              ? NtaExamColors.accent
              : (isLocked ? const Color(0xFFF1F4F8) : const Color(0xFFE8EDF4)),
          borderRadius: BorderRadius.circular(3),
          child: InkWell(
            onTap: () => _jumpToSection(i),
            borderRadius: BorderRadius.circular(3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLocked) ...[
                    Icon(Icons.lock_outline, size: 12, color: foreground),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    widget.config.sections[i].name.toUpperCase(),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$answered/${_sectionQuestions[i].length}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white70
                          : NtaExamColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildViolationBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AdaptiveColors.warning(context).withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(
            Icons.gpp_maybe,
            size: 14,
            color: AdaptiveColors.warning(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _violations == 1
                  ? 'Proctoring: you left the exam once'
                  : 'Proctoring: you left the exam $_violations times',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AdaptiveColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section tab locks. NEET 2024 has two blocks: B stays sealed until A is
  /// submitted, and A is closed once B has started. Section-locked papers
  /// (per-section timing) lock every section except the active one.
  bool _isSectionLocked(int index) {
    if (index == _currentSection) return false;
    if (_isNeet2024) {
      if (_inABlock && index >= 4) return true;
      if (_inBBlock && index < 4) return true;
      return false;
    }
    return widget.config.sectionLock;
  }

  String get _lockedSectionMessage => _isNeet2024
      ? (_inABlock
            ? 'Submit Section A to unlock Section B.'
            : 'Section A is closed once Section B has started.')
      : 'This paper is section-locked. Finish the current section to continue.';

  void _jumpToSection(int index) {
    if (index == _currentSection) return;
    if (_isSectionLocked(index)) {
      _showNotice(_lockedSectionMessage);
      return;
    }
    _goTo(_sectionStart[index]);
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Question pane + palette. The palette is a fixed side panel on tablets and
  /// desktop (NTA's own layout, complete with the `>` collapse handle between
  /// the panes), and a bottom sheet on phones where 320px of side panel would
  /// leave no room for the question itself.
  Widget _buildQuestionArea(BuildContext context, {required bool isWide}) {
    final questionPane = ColoredBox(
      color: NtaExamColors.surface,
      child: Column(
        children: [
          Expanded(child: _buildQuestionView()),
          _buildActionBar(context),
        ],
      ),
    );
    if (!isWide) return questionPane;

    return Row(
      children: [
        Expanded(child: questionPane),
        Material(
          color: NtaExamColors.navy,
          child: InkWell(
            onTap: () => setState(() => _paletteCollapsed = !_paletteCollapsed),
            child: SizedBox(
              width: 22,
              child: Center(
                child: Icon(
                  _paletteCollapsed ? Icons.chevron_left : Icons.chevron_right,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        if (!_paletteCollapsed)
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: NtaExamColors.surface,
              border: Border(left: BorderSide(color: NtaExamColors.border)),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: NtaQuestionPalette(
                sections: _paletteSections(),
                answers: _answers,
                marked: _flagged,
                visited: _visited,
                currentIndex: _currentIndex,
                onJump: _goTo,
                onSubmit: _confirmSubmit,
                onShowPaper: _showQuestionPaper,
                onShowInstructions: _showInstructionsSheet,
                lockedMessage: _lockedSectionMessage,
              ),
            ),
          ),
      ],
    );
  }

  void _showPaletteSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: NtaExamColors.surface,
      builder: (sheetContext) {
        return Theme(
          data: _ntaTheme,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.78,
              child: NtaQuestionPalette(
                sections: _paletteSections(),
                answers: _answers,
                marked: _flagged,
                visited: _visited,
                currentIndex: _currentIndex,
                onJump: (index) {
                  Navigator.of(sheetContext).pop();
                  _goTo(index);
                },
                onSubmit: () {
                  Navigator.of(sheetContext).pop();
                  _confirmSubmit();
                },
                onShowPaper: () {
                  Navigator.of(sheetContext).pop();
                  _showQuestionPaper();
                },
                onShowInstructions: () {
                  Navigator.of(sheetContext).pop();
                  _showInstructionsSheet();
                },
                lockedMessage: _lockedSectionMessage,
              ),
            ),
          ),
        );
      },
    );
  }

  static const List<String> _examRules = [
    'The Remaining Time in the candidate strip is the total time left. It does '
        'not pause, even if you leave a question unanswered.',
    'SAVE & NEXT stores an answer and moves on. CLEAR removes the selected '
        'answer.',
    'SAVE & MARK FOR REVIEW stores the answer and flags the question, keeping '
        'you on it. MARK FOR REVIEW & NEXT flags without storing an answer and '
        'moves on.',
    'The palette colours show the status of every question: answered, not '
        'answered, not visited, marked, and answered & marked.',
    'You can answer questions in any order inside the open section. A section '
        'showing a lock opens only after the previous section is submitted.',
    'The test is submitted automatically when the timer reaches zero.',
    'Do not switch apps, take screenshots or leave the exam. Violations are '
        'recorded with the attempt.',
  ];

  /// NTA's "Instructions" action from the palette footer: a read-only reminder
  /// of the rules, available without leaving the paper.
  void _showInstructionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: NtaExamColors.surface,
      builder: (sheetContext) {
        return Theme(
          data: _ntaTheme,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: NtaExamColors.text,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < _examRules.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      child: Text(
                                        '${i + 1}.',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: NtaExamColors.accent,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _examRules[i],
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          height: 1.45,
                                          color: NtaExamColors.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 42,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: NtaExamColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// NTA's "Question Paper" action: the whole paper, read-only, with live
  /// status chips. Tapping a row jumps to that question.
  void _showQuestionPaper() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: NtaExamColors.surface,
      builder: (sheetContext) {
        return Theme(
          data: _ntaTheme,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question Paper',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: NtaExamColors.text,
                                ),
                              ),
                              Text(
                                'View only · tap a question to jump to it',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: NtaExamColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: NtaExamColors.border),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                      itemCount: _questions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final question = _questions[i];
                        final state = ntaPaletteStateFor(
                          answered: _answers.containsKey(i),
                          marked: _flagged.contains(i),
                          visited: _visited.contains(i),
                        );
                        final locked = _isSectionLocked(_sectionOf(i));
                        return Opacity(
                          opacity: locked ? 0.5 : 1,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              if (locked) {
                                _showNotice(_lockedSectionMessage);
                                return;
                              }
                              _goTo(i);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: i == _currentIndex
                                      ? NtaExamColors.accent
                                      : NtaExamColors.border,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: NtaPaletteColors.fill(state),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color:
                                            state == NtaPaletteState.notVisited
                                            ? NtaExamColors.border
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: NtaPaletteColors.foreground(
                                          state,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          question.questionText,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.4,
                                            color: NtaExamColors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${question.subject} · '
                                          '${NtaPaletteColors.label(state)}',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: NtaExamColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<int> _indicesForSection(int s) => [
    for (
      var i = _sectionStart[s];
      i < _sectionStart[s] + _sectionQuestions[s].length;
      i++
    )
      i,
  ];

  List<NtaPaletteSection> _paletteSections() {
    final List<NtaPaletteSection> sections;
    if (_isNeet2024) {
      final split = _sectionStart[4];
      sections = [
        NtaPaletteSection(
          name: 'Section A · compulsory',
          indices: [for (var i = 0; i < split; i++) i],
          locked: _inBBlock,
        ),
        NtaPaletteSection(
          name: 'Section B · attempt 10 of 15',
          indices: [for (var i = split; i < _questions.length; i++) i],
          locked: _inABlock,
        ),
      ];
    } else {
      sections = [
        for (var s = 0; s < _sectionQuestions.length; s++)
          NtaPaletteSection(
            name: widget.config.sections[s].name,
            indices: _indicesForSection(s),
            locked: widget.config.sectionLock && s != _currentSection,
          ),
      ];
    }
    final nonEmpty = sections.where((s) => s.indices.isNotEmpty).toList();
    return nonEmpty.isEmpty ? sections : nonEmpty;
  }

  NtaCountSummary _summaryFor(Iterable<int> indices) => NtaCountSummary.from(
    indices: indices,
    answers: _answers,
    marked: _flagged,
    visited: _visited,
  );

  Widget _buildQuestionView() {
    final question = _questions[_currentIndex];
    final selected = _drafts[_currentIndex] ?? _answers[_currentIndex];
    final isFlagged = _flagged.contains(_currentIndex);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${_currentIndex + 1}:',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: NtaExamColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: NtaExamColors.border),
                ),
                child: Text(
                  'Marks: +${widget.config.marksPerCorrect} / '
                  '${widget.config.marksPerWrong}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: NtaExamColors.textMuted,
                  ),
                ),
              ),
              // Bookmark-style flag toggle: mark/unmark for review without
              // leaving the question (the mark buttons below both advance).
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                tooltip: isFlagged ? 'Unmark for review' : 'Mark for review',
                onPressed: _toggleFlag,
                icon: Icon(
                  isFlagged ? Icons.flag : Icons.flag_outlined,
                  size: 18,
                  color: isFlagged ? _cMarked : NtaExamColors.textMuted,
                ),
              ),
              const SizedBox(width: 2),
              // The reference page's blue circular arrow, which moves on.
              Tooltip(
                message: _isLastQuestionOverall
                    ? 'Submit test'
                    : 'Go to next question',
                child: Material(
                  color: NtaExamColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _locked
                        ? null
                        : (_isLastQuestionOverall ? _confirmSubmit : _advance),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        Icons.arrow_downward,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: NtaExamColors.hairline),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _subjectColor(question.subject).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  question.subject,
                  style: TextStyle(
                    color: _subjectColor(question.subject),
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.config.sectionLock
                      ? '${question.chapter} · ${_activeSection.name}'
                      : question.chapter,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NtaExamColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: NtaExamColors.text,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(question.options.length, (i) {
            final option = question.options[i];
            final isSelected = selected == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildOptionTile(
                label: '${i + 1}',
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

  /// NTA option row: a plain radio, the option label, then the text. Selected
  /// rows tint blue and thicken the border instead of growing a shadow.
  Widget _buildOptionTile({
    required String label,
    required String option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFFE8F0FB) : NtaExamColors.surface,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? NtaExamColors.accent : NtaExamColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NtaExamColors.surface,
                  border: Border.all(
                    color: isSelected
                        ? NtaExamColors.accent
                        : NtaExamColors.textMuted,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: NtaExamColors.accent,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                '$label.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? NtaExamColors.accent
                      : NtaExamColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  option,
                  style: const TextStyle(
                    color: NtaExamColors.text,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// NTA control rows, in the reference's own order and colours:
  ///
  ///   SAVE & NEXT (green) · CLEAR (white) · SAVE & MARK FOR REVIEW (orange) ·
  ///   MARK FOR REVIEW & NEXT (blue)
  ///
  /// and beneath them the grey strip `<< BACK` · `NEXT >>` ... `SUBMIT`.
  /// Wide panes fit the four in one row; phones get two rows of two, because
  /// MARK FOR REVIEW & NEXT cannot share a 360px row with three siblings.
  Widget _buildActionBar(BuildContext context) {
    final hasAnswer =
        _answers.containsKey(_currentIndex) ||
        _drafts.containsKey(_currentIndex);
    final canGoPrevious = _currentIndex > _navigationLowerBound;

    const buttonText = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    );

    FilledButton filled(String label, Color background, VoidCallback? onTap) {
      return FilledButton(
        onPressed: _locked ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFBFC7D2),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 42),
          shape: shape,
          textStyle: buttonText,
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    OutlinedButton outlined(String label, VoidCallback? onTap) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: NtaExamColors.surface,
          foregroundColor: NtaExamColors.text,
          disabledForegroundColor: const Color(0xFF9AA2AE),
          side: const BorderSide(color: NtaExamColors.chromeBorder),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 42),
          shape: shape,
          textStyle: buttonText,
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    // Row 1 — the four answering controls.
    final saveNext = filled(
      'SAVE & NEXT',
      NtaExamColors.saveGreen,
      _saveAndNext,
    );
    final clear = outlined(
      'CLEAR',
      hasAnswer && !_locked ? _clearResponse : null,
    );
    final saveMark = filled(
      'SAVE & MARK FOR REVIEW',
      NtaExamColors.saveOrange,
      _saveAndMarkForReview,
    );
    final markNext = filled(
      'MARK FOR REVIEW & NEXT',
      NtaExamColors.markBlue,
      _markForReviewAndNext,
    );

    // Row 2 — plain navigation plus the always-reachable submit.
    final back = outlined('<< BACK', canGoPrevious ? _previous : null);
    final next = outlined('NEXT >>', _advance);
    final submit = filled('SUBMIT', NtaExamColors.saveGreen, _confirmSubmit);

    return Container(
      decoration: const BoxDecoration(
        color: NtaExamColors.surface,
        border: Border(top: BorderSide(color: NtaExamColors.border)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        minimum: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final oneRow = constraints.maxWidth >= 620;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (oneRow)
                  Row(
                    children: [
                      Expanded(child: saveNext),
                      const SizedBox(width: 8),
                      Expanded(child: clear),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: saveMark),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: markNext),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(child: saveNext),
                      const SizedBox(width: 8),
                      Expanded(child: clear),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: saveMark),
                      const SizedBox(width: 8),
                      Expanded(child: markNext),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: NtaExamColors.chrome,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: NtaExamColors.chromeBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: back),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: next),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: submit),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
            const Icon(Icons.coffee, size: 64, color: NtaExamColors.accent),
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
                color: NtaExamColors.accent,
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

  /// NTA's total clock is always HH:MM:SS, even under an hour.
  String _formatClock(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final h = safe ~/ 3600;
    final m = (safe % 3600) ~/ 60;
    final s = safe % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
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
