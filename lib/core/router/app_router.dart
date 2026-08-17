import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/two_factor_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/neet_home_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/home_shell_screen.dart';
import '../../features/topic_browser/topic_browser_screen.dart';
import '../../features/topic_browser/topic_detail_screen.dart';
import '../../features/quiz/enhanced_quiz_screen.dart';
import '../../features/test_series/test_series_screen.dart';
import '../../features/test_series/test_result_screen.dart';
import '../../features/test_series/question_paper_selector.dart';
import '../../features/test_series/pdf_picker_screen.dart';
import '../../features/exam_engine/cbt_test_screen.dart';
import '../../features/exam_engine/cbt_result_screen.dart';
import '../../features/study_plan/study_plan_screen.dart';
import '../../features/review/spaced_review_screen.dart';
import '../../features/progress/progress_dashboard.dart';
import '../../features/error_book/error_book_screen.dart';
import '../../features/mark_booster/mark_booster_screen.dart';
import '../../features/flashcards/flashcard_screen.dart';
import '../../features/flashcards/flashcard_generate_screen.dart';
import '../../features/flashcards/flashcard_study_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/import_questions_screen.dart';
import '../../features/pdf/ncert_pdf_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/bookmarks/bookmarks_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final path = state.matchedLocation;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.loading;

      if (path == '/auth') {
        if (isAuthenticated) return '/';
        return null;
      }

      if (path == '/otp') {
        if (isAuthenticated) return '/';
        if (authState.status != AuthStatus.awaitingOtp) return '/auth';
        return null;
      }

      if (path == '/2fa') {
        if (isAuthenticated) return '/';
        if (authState.status != AuthStatus.awaiting2FA) return '/auth';
        return null;
      }

      if (path == '/onboarding') {
        if (!isAuthenticated) return '/auth';
        return null;
      }

      if (isLoading) return '/loading';

      if (authState.status == AuthStatus.awaiting2FA) return '/2fa';
      if (authState.status == AuthStatus.awaitingOtp) return '/otp';

      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        final onboardingComplete =
            prefs.getBool('onboarding_complete') ?? false;
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
      GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
      GoRoute(path: '/2fa', builder: (_, _) => const TwoFactorScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Consumer(
                builder: (ctx, ref, _) {
                  final premium = ref.watch(usePremiumHomeProvider);
                  return premium
                      ? const NeetHomeScreen()
                      : const HomeScreen();
                },
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/flashcards',
                builder: (_, _) => const FlashcardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/review',
                builder: (_, _) => const SpacedReviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/progress',
                builder: (_, _) => const ProgressDashboard()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),

      GoRoute(
        path: '/subjects',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return TopicBrowserScreen(
            subjectId: args['subjectId'] as String,
            subjectName: args['subjectName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/topic',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return TopicDetailScreen(
            topic: args['topic'],
            subjectName: args['subjectName'] as String,
            chapterName: args['chapterName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/quiz',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return EnhancedQuizScreen(
            questions: args['questions'],
            topicName: args['topicName'] as String,
            topicId: args['topicId'] as String,
            subject: args['subject'] as String,
            testType: args['testType'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/quiz/result',
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
      GoRoute(
        path: '/pdf-picker',
        builder: (_, _) => const PdfPickerScreen(),
      ),
      GoRoute(
        path: '/pdf',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return NcertPdfScreen(
            entry: args['entry'],
            chapter: args['chapter'],
          );
        },
      ),
      GoRoute(
        path: '/cbt',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return CbtTestScreen(
            config: args['config'],
            questionPool: args['questionPool'],
          );
        },
      ),
      GoRoute(
        path: '/cbt/result',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return CbtResultScreen(
            attempt: args['attempt'],
            analytics: args['analytics'],
          );
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
      GoRoute(
        path: '/error-book',
        builder: (_, _) => const ErrorBookScreen(),
      ),
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
        builder: (_, _) => const ChatbotScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/import',
        builder: (_, _) => const ImportQuestionsScreen(),
      ),
      GoRoute(
        path: '/study-plan',
        builder: (_, _) => const StudyPlanScreen(),
      ),
    ],
  );
});
