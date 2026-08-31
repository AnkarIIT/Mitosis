import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../../features/auth/auth_screen.dart';

import '../../features/auth/terms_screen.dart';
import '../../features/auth/privacy_policy_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_shell_screen.dart';
import '../../features/home/home_content/home_tab.dart';
// import '../../features/home/home_content/subjects_tab.dart'; // Replaced with Flashcards
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
import '../../core/services/exam_engine_service.dart';
import '../../core/services/dpp_engine.dart';
import '../../core/services/exam_checkpoint_service.dart';
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
import '../../features/bookmarks/bookmarks_dashboard.dart';
import '../../features/study_modules/allen_study_module_screen.dart';
import '../../features/dpp/dpp_screen.dart';
import '../../features/dpp/dpp_attempt_screen.dart';
import '../../features/dpp/dpp_neet_screen.dart';

const _publicRoutes = {'/auth', '/terms', '/privacy', '/loading'};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.loading;

      if (_publicRoutes.contains(path)) {
        if (path == '/auth' && isAuthenticated) return '/';
        return null;
      }

      if (path == '/onboarding') {
        if (!isAuthenticated) return '/auth';
        return null;
      }

      if (isLoading) return '/loading';

      if (isAuthenticated) {
        final onboardingComplete = ref.read(onboardingCompleteProvider);
        if (!onboardingComplete) return '/onboarding';
        return null;
      }

      return '/auth';
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
                    color: const Color(0xFF216869),
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
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeTab())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/flashcards',
                builder: (_, _) => const FlashcardDashboardScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (_, _) => const ProfileTab()),
            ],
          ),
        ],
      ),

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
          final topicId = state.uri.queryParameters['topicId'] ?? '';
          final topicName = state.uri.queryParameters['topicName'] ?? '';
          final subject = state.uri.queryParameters['subject'] ?? '';
          final testType = state.uri.queryParameters['testType'];
          return EnhancedQuizScreen(
            topicId: topicId,
            topicName: topicName,
            subject: subject,
            testType: testType,
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
      GoRoute(
        path: '/pdf',
        builder: (_, state) {
          final entryId = state.uri.queryParameters['entryId'] ?? '';
          return NcertPdfScreen(entryId: entryId);
        },
      ),
      GoRoute(
        path: '/cbt',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final config = extra['config'] as ExamConfig? ?? ExamConfig.neet();
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
          final config = extra['config'] as ExamConfig? ?? ExamConfig.neet();
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
    ],
  );
});
