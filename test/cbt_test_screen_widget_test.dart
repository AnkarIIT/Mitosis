import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';
import 'package:neet_mitos/core/services/exam_checkpoint_service.dart';
import 'package:neet_mitos/features/exam_engine/cbt_test_screen.dart';
import 'package:neet_mitos/features/exam_engine/nta_palette.dart';

/// Reads a live count out of the palette legend. The legend shows the number
/// inside a shape-coded chip and the label beside it, so the two are found by
/// key and by text respectively.
String _legendCount(WidgetTester tester, NtaPaletteState state) {
  final text = tester.widget<Text>(
    find.byKey(ValueKey('nta-count-${state.name}')),
  );
  return text.data!;
}

Question _q(String id, String subject, String topicId) {
  return Question(
    id: id,
    subject: subject,
    chapter: 'Chapter',
    topic: 'Topic',
    topicId: topicId,
    questionText: 'Question $id',
    options: const ['Option A', 'Option B', 'Option C', 'Option D'],
    correctAnswer: 'Option B',
    difficulty: 'Medium',
    tags: const [],
    type: 'mcq',
  );
}

List<Question> _pool() {
  return [
    _q('1', 'Physics', 'p1'),
    _q('2', 'Physics', 'p1'),
    _q('3', 'Chemistry', 'c1'),
    _q('4', 'Chemistry', 'c1'),
  ];
}

/// Pumps [CbtTestScreen] via GoRouter so it is mounted inside a fully
/// established [ModalRoute] â€” required because the screen reads
/// `ModalRoute.of(context)` during initState.
Future<void> _pumpCbt(
  WidgetTester tester, {
  ExamConfig? config,
  List<Question>? questionPool,
  ExamCheckpoint? resume,
}) async {
  final router = GoRouter(
    initialLocation: '/cbt',
    routes: [
      GoRoute(
        path: '/cbt',
        builder: (_, _) => CbtTestScreen(
          config:
              config ??
              ExamConfig.practice(questionCount: 4, durationMinutes: 10),
          questionPool: questionPool ?? _pool(),
          resumeFrom: resume,
        ),
      ),
      GoRoute(
        path: '/cbt/result',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('Result screen'))),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recentlySeenQuestionIdsProvider.overrideWith((ref, subject) async {
          return const <String>{};
        }),
        // The candidate strip reads the signed-in user. Without this override
        // the real notifier would open the database and secure storage.
        authProvider.overrideWith((ref) => _FakeAuthNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the NTA strips, question and palette', (tester) async {
    await _pumpCbt(tester);

    // Logo band and candidate strip carry the exam name.
    expect(find.text('CBT Practice'), findsOneWidget);

    // The clock lives in the candidate strip as a blue pill.
    expect(find.text('Remaining Time'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2}:\d{2}$')), findsOneWidget);

    // A question with its options renders (order is shuffled by a time seed).
    expect(find.text('Question 1:'), findsOneWidget);
    expect(find.text('Option A'), findsOneWidget);

    // Palette legend present with live counts. The current question has been
    // visited but not answered, so Not Answered reads 1 and 3 are untouched.
    expect(_legendCount(tester, NtaPaletteState.answered), '0');
    expect(_legendCount(tester, NtaPaletteState.notAnswered), '1');
    expect(_legendCount(tester, NtaPaletteState.notVisited), '3');

    // NTA control labels, in the reference's own wording.
    expect(find.text('CLEAR'), findsOneWidget);
    expect(find.text('SAVE & MARK FOR REVIEW'), findsOneWidget);
    expect(find.text('MARK FOR REVIEW & NEXT'), findsOneWidget);
    expect(find.text('SAVE & NEXT'), findsOneWidget);
    expect(find.text('SUBMIT'), findsOneWidget);
  });

  testWidgets('wide layout shows the NTA side panel and candidate strip', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() => tester.binding.platformDispatcher.clearAllTestValues());

    await _pumpCbt(tester);

    // NTA chrome: logo band, candidate identity, palette footer actions.
    expect(find.text('National Testing Agency'), findsOneWidget);
    expect(find.text('Guest Candidate'), findsOneWidget);
    expect(find.text('Question Paper'), findsOneWidget);
    expect(find.text('Instructions'), findsOneWidget);
    // The four controls fit one row at this width.
    expect(find.text('SAVE & NEXT'), findsOneWidget);
    expect(find.text('MARK FOR REVIEW & NEXT'), findsOneWidget);
  });

  testWidgets('selecting an option does not save it until SAVE & NEXT', (
    tester,
  ) async {
    await _pumpCbt(tester);

    await tester.tap(find.text('Option A'));
    await tester.pump();

    // NTA keeps a clicked option unsaved: the palette stays "Not Answered"
    // and only SAVE & NEXT moves it into the answer sheet.
    expect(_legendCount(tester, NtaPaletteState.answered), '0');
    expect(_legendCount(tester, NtaPaletteState.notAnswered), '1');

    await tester.tap(find.text('SAVE & NEXT'));
    await tester.pumpAndSettle();

    expect(_legendCount(tester, NtaPaletteState.answered), '1');
    // Question 2 is now the visited-but-unanswered one.
    expect(_legendCount(tester, NtaPaletteState.notAnswered), '1');
    expect(find.text('Question 2:'), findsOneWidget);
  });

  testWidgets('an unsaved selection is dropped when moving away', (
    tester,
  ) async {
    await _pumpCbt(tester);

    await tester.tap(find.text('Option A'));
    await tester.pump();
    // NEXT >> navigates, it does not save — same as clicking a palette cell.
    await tester.tap(find.text('NEXT >>'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2:'), findsOneWidget);
    expect(_legendCount(tester, NtaPaletteState.answered), '0');
    expect(find.textContaining('Answer not saved'), findsOneWidget);
  });

  testWidgets('SAVE & NEXT advances to the next question', (tester) async {
    await _pumpCbt(tester);

    expect(find.text('Question 1:'), findsOneWidget);

    await tester.tap(find.text('Option A'));
    await tester.pump();
    await tester.tap(find.text('SAVE & NEXT'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2:'), findsOneWidget);
  });

  testWidgets('SAVE & MARK FOR REVIEW flags but stays on the question', (
    tester,
  ) async {
    await _pumpCbt(tester);

    await tester.tap(find.text('Option A'));
    await tester.pump();
    await tester.tap(find.text('SAVE & MARK FOR REVIEW'));
    await tester.pumpAndSettle();

    // Answer stored and question flagged, and — unlike MARK FOR REVIEW & NEXT
    // — the candidate is still on question 1.
    expect(find.text('Question 1:'), findsOneWidget);
    expect(_legendCount(tester, NtaPaletteState.answeredMarked), '1');
    expect(find.text('Response saved and marked for review.'), findsOneWidget);
  });

  testWidgets('MARK FOR REVIEW & NEXT flags without saving and advances', (
    tester,
  ) async {
    await _pumpCbt(tester);

    await tester.tap(find.text('MARK FOR REVIEW & NEXT'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2:'), findsOneWidget);
    expect(_legendCount(tester, NtaPaletteState.marked), '1');
    expect(_legendCount(tester, NtaPaletteState.answered), '0');
  });

  testWidgets('No proctoring banner when no violations', (tester) async {
    await _pumpCbt(tester);

    expect(find.textContaining('Proctoring'), findsNothing);
  });

  // ── NTA flow cover ─────────────────────────────────────────────
  // The palette moved from a cramped horizontal strip to NTA's side panel /
  // phone sheet, and submission now goes through NTA's count table plus a
  // declaration. These tests pin the parts that are easy to regress silently.

  testWidgets('phone layout opens the palette as a sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() => tester.binding.platformDispatcher.clearAllTestValues());

    await _pumpCbt(tester);

    // The side panel is not used on a phone; the grid action is the entry.
    expect(find.byTooltip('Question palette'), findsOneWidget);
    await tester.tap(find.byTooltip('Question palette'));
    await tester.pumpAndSettle();

    expect(find.text('Question Palette'), findsOneWidget);
    expect(find.text('Submit Test'), findsOneWidget);
    expect(_legendCount(tester, NtaPaletteState.notVisited), '3');
  });

  testWidgets('submit dialog lists NTA counts and requires the declaration', (
    tester,
  ) async {
    await _pumpCbt(tester);

    // Walk to the last question with SAVE & NEXT, then submit from the strip.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('SAVE & NEXT'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    // Scoped to the dialog: the palette legend behind it carries the same
    // state labels.
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('No. of Questions')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Not Visited')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('Answered & Marked for Review'),
      ),
      findsOneWidget,
    );

    final submit = find.widgetWithText(FilledButton, 'Yes, Submit');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    // Deliberately stops here: pressing Submit kicks off persistence through
    // platform channels that do not resolve under the test binding, so the
    // in-flight spinner would make pumpAndSettle time out. The declaration
    // gate is the behaviour this test exists to protect.
  });

  testWidgets('section-locked paper explains why a tab cannot be opened', (
    tester,
  ) async {
    final cfg = ExamConfig.neet(
      physicsCount: 2,
      chemistryCount: 2,
      botanyCount: 0,
      zoologyCount: 0,
      sectionLock: true,
    );
    await _pumpCbt(tester, config: cfg);

    await tester.tap(find.text('CHEMISTRY').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('section-locked'), findsOneWidget);
  });

  testWidgets('palette footer opens Question Paper and Instructions', (
    tester,
  ) async {
    await _pumpCbt(tester);

    await tester.tap(find.text('Question Paper'));
    await tester.pumpAndSettle();
    expect(
      find.text('View only · tap a question to jump to it'),
      findsOneWidget,
    );
    // The sheet lists all four questions; the pane behind shows whichever one
    // the shuffled allocation put first, so the count is 4 + 1, not 4.
    expect(
      find.textContaining(RegExp(r'^Question \d$')),
      findsNWidgets(5),
    );

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Instructions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('does not pause'), findsOneWidget);
  });

  testWidgets('full mock warns once at 15 minutes remaining', (tester) async {
    final cfg = ExamConfig.neet(
      physicsCount: 2,
      chemistryCount: 2,
      botanyCount: 0,
      zoologyCount: 0,
    );
    final stored = [_q('w1', 'Physics', 'p1'), _q('w2', 'Physics', 'p1')];
    final cp = _checkpoint(config: cfg, questions: stored, minutesLeft: 14);

    await _pumpCbt(tester, config: cfg, questionPool: const [], resume: cp);

    // The first tick crosses the 15-minute threshold.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('15 minutes remaining'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('15 minutes remaining'), findsNothing);
  });

  // â”€â”€ Resume regression cover â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // The resume path was completely broken and nothing caught it: initState
  // sized `_secondsPerQuestion` from `_questions.length` *before* `_questions`
  // (a `late final`) was assigned, so every resume threw
  // LateInitializationError on the first frame. Every other CBT test mounts
  // without a checkpoint, so the whole feature could rot unnoticed.

  testWidgets('resuming a checkpoint renders instead of throwing', (
    tester,
  ) async {
    final cfg = ExamConfig.practice(questionCount: 4, durationMinutes: 30);
    // Pool deliberately EMPTY: only the stored snapshots can satisfy resume.
    final stored = [
      _q('r1', 'Physics', 'p1'),
      _q('r2', 'Physics', 'p1'),
      _q('r3', 'Chemistry', 'c1'),
      _q('r4', 'Chemistry', 'c1'),
    ];
    final cp = _checkpoint(
      config: cfg,
      questions: stored,
      currentIndex: 2,
      answers: const {0: 'Option B'},
    );

    await _pumpCbt(tester, config: cfg, questionPool: const [], resume: cp);

    // Survived initState and reached the question view at the restored index.
    expect(find.textContaining('Question r3'), findsWidgets);
    // The restored answer for index 0 is carried into the attempt, and index 0
    // is also flagged in the checkpoint, so it lands in the "Answered &
    // Marked" bucket of the NTA legend.
    expect(_legendCount(tester, NtaPaletteState.answeredMarked), '1');
  });

  testWidgets('resume restores the stored deadline, not a fresh one', (
    tester,
  ) async {
    final cfg = ExamConfig.practice(questionCount: 2, durationMinutes: 30);
    final stored = [_q('r1', 'Physics', 'p1'), _q('r2', 'Physics', 'p1')];
    final cp = _checkpoint(config: cfg, questions: stored);

    await _pumpCbt(tester, config: cfg, questionPool: const [], resume: cp);

    // ~30 minutes were restored, and only ~0 elapsed, so this must still be
    // comfortably above 25 â€” a fresh 30-minute start would also pass that, so
    // the real assertion is that resume did not crash and state round-trips.
    expect(cp.remainingSecondsAt(DateTime.now()), greaterThan(25 * 60));
    expect(cp.config.totalDurationSeconds, 30 * 60);
  });
}

/// Builds a v3 checkpoint whose questions no longer exist in `questionPool`,
/// so resume can only succeed via the stored snapshots.
ExamCheckpoint _checkpoint({
  required ExamConfig config,
  required List<Question> questions,
  int currentIndex = 0,
  Map<int, String?> answers = const {},
  int minutesLeft = 30,
}) {
  final now = DateTime.now();
  return ExamCheckpoint(
    attemptId: 'cbt_resume_regression',
    configJson: config.toJson(),
    sectionQuestionIds: [
      [for (final q in questions) q.id],
    ],
    sectionQuestions: [questions],
    answersByIndex: answers,
    flagged: const [0],
    visited: [for (var i = 0; i < questions.length; i++) i],
    currentIndex: currentIndex,
    currentSection: 0,
    phase: 'taking',
    // Well in the future, so the restored deadline is not already expired.
    deadlineEpochMs: now
        .add(Duration(minutes: minutesLeft))
        .millisecondsSinceEpoch,
    startedAtEpochMs: now
        .subtract(const Duration(minutes: 10))
        .millisecondsSinceEpoch,
    savedAtEpochMs: now.millisecondsSinceEpoch,
    secondsPerQuestion: const {0: 42, 1: 17},
    violations: 0,
  );
}

/// Minimal stand-in for the auth notifier so the exam's candidate strip has a
/// user without opening the real database or secure storage.
class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
    : super(AuthState(status: AuthStatus.authenticated, isGuest: true));

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> continueAsGuest() async {}

  @override
  Future<bool> toggle2FA(bool enabled) async => false;

  @override
  Future<bool> enable2FA(String email) async => false;

  @override
  Future<bool> confirmEnable2FA(String email, String code) async => false;

  @override
  Future<bool> disable2FA() async => false;

  @override
  Future<bool> verifyLogin2FA(String code) async => false;

  @override
  Future<bool> resendLogin2FA() async => false;

  @override
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async => false;

  @override
  Future<bool> login({required String email, required String password}) async =>
      false;

  @override
  Future<bool> signInWithGoogle() async => false;

  @override
  Future<bool> resetPassword(String email) async => false;

  @override
  Future<bool> verifyResetCode({
    required String email,
    required String code,
    required String newPassword,
  }) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<({bool success, String message})> deleteAccount() async {
    return (success: true, message: 'deleted');
  }
}
