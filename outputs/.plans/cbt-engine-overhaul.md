# CBT Exam Engine — God-Level Overhaul Plan

> **Status:** Ready for implementation
> **Prerequisite decisions locked:**
> 1. Configurable `ExamConfig`, modern default = 180Q/180min/all-compulsory
> 2. Auto-save & resume with absolute-deadline checkpoint
> 3. Percentile/AIR labeled rough estimate, gated to full mocks only

---

## Current State (Verified)

| File | Line(s) | Issue |
|---|---|---|
| `exam_engine_service.dart` | 52 | `ExamConfig.neet()` defaults to **200 min**, `sectionLock: true`, `breaksEnabled: true` — legacy 2021-2024 pattern |
| `exam_engine_service.dart` | 229 | `grade()` compares raw text, no trim — scoring can disagree with error book |
| `exam_engine_service.dart` | 209 | `allocateQuestions` O(n²) via `remaining.removeWhere(taken.contains)` |
| `cbt_test_screen.dart` | 69 | Ticker starts unconditionally — crashes with `RangeError` if pool empty |
| `cbt_test_screen.dart` | 158 | `_secondsPerQuestion[_currentIndex]++` per tick — drift + crash vector |
| `cbt_test_screen.dart` | 90-108 | Background handling subtracts `backgroundSeconds` from `_remainingSeconds` — double-counts if app is killed |
| `cbt_test_screen.dart` | 168-169 | Re-tap silently clears answer (no explicit Clear button) |
| `cbt_test_screen.dart` | 211 | `_previous()` ignores `sectionLock` — can go back before section start |
| `cbt_test_screen.dart` | 298 | Only `score.correct` persisted; no rawScore/maxMarks |
| `cbt_test_screen.dart` | 280-297 | Subject scores collapse Botany+Zoology into "Biology" |
| `cbt_test_screen.dart` | 711-750 | Palette chip collapses states — answered+flagged loses answered color |
| `cbt_result_screen.dart` | 144-168 | `_buildRankEstimates` shown **unconditionally** for every test |
| `user_progress_model.dart` | 99 | `neetScore => (score * 4) - incorrectCount` — hardcoded, two sources of truth |
| `quiz_attempts_table.dart` | 1-17 | No `rawScore`/`maxMarks` columns |
| `drift_database.dart` | 54 | `schemaVersion` = 21 |
| `app_router.dart` | 247-251 | `/cbt/result` force-assigns nullable `args['attempt']`/`args['analytics']` — crash on deep link |
| `test_analytics_service.dart` | 192-194 | `_neetApplicants = 2,400,000` — hardcoded fantasy number |
| `user_providers.dart` | 147-164 | `recordQuizAttempt` not wrapped in transaction — half-write on crash |

---

## Phase 0 (P0) — Crash & Data Integrity

**Goal:** No crash vectors, single source of truth for marks, atomic writes.

### 0.1 Empty-pool guard (`cbt_test_screen.dart`)

**Current:** `initState` calls `_ticker = Timer.periodic(...)` at line 69 unconditionally. If `_questions` is empty, `_onTick` at line 158 indexes `_secondsPerQuestion[_currentIndex]` → `RangeError`.

**Fix:**
```dart
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

  // NEW: guard empty pool
  if (_questions.isEmpty) {
    // Do NOT start ticker; build() shows empty state
    return;
  }

  _skipEmptySections();
  _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
}
```

**Also add** `ExamEngineService.validatePool`:
```dart
static List<Question> validatePool(List<Question> pool) {
  return pool.where((q) {
    final opts = q.options.map((o) => o.trim()).where((o) => o.isNotEmpty).toList();
    final correct = q.correctAnswer.trim();
    if (opts.length < 2) return false;
    if (correct.isEmpty) return false;
    if (!opts.contains(correct)) return false;
    if (q.questionText.trim().isEmpty) return false;
    return true;
  }).toList();
}
```

**Launcher** (`test_series_screen.dart`): call `validatePool` before navigating to `/cbt`. Show "Not enough valid questions" if result is empty.

### 0.2 Persist real ±marks (single source of truth)

**Current:** `QuizAttempt` has `score` (correct count) and `incorrectCount`. `neetScore` getter re-derives with hardcoded `*4 -1`. `recordQuizAttempt` inserts only `score` + `incorrectCount`.

**Fix:**

1. **Add columns** to `quiz_attempts_table.dart`:
```dart
IntColumn get rawScore => integer().nullable()();
IntColumn get maxMarks => integer().nullable()();
```

2. **Bump schemaVersion** in `drift_database.dart` from 21 → 22:
```dart
if (from < 22) {
  await _addColumnSafely(m, quizAttempts, (quizAttempts as dynamic).rawScore);
  await _addColumnSafely(m, quizAttempts, (quizAttempts as dynamic).maxMarks);
}
```

3. **Update `QuizAttempt` model** (`user_progress_model.dart`):
```dart
final int? rawScore;
final int? maxMarks;

QuizAttempt({
  // ... existing fields
  this.rawScore,
  this.maxMarks,
});

int get neetScore => rawScore ?? ((score * 4) - incorrectCount);
int get maxScore => maxMarks ?? (totalQuestions * 4);
```

4. **Thread through** `user_providers.dart` line 147 insert + line 81 row→model mapping.

5. **Regenerate Drift:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 0.3 One answer-matcher, normalized

**Current:** `grade()` at line 229 compares `answer == q.correctAnswer` raw. Error-book/SR re-grade at `user_providers.dart:178` does `answer == q.correctAnswer` again. Two places, no normalization.

**Fix:**
```dart
static bool isAnswerCorrect(String? answer, Question q) {
  if (answer == null) return false;
  return answer.trim() == q.correctAnswer.trim();
}
```

Use in `grade()` and `recordQuizAttempt` re-grade loop.

### 0.4 Atomic write

**Current:** `recordQuizAttempt` does insert + error-book + spaced-repetition writes sequentially. Crash mid-way leaves half-recorded attempt.

**Fix:** Wrap in `_db.transaction`:
```dart
await _db.transaction(() async {
  await _db.insertQuizAttempt(...);
  // error book writes
  // spaced repetition writes
});
```

Reuse the existing `transaction()` pattern at `drift_database.dart:526`.

---

## Phase 1 (P1) — NEET Fidelity

**Goal:** Configurable patterns, deadline timer, crash recovery.

### 1.1 `ExamConfig` / `ExamSection` express compulsory + optional N-of-M

**Current:** `ExamSection` has `questionCount` only. `ExamConfig.neet()` hardcodes 200 min, sectionLock=true, breaks=true.

**Fix:**

```dart
class ExamSection {
  final int index;
  final String name;
  final String sourceSubject;
  final int presentedCount;   // M: total shown
  final int gradedCount;      // N: counted toward score

  const ExamSection({
    required this.index,
    required this.name,
    required this.sourceSubject,
    this.presentedCount = 0,
    this.gradedCount = 0,
  });

  bool get isOptional => gradedCount < presentedCount;
  int get questionCount => presentedCount; // back-compat alias
}
```

```dart
class ExamConfig {
  // ... existing fields ...
  final bool isFullLengthMock;

  const ExamConfig({
    // ... existing params ...
    this.isFullLengthMock = false,
  });

  int get totalPresented => sections.fold(0, (s, x) => s + x.presentedCount);
  int get totalGraded => sections.fold(0, (s, x) => s + x.gradedCount);
  int get maxScoreTotal => totalGraded * marksPerCorrect;

  factory ExamConfig.neet2025_2026() {
    // Modern flat mock: 180Q, 180min, all compulsory
    return ExamConfig(
      mode: ExamMode.neet,
      testType: 'mock',
      topicId: 'mock_test',
      subjectLabel: 'NEET',
      totalDurationSeconds: 180 * 60,
      sectionLock: false,
      breaksEnabled: false,
      breakDurationSeconds: 0,
      breakAfterSectionIndex: -1,
      marksPerCorrect: 4,
      marksPerWrong: -1,
      sections: [
        ExamSection(index: 0, name: 'Physics', sourceSubject: 'Physics', presentedCount: 45, gradedCount: 45),
        ExamSection(index: 1, name: 'Chemistry', sourceSubject: 'Chemistry', presentedCount: 45, gradedCount: 45),
        ExamSection(index: 2, name: 'Botany', sourceSubject: 'Biology', presentedCount: 45, gradedCount: 45),
        ExamSection(index: 3, name: 'Zoology', sourceSubject: 'Biology', presentedCount: 45, gradedCount: 45),
      ],
      isFullLengthMock: true,
    );
  }

  factory ExamConfig.neetWithOptionalB() {
    // Legacy 2021-2024: 200Q with Section B optional
    return ExamConfig(
      mode: ExamMode.neet,
      testType: 'mock',
      topicId: 'mock_test',
      subjectLabel: 'NEET',
      totalDurationSeconds: 200 * 60,
      sectionLock: true,
      breaksEnabled: true,
      breakDurationSeconds: 5 * 60,
      breakAfterSectionIndex: 1,
      marksPerCorrect: 4,
      marksPerWrong: -1,
      sections: [
        ExamSection(index: 0, name: 'Physics', sourceSubject: 'Physics', presentedCount: 50, gradedCount: 45),
        ExamSection(index: 1, name: 'Chemistry', sourceSubject: 'Chemistry', presentedCount: 50, gradedCount: 45),
        ExamSection(index: 2, name: 'Botany', sourceSubject: 'Biology', presentedCount: 50, gradedCount: 45),
        ExamSection(index: 3, name: 'Zoology', sourceSubject: 'Biology', presentedCount: 50, gradedCount: 45),
      ],
      isFullLengthMock: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'testType': testType,
    'topicId': topicId,
    'subjectLabel': subjectLabel,
    'totalDurationSeconds': totalDurationSeconds,
    'sectionLock': sectionLock,
    'breaksEnabled': breaksEnabled,
    'breakDurationSeconds': breakDurationSeconds,
    'breakAfterSectionIndex': breakAfterSectionIndex,
    'marksPerCorrect': marksPerCorrect,
    'marksPerWrong': marksPerWrong,
    'sections': sections.map((s) => {
      'index': s.index,
      'name': s.name,
      'sourceSubject': s.sourceSubject,
      'presentedCount': s.presentedCount,
      'gradedCount': s.gradedCount,
    }).toList(),
    'isFullLengthMock': isFullLengthMock,
  };

  factory ExamConfig.fromJson(Map<String, dynamic> json) {
    return ExamConfig(
      mode: ExamMode.values.firstWhere((e) => e.name == json['mode']),
      testType: json['testType'],
      topicId: json['topicId'],
      subjectLabel: json['subjectLabel'],
      totalDurationSeconds: json['totalDurationSeconds'],
      sectionLock: json['sectionLock'],
      breaksEnabled: json['breaksEnabled'],
      breakDurationSeconds: json['breakDurationSeconds'],
      breakAfterSectionIndex: json['breakAfterSectionIndex'],
      marksPerCorrect: json['marksPerCorrect'],
      marksPerWrong: json['marksPerWrong'],
      sections: (json['sections'] as List).map((s) => ExamSection(
        index: s['index'],
        name: s['name'],
        sourceSubject: s['sourceSubject'],
        presentedCount: s['presentedCount'],
        gradedCount: s['gradedCount'],
      )).toList(),
      isFullLengthMock: json['isFullLengthMock'] ?? false,
    );
  }
}
```

**Important:** The default `ExamConfig.neet()` is **deprecated** — replace callers with `ExamConfig.neet2025_2026()` or `ExamConfig.neetWithOptionalB()`. Keep `neet()` temporarily as a deprecated alias pointing to `neet2025_2026()` if needed, but update all internal callers.

### 1.2 Grade N-of-M correctly

**Current:** `grade()` takes flat `List<Question>` + `Map<int, String?>`. No section awareness.

**Fix:**
```dart
class QuestionResult {
  final Question question;
  final String? selectedAnswer;
  final int marks;
  final bool counted; // whether this answer counts toward score

  const QuestionResult({
    required this.question,
    required this.selectedAnswer,
    required this.marks,
    this.counted = true,
  });

  bool get isCorrect => counted && selectedAnswer != null && selectedAnswer == question.correctAnswer;
  bool get isIncorrect => counted && selectedAnswer != null && selectedAnswer != question.correctAnswer;
  bool get isUnanswered => selectedAnswer == null;
  bool get isDiscarded => selectedAnswer != null && !counted;
}

static ExamScore grade({
  required ExamConfig config,
  required List<List<Question>> sectionQuestions,
  required Map<int, String?> answersByIndex,
}) {
  final results = <QuestionResult>[];
  int globalOffset = 0;

  for (int s = 0; s < sectionQuestions.length; s++) {
    final section = sectionQuestions[s];
    final examSection = config.sections[s];
    final gradedCount = examSection.gradedCount;
    var answeredInSection = 0;

    for (int i = 0; i < section.length; i++) {
      final globalIndex = globalOffset + i;
      final q = section[i];
      final raw = answersByIndex[globalIndex];
      final answer = (raw == null || raw.isEmpty) ? null : raw;

      bool counted = true;
      if (examSection.isOptional && answer != null) {
        if (answeredInSection < gradedCount) {
          answeredInSection++;
        } else {
          counted = false; // beyond cap: discarded
        }
      }

      bool correct = false;
      if (answer != null) {
        correct = isAnswerCorrect(answer, q);
      }

      results.add(QuestionResult(
        question: q,
        selectedAnswer: answer,
        marks: counted
            ? (correct ? config.marksPerCorrect : (answer == null ? 0 : config.marksPerWrong))
            : 0, // discarded: 0 marks, not penalized
        counted: counted,
      ));
    }
    globalOffset += section.length;
  }

  return ExamScore(config: config, results: results);
}
```

**Update `ExamScore`:**
```dart
int get rawScore => results.fold(0, (sum, r) => sum + r.marks);
int get maxScore => config.maxScoreTotal;
```

### 1.3 Deadline-based timer (fixes drift)

**Current:** Decrementing `_remainingSeconds` counter. Background handling subtracts `backgroundSeconds` — loses time if app is killed.

**Fix:**
```dart
class _CbtTestScreenState extends ConsumerState<CbtTestScreen> with WidgetsBindingObserver {
  late DateTime _deadline;               // absolute end time
  DateTime? _breakDeadline;              // absolute break end time
  DateTime? _questionEnteredAt;          // for per-question timing
  Timer? _ticker;
  // ... remove _pausedAt, remove backgroundSeconds logic

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sectionQuestions = ExamEngineService.allocateQuestions(
      widget.questionPool,
      widget.config,
    );
    _questions = ExamEngineService.flattenAllocated(_sectionQuestions);
    // ... sectionStart, secondsPerQuestion

    if (_questions.isEmpty) return; // guard from 0.1

    _skipEmptySections();
    _deadline = DateTime.now().add(Duration(seconds: widget.config.totalDurationSeconds));
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) {
      _ticker?.cancel();
      _ticker = null;
    } else if (state == AppLifecycleState.resumed && _ticker == null && !_submitted) {
      _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
      final remaining = _deadline.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _submitTest(auto: true);
      }
    }
  }

  void _onTick(Timer timer) {
    if (!mounted || _submitted) return;

    if (_phase == _SessionPhase.break_) {
      if (_breakDeadline != null && DateTime.now().isAfter(_breakDeadline!)) {
        _advanceToSection(_currentSection + 1);
      }
      return;
    }

    setState(() {}); // repaint only

    if (DateTime.now().isAfter(_deadline)) {
      _remainingSeconds = 0;
      _submitTest(auto: true);
    }
  }

  int get _remainingSeconds {
    final remaining = _deadline.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // Per-question timing via timestamps
  void _goTo(int globalIndex) {
    final now = DateTime.now();
    if (_questionEnteredAt != null && _currentIndex >= 0 && _currentIndex < _questions.length) {
      final delta = now.difference(_questionEnteredAt!).inSeconds.clamp(0, 3600);
      _secondsPerQuestion[_currentIndex] += delta;
    }
    _questionEnteredAt = now;
    setState(() {
      _currentIndex = globalIndex;
      _currentSection = _sectionOf(globalIndex);
    });
  }
}
```

**Key insight:** No more `_remainingSeconds--` arithmetic. The ticker only repaints. Time is derived from `_deadline - DateTime.now()`. If the app is killed and relaunched with a checkpoint, the deadline is restored as an epoch millis — no drift possible.

### 1.4 Auto-save & resume

**New file:** `lib/core/services/exam_checkpoint_service.dart`
```dart
class ExamCheckpoint {
  final String attemptId;
  final String configJson;
  final List<List<String>> sectionQuestionIds;
  final Map<String, String?> answersByIndex; // String keys for JSON
  final Set<String> flagged;
  final Set<String> visited;
  final int currentIndex;
  final int currentSection;
  String phase; // 'taking' | 'break_'
  final int deadlineEpochMs;
  final int? breakDeadlineEpochMs;
  final int startedAtEpochMs;

  ExamCheckpoint({
    required this.attemptId,
    required this.configJson,
    required this.sectionQuestionIds,
    required this.answersByIndex,
    required this.flagged,
    required this.visited,
    required this.currentIndex,
    required this.currentSection,
    required this.phase,
    required this.deadlineEpochMs,
    this.breakDeadlineEpochMs,
    required this.startedAtEpochMs,
  });

  factory ExamCheckpoint.fromAttempt({
    required ExamConfig config,
    required List<List<Question>> sectionQuestions,
    required Map<int, String?> answersByIndex,
    required Set<int> flagged,
    required Set<int> visited,
    required int currentIndex,
    required int currentSection,
    required String phase,
    required DateTime deadline,
    required DateTime startedAt,
    DateTime? breakDeadline,
  }) {
    return ExamCheckpoint(
      attemptId: 'cbt_${DateTime.now().millisecondsSinceEpoch}',
      configJson: jsonEncode(config.toJson()),
      sectionQuestionIds: sectionQuestions.map((s) => s.map((q) => q.id).toList()).toList(),
      answersByIndex: {for (final e in answersByIndex.entries) e.key.toString(): e.value},
      flagged: flagged.map((i) => i.toString()).toSet(),
      visited: visited.map((i) => i.toString()).toSet(),
      currentIndex: currentIndex,
      currentSection: currentSection,
      phase: phase,
      deadlineEpochMs: deadline.millisecondsSinceEpoch,
      breakDeadlineEpochMs: breakDeadline?.millisecondsSinceEpoch,
      startedAtEpochMs: startedAt.millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => { ... };
  factory ExamCheckpoint.fromJson(Map<String, dynamic> json) => ...;
}

class ExamCheckpointService {
  static const _key = 'cbt_active_checkpoint';
  final SharedPreferences _prefs;

  ExamCheckpointService(this._prefs);

  Future<void> save(ExamCheckpoint checkpoint) async {
    await _prefs.setString(_key, jsonEncode(checkpoint.toJson()));
  }

  ExamCheckpoint? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return ExamCheckpoint.fromJson(jsonDecode(raw));
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
```

**Checkpoint triggers in `cbt_test_screen.dart`:**
- On answer change (`_selectAnswer`)
- On flag toggle (`_toggleFlag`)
- On navigation (`_goTo`)
- On section/phase change
- On `_submitTest` → `clear()`
- On confirmed exit → `clear()`
- Autosave `Timer.periodic(Duration(seconds: 15), (_) => _saveCheckpoint())`

**Resume flow:**
1. `activeCbtCheckpointProvider` in `user_providers.dart` exposes `ExamCheckpoint?`
2. Home tab shows **"Resume Mock Test"** card when checkpoint exists, with Discard button
3. `test_series_screen.dart` shows same card
4. `/cbt` route accepts `resumeCheckpoint` extra
5. `CbtTestScreen.initState` restores: rebuild `_sectionQuestions` from saved IDs, restore answers/flags/visited/index/phase, set `_deadline` from epoch

**Critical:** Resume restores the **exact same question IDs** — no re-shuffle. This is why we persist `sectionQuestionIds`, not just counts.

### 1.5 Section-lock `_previous()` bypass

**Current:** `_previous()` at line 211 ignores `sectionLock`:
```dart
void _previous() {
  if (_currentIndex > 0) {
    _goTo(_currentIndex - 1);
  }
}
```

**Fix:**
```dart
void _previous() {
  final lowerBound = widget.config.sectionLock
      ? _sectionStart[_currentSection]
      : 0;
  if (_currentIndex > lowerBound) {
    _goTo(_currentIndex - 1);
  }
}
```

### 1.6 Auto-submit vs. Submit-dialog race

**Current:** `_submitTest` and `_confirmSubmit` can race if timer fires while dialog is open. Possible double-submit.

**Fix:**
```dart
Future<void> _confirmSubmit() async {
  if (_submitting || _submitted) return;
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true || !mounted) return;
  if (_submitted) return; // guard: timer fired during dialog
  await _submitTest();
}

Future<void> _submitTest({bool auto = false}) async {
  if (_submitting || _submitted) return;
  _submitting = true;
  _submitted = true; // synchronous — prevents re-entry
  _ticker?.cancel();
  _ticker = null;
  // ... rest of submit
}
```

---

## Phase 2 (P2) — UX Polish & Analytics Honesty

### 2.1 Five-state question palette

**Current:** `_buildPaletteChip` at line 711 collapses states:
```dart
if (isAnswered) { bg = primary; fg = white; }
if (isCurrent) { bg = warning; fg = white; }
if (isFlagged && !isCurrent) { bg = warning; fg = white; }
```
Answered+flagged loses answered color.

**Fix:**
```dart
enum PaletteState { notVisited, notAnswered, answered, marked, answeredAndMarked }

PaletteState _paletteState(int globalIndex) {
  final isAnswered = _answers.containsKey(globalIndex);
  final isFlagged = _flagged.contains(globalIndex);
  final isCurrent = globalIndex == _currentIndex;

  if (isCurrent) return PaletteState.notAnswered; // current overrides
  if (isAnswered && isFlagged) return PaletteState.answeredAndMarked;
  if (isAnswered) return PaletteState.answered;
  if (isFlagged) return PaletteState.marked;
  if (_visited.contains(globalIndex)) return PaletteState.notAnswered;
  return PaletteState.notVisited;
}

// Add _visited Set<int>, add in _goTo: _visited.add(globalIndex);
```

Render with NTA-style colors:
- notVisited: neutral gray
- notAnswered: red/orange
- answered: green
- marked: purple
- answeredAndMarked: green base + flag badge overlay

Add small legend row below palette.

### 2.2 NTA controls: Clear Response / Save & Next / Mark & Next

**Current:** Re-tap clears answer silently (line 168-169).

**Fix:**
```dart
void _selectAnswer(String option) {
  setState(() {
    _answers[_currentIndex] = option; // no silent clear
  });
}

// Add explicit buttons in _buildBottomControls:
Row(
  children: [
    TextButton.icon(
      onPressed: _answers.containsKey(_currentIndex) ? () {
        setState(() { _answers.remove(_currentIndex); });
      } : null,
      icon: Icon(Icons.clear, size: 18),
      label: Text('Clear'),
    ),
    if (widget.config.sectionLock && _isLastQuestionInSection && !_isLastSection)
      ElevatedButton(onPressed: _goToNextSection, child: Text('Next Section ▸'))
    else
      ElevatedButton.icon(
        onPressed: () { _toggleFlag(); _next(); },
        icon: Icon(Icons.flag_outlined),
        label: Text('Mark & Next'),
      ),
    ElevatedButton.icon(
      onPressed: _next,
      icon: Icon(Icons.chevron_right),
      label: Text('Save & Next'),
    ),
  ],
)
```

### 2.3 Faithful subject breakdown (Botany vs Zoology)

**Current:** `_submitTest` builds `subjectScores` from `analytics.subjects` keyed by `question.subject`, collapsing Botany+Zoology.

**Fix:** Build from section structure:
```dart
final sectionScores = <String, Map<String, int>>{};
for (int s = 0; s < _sectionQuestions.length; s++) {
  final sectionName = widget.config.sections[s].name;
  final sectionQs = _sectionQuestions[s];
  int startOffset = _sectionStart[s];
  int correct = 0, incorrect = 0, unanswered = 0;
  for (int i = 0; i < sectionQs.length; i++) {
    final result = analytics.score.results[startOffset + i];
    if (result.isCorrect) correct++;
    else if (result.isIncorrect) incorrect++;
    else unanswered++;
  }
  sectionScores[sectionName] = {'correct': correct, 'incorrect': incorrect, 'unanswered': unanswered};
}
```

Pass `sectionScores` to result screen and render all four subjects.

### 2.4 Percentile/AIR: labeled estimate + gated to full mocks

**Current:** `_buildRankEstimates` shown unconditionally for every test.

**Fix:**

1. `test_analytics_service.dart`:
```dart
class TestAnalytics {
  // ... existing fields ...
  final bool showRankEstimate;

  const TestAnalytics({
    // ... existing params ...
    this.showRankEstimate = false,
  });
}

static TestAnalytics compute(...) {
  // ...
  final showRank = score.config.isFullLengthMock;
  return TestAnalytics(
    // ...
    percentileEstimate: showRank ? estimatePercentile(score.rawScore, score.maxScore) : 0,
    airEstimate: showRank ? estimateAir(percentile) : 0,
    showRankEstimate: showRank,
  );
}
```

2. `cbt_result_screen.dart`:
```dart
if (analytics.showRankEstimate)
  Column(
    children: [
      _buildRankEstimates(context),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Rough estimate — not an official NEET rank/percentile.',
          style: TextStyle(fontSize: 11, color: AppColors.textSubtle, fontStyle: FontStyle.italic),
        ),
      ),
    ],
  )
```

### 2.5 `/cbt/result` null-safety

**Current:**
```dart
return CbtResultScreen(
  attempt: args['attempt'],       // force-assign nullable to non-nullable
  analytics: args['analytics'],   // crash if route reached without extra
);
```

**Fix:**
```dart
final attempt = args['attempt'] as QuizAttempt?;
final analytics = args['analytics'] as TestAnalytics?;
if (attempt == null || analytics == null) {
  return Scaffold(body: Center(child: Text('No result data. Please retake the test.')));
}
return CbtResultScreen(attempt: attempt, analytics: analytics);
```

---

## Phase 3 (P3) — Cleanup

### 3.1 Delete dead stub
`lib/features/quiz/test_result_screen.dart` — confirm with grep that router imports only `test_series/test_result_screen.dart`, then delete.

### 3.2 Remove stale files
- `temp_output.txt` if present
- `outputs/project-analysis.md` if present

---

## Implementation Order (Recommended)

| Order | Task | Risk | Effort |
|---|---|---|---|
| 1 | Phase 0.2: rawScore/maxMarks columns + v22 migration | Medium (schema change) | 2h |
| 2 | Phase 0.3: Unified answer matcher | Low | 30m |
| 3 | Phase 0.4: Atomic transaction in recordQuizAttempt | Low | 30m |
| 4 | Phase 0.1: Empty-pool guard + validatePool | Low | 45m |
| 5 | Phase 1.1: ExamConfig N-of-M + JSON | Medium | 2h |
| 6 | Phase 1.2: Grade N-of-M correctly | High (scoring logic) | 2h |
| 7 | Phase 1.3: Deadline timer | High (timer rewrite) | 2h |
| 8 | Phase 1.4: Checkpoint service + resume | High (new persistence) | 3h |
| 9 | Phase 1.5: _previous() section-lock fix | Low | 10m |
| 10 | Phase 1.6: Submit-race fix | Low | 20m |
| 11 | Phase 2.1: 5-state palette | Medium | 1.5h |
| 12 | Phase 2.2: NTA controls | Medium | 1h |
| 13 | Phase 2.3: Botany/Zoology split | Low | 30m |
| 14 | Phase 2.4: Percentile/AIR gating | Low | 30m |
| 15 | Phase 2.5: /cbt/result null-safety | Low | 10m |
| 16 | Phase 3: Cleanup | Low | 15m |

**Total estimated effort:** ~15-18 hours of focused coding.

---

## Test Plan

### Unit tests to update/add

**`test/exam_engine_service_test.dart`:**
- Update `neet()` assertions: `totalDurationSeconds == 180*60`, `sectionLock == false`, `breaksEnabled == false`
- Update `grade` tests to new `sectionQuestions` signature
- Add N-of-M test: present 5, grade 3 → first 3 answered count, extras discarded, no penalty
- Add `validatePool` tests: rejects missing options, empty text, correctAnswer not in options
- Add `isAnswerCorrect` trim test

**New `test/exam_checkpoint_test.dart`:**
- `ExamCheckpoint` JSON round-trip
- Deadline remaining-time helper
- Resume rebuilds exact question IDs from pool

**Manual end-to-end:**
1. Full mock → answer/flag/navigate across sections
2. Background 30s → foreground: timer continues from wall clock
3. Kill app → relaunch → Resume card → exact state restored
4. Timer hits 0 → auto-submit → result shows ±marks, Botany/Zoology split, percentile/AIR labeled
5. Short practice test → percentile/AIR hidden
6. Progress screen shows accurate NEET score from rawScore

---

## Verification Checklist

- [ ] `flutter analyze` — 0 errors
- [ ] `flutter test` — all passing (currently 126/132)
- [ ] Release APK builds and installs on device
- [ ] CBT timer survives background/kill with exact deadline
- [ ] Empty question pool shows "No questions" instead of crashing
- [ ] Percentile/AIR only on full mocks with disclaimer
- [ ] Botany and Zoology shown separately in results
- [ ] 5-state palette renders correctly
- [ ] Section-lock navigation enforced in both directions

---

## Open Questions

1. **ExamConfig default:** Should `ExamConfig.neet()` be fully replaced by `ExamConfig.neet2025_2026()`, or kept as deprecated alias? → Replace everywhere, delete alias after one release.
2. **Break behavior:** Should breaks be mandatory or skippable? Current plan: skippable with "Skip Break" button.
3. **Checkpoint storage:** SharedPreferences is sufficient for single active mock. If we later want multiple concurrent attempts, migrate to Drift table.
4. **N-of-M optional section:** Should the UI let students choose which 10 of 15 to attempt, or auto-select first 10 answered? → Auto-select first 10 answered (NTA convention).
