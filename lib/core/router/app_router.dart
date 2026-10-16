import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../../features/auth/auth_screen.dart';

import '../../features/auth/terms_screen.dart';
import '../../features/auth/privacy_policy_screen.dart';
import '../../features/auth/help_support_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_shell_screen.dart';
import '../../features/home/home_content/home_tab.dart';
import '../../features/home/home_content/learn_hub_screen.dart';
import '../../features/home/home_content/practice_hub_screen.dart';
import '../../features/home/home_content/review_tab.dart';
import '../../features/home/home_content/progress_tab.dart';
import '../../features/home/home_content/profile_tab.dart';
import '../../features/topic_browser/topic_browser_screen.dart';
import '../../features/topic_browser/topic_detail_screen.dart';
import '../../features/quiz/enhanced_quiz_screen.dart';
import '../../features/test_series/test_series_screen.dart';
import '../../features/test_series/test_result_screen.dart';
import '../../features/test_series/question_paper_selector.dart';
import '../../features/test_series/pdf_picker_screen.dart';
import '../../features/exam_engine/cbt_test_screen.dart';
import '../../features/exam_engine/cbt_result_screen.dart';
import '../../features/exam_engine/cbt_instructions_screen.dart';
import '../../core/services/exam_engine_service.dart';
import '../../core/services/dpp_engine.dart';
import '../../core/services/exam_checkpoint_service.dart';
import '../../core/services/onboarding_completion_service.dart';
import '../../core/services/test_analytics_service.dart';
import '../../core/models/question_model.dart';
import '../../core/models/user_progress_model.dart';
import '../../features/study_plan/study_plan_screen.dart';
import '../../features/error_book/error_book_screen.dart';
import '../../features/mark_booster/mark_booster_screen.dart';
import '../../features/flashcards/flashcard_study_screen.dart';
import '../../features/flashcards/flashcard_generate_screen.dart';
import '../../features/flashcards/flashcard_dashboard_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/import_questions_screen.dart';
import '../../features/pdf/ncert_pdf_screen.dart';
import '../../features/resources/resources_screen.dart';
import '../../features/resources/chapter_notes_screen.dart';
import '../../features/bookmarks/bookmarks_dashboard.dart';
import '../../features/study_modules/allen_study_module_screen.dart';
import '../../features/dpp/dpp_screen.dart';
import '../../features/dpp/dpp_attempt_screen.dart';
import '../../features/dpp/dpp_neet_screen.dart';
import '../../features/pyq/pyq_download_screen.dart';
import '../../features/test/test_module_screen.dart';
import '../../features/chapter/chapter_landing_screen.dart';
import '../../features/chapter/lesson_screen.dart';
import '../../features/chapter/chapter_quiz_screen.dart';

const _publicRoutes = {'/auth', '/terms', '/privacy', '/help'};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final path = state.matchedLocation;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.loading;

      if (_publicRoutes.contains(path)) {
        if (path == '/auth' && isAuthenticated) return '/';
        return null;
      }

      if (isLoading) return path == '/loading' ? null : '/loading';
      if (!isAuthenticated) return '/auth';

      final user = authState.user;
      final hasSavedStudySetup =
          user != null &&
          user.batch != null &&
          user.targetYear != null &&
          user.dailyCommitmentMinutes != null;
      final onboardingComplete =
          hasSavedStudySetup ||
          await OnboardingCompletionService.isComplete(
            userId: user?.id,
            isGuest: authState.isGuest,
          );

      if (path == '/loading') {
        return onboardingComplete ? '/' : '/onboarding';
      }
      if (path == '/onboarding') return onboardingComplete ? '/' : null;
      if (!onboardingComplete) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'NEET Mitos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      ),

      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/terms', builder: (_, _) => const TermsScreen()),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyPolicyScreen()),
      // Public, like /terms and /privacy: a signed-out user may need to read
      // how to get help before they can sign in.
      GoRoute(path: '/help', builder: (_, _) => const HelpSupportScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShellScreen(navigationShell: shell),
        branches: [
          // Today · Learn · Practice · Review · Progress. Profile lives
          // outside the tabs (avatar/settings entry point).
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeTab())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (_, _) => const LearnHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/practice',
                builder: (_, _) => const PracticeHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/review', builder: (_, _) => const ReviewTab()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (_, _) => const ProgressTab(),
              ),
            ],
          ),
        ],
      ),
      // Reachable from Learn hub / deep links (not a bottom tab).
      GoRoute(
        path: '/flashcards',
        builder: (_, _) => const FlashcardDashboardScreen(),
      ),
      // Profile is reachable via the Today header avatar and settings.
      GoRoute(path: '/profile', builder: (_, _) => const ProfileTab()),

      GoRoute(
        path: '/subjects/:subjectId',
        builder: (_, state) {
          final subjectId = state.pathParameters['subjectId']!;
          final subjectName =
              state.uri.queryParameters['subjectName'] ?? subjectId;
          return TopicBrowserScreen(
            subjectId: subjectId,
            subjectName: subjectName,
          );
        },
      ),
      GoRoute(
        path: '/topic/:topicId',
        builder: (_, state) {
          final topicId = state.pathParameters['topicId']!;
          final subjectName = state.uri.queryParameters['subjectName'] ?? '';
          final chapterName = state.uri.queryParameters['chapterName'] ?? '';
          return TopicDetailScreen(
            topicId: topicId,
            subjectName: subjectName,
            chapterName: chapterName,
          );
        },
      ),
      GoRoute(
        path: '/quiz',
        builder: (_, state) {
          // The Error Book retest passes its questions via extra; topic
          // flows keep using query parameters. Previously extra was
          // silently dropped, so retests opened an empty quiz.
          final extra = state.extra as Map<String, dynamic>?;
          final rawQuestions = extra?['questions'];
          final extraQuestions = rawQuestions is List
              ? rawQuestions.whereType<Question>().toList()
              : null;
          final topicId =
              (extra?['topicId'] as String?) ??
              state.uri.queryParameters['topicId'] ??
              '';
          final topicName =
              (extra?['topicName'] as String?) ??
              state.uri.queryParameters['topicName'] ??
              '';
          final subject =
              (extra?['subject'] as String?) ??
              state.uri.queryParameters['subject'] ??
              '';
          final testType =
              (extra?['testType'] as String?) ??
              state.uri.queryParameters['testType'];
          return EnhancedQuizScreen(
            questions: extraQuestions,
            topicId: topicId,
            topicName: topicName,
            subject: subject,
            testType: testType,
            marksPerCorrect: 4,
            marksPerWrong: -1,
          );
        },
      ),
      GoRoute(
        path: '/quiz/result',
        redirect: (context, state) {
          if (state.extra == null) return '/';
          return null;
        },
        builder: (_, state) {
          final attempt = state.extra as dynamic;
          return TestResultScreen(attempt: attempt);
        },
      ),
      GoRoute(
        path: '/test-series',
        builder: (_, _) => const TestSeriesScreen(),
      ),
      GoRoute(
        path: '/test-series/paper',
        builder: (_, _) => const QuestionPaperSelector(),
      ),
      GoRoute(path: '/pdf-picker', builder: (_, _) => const PdfPickerScreen()),
      GoRoute(path: '/resources', builder: (_, _) => const ResourcesScreen()),
      GoRoute(
        path: '/resources/notes',
        builder: (_, state) => ChapterNotesScreen(
          chapterId: state.uri.queryParameters['chapterId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/pdf',
        builder: (_, state) {
          final entryId = state.uri.queryParameters['entryId'] ?? '';
          return NcertPdfScreen(entryId: entryId);
        },
      ),
      GoRoute(
        path: '/cbt/instructions',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final config =
              extra['config'] as ExamConfig? ?? ExamConfig.neet2024();
          final questionPool = extra['questionPool'] as List<Question>? ?? [];
          return CbtInstructionsScreen(
            config: config,
            questionPool: questionPool,
          );
        },
      ),
      GoRoute(
        path: '/cbt',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final config =
              extra['config'] as ExamConfig? ?? ExamConfig.neet2024();
          final questionPool = extra['questionPool'] as List<Question>? ?? [];
          final resumeFrom = extra['resumeCheckpoint'] as ExamCheckpoint?;
          return CbtTestScreen(
            config: config,
            questionPool: questionPool,
            resumeFrom: resumeFrom,
          );
        },
      ),
      GoRoute(
        path: '/cbt/result',
        // Guard against a hot-restart / deep-link with no result payload: the
        // screen's fields are non-nullable, so redirect home instead of crashing.
        redirect: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          if (args == null ||
              args['attempt'] == null ||
              args['analytics'] == null) {
            return '/';
          }
          return null;
        },
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return CbtResultScreen(
            attempt: args['attempt'] as QuizAttempt,
            analytics: args['analytics'] as TestAnalytics,
            questions: args['questions'] as List<Question>?,
            answersByIndex: args['answersByIndex'] as Map<int, String?>?,
          );
        },
      ),
      GoRoute(
        path: '/cbt/replay',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final config =
              extra['config'] as ExamConfig? ?? ExamConfig.neet2024();
          final questionPool = extra['questionPool'] as List<Question>? ?? [];
          return CbtTestScreen(config: config, questionPool: questionPool);
        },
      ),
      GoRoute(
        path: '/flashcards/generate',
        builder: (_, _) => const FlashcardGenerateScreen(),
      ),
      GoRoute(
        path: '/flashcards/study',
        builder: (_, _) => const FlashcardStudyScreen(),
      ),
      GoRoute(path: '/error-book', builder: (_, _) => const ErrorBookScreen()),
      GoRoute(
        path: '/bookmarks',
        builder: (_, _) => const BookmarksDashboard(),
      ),
      GoRoute(
        path: '/mark-booster',
        builder: (_, _) => const MarkBoosterScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (_, state) {
          final initialMessage = state.uri.queryParameters['initialMessage'];
          return ChatbotScreen(initialMessage: initialMessage);
        },
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/settings/import',
        builder: (_, _) => const ImportQuestionsScreen(),
      ),
      GoRoute(path: '/study-plan', builder: (_, _) => const StudyPlanScreen()),
      GoRoute(
        path: '/study-modules',
        builder: (_, state) {
          final subjectId = state.uri.queryParameters['subjectId'];
          return AllenStudyModuleScreen(initialSubjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/study-modules/chapter',
        builder: (_, state) {
          final subjectId = state.uri.queryParameters['subjectId'] ?? '';
          final chapterName = state.uri.queryParameters['chapterName'] ?? '';
          final topicId = state.uri.queryParameters['topicId'] ?? '';
          return AllenChapterDetailScreen(
            subjectId: subjectId,
            chapterName: chapterName,
            topicId: topicId,
          );
        },
      ),
      GoRoute(
        path: '/study-modules/chapter',
        builder: (_, state) {
          final subjectId = state.uri.queryParameters['subjectId'] ?? '';
          final chapterName = state.uri.queryParameters['chapterName'] ?? '';
          final topicId = state.uri.queryParameters['topicId'] ?? '';
          return AllenChapterDetailScreen(
            subjectId: subjectId,
            chapterName: chapterName,
            topicId: topicId,
          );
        },
      ),
      // Chapter module routes
      GoRoute(
        path: '/chapter/:chapterId',
        builder: (_, state) {
          final chapterId = state.pathParameters['chapterId']!;
          return ChapterLandingScreen(chapterId: chapterId);
        },
      ),
      GoRoute(
        path: '/chapter/:chapterId/lesson/:lessonId',
        builder: (_, state) {
          final chapterId = state.pathParameters['chapterId']!;
          final lessonId = state.pathParameters['lessonId']!;
          return LessonScreen(chapterId: chapterId, lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/chapter/:chapterId/quiz',
        builder: (_, state) {
          final chapterId = state.pathParameters['chapterId']!;
          return ChapterQuizScreen(chapterId: chapterId);
        },
      ),
      GoRoute(
        path: '/dpp/neet',
        builder: (_, _) {
          return const DppNeetScreen();
        },
      ),
      GoRoute(
        path: '/dpp/attempt',
        redirect: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null || extra['dppResult'] == null) return '/';
          return null;
        },
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          final dppResult = extra['dppResult'] as DppResult;
          final durationMinutes = extra['durationMinutes'] as int? ?? 20;
          return DppAttemptScreen(
            dppResult: dppResult,
            durationMinutes: durationMinutes,
          );
        },
      ),
      GoRoute(
        path: '/dpp/:subject',
        builder: (_, state) {
          final subject = state.pathParameters['subject'] ?? 'physics';
          return DppScreen(subject: subject);
        },
      ),
      GoRoute(path: '/pyq', builder: (_, _) => const PyqDownloadScreen()),
      GoRoute(path: '/test', builder: (_, _) => const TestModuleScreen()),
    ],
  );
});
