import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/services/onboarding_completion_service.dart';

import 'batch_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isSaving = false;
  String? _saveError;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Study with a clear plan',
      description:
          'Keep Biology, Chemistry, and Physics moving with a daily goal that fits your routine.',
      icon: Icons.track_changes_rounded,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Practice at your pace',
      description:
          'Build confidence with quizzes, daily practice papers, and previous year questions—even offline.',
      icon: Icons.edit_note_rounded,
      color: AppColors.brandTeal,
    ),
    OnboardingPage(
      title: 'Build steady progress',
      description:
          'Practice, review missed questions, and see where your study time is going.',
      icon: Icons.show_chart_rounded,
      color: AppColors.brandTeal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length + 2, // +1 batch triage, +1 final setup
            itemBuilder: (context, index) {
              if (index < _pages.length) {
                return _buildIntroPage(_pages[index]);
              } else if (index == _pages.length) {
                return BatchOnboardingPage(
                  onDone: () {
                    _pageController.animateToPage(
                      _pages.length + 1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                );
              } else {
                return _buildSetupPage();
              }
            },
          ),
          Positioned(
            bottom: 28,
            left: 20,
            right: 20,
            // The batch triage page renders its own back/skip/next controls.
            child: _currentPage == _pages.length
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AdaptiveColors.surface(context),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: AdaptiveColors.outlineVariant(context),
                      ),
                      boxShadow: AppShadows.raised(
                        AdaptiveColors.isDark(context),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage < _pages.length)
                          TextButton(
                            onPressed: () {
                              _pageController.animateToPage(
                                _pages.length,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(
                              'SKIP',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 60),

                        Row(
                          children: List.generate(
                            _pages.length + 2,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? AppColors.primary
                                    : AdaptiveColors.outline(context),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        if (_currentPage < _pages.length)
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          )
                        else
                          const SizedBox(width: 60),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 118),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(64),
              border: Border.all(color: page.color.withValues(alpha: 0.14)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: page.color.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    color: AdaptiveColors.surface(context),
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.raised(
                      AdaptiveColors.isDark(context),
                    ),
                  ),
                  child: Icon(page.icon, size: 52, color: page.color),
                ),
                Positioned(
                  top: 30,
                  right: 35,
                  child: _onboardingDot(page.color, 11),
                ),
                Positioned(
                  bottom: 33,
                  left: 28,
                  child: _onboardingDot(page.color.withValues(alpha: 0.55), 8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            page.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _onboardingDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.settings_suggest,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Optional AI Tutor',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Your study plan is ready. Adding a Gemini API key is optional; you can skip this and add it later in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _apiKeyController,
            enabled: !_isSaving,
            decoration: InputDecoration(
              labelText: 'Gemini API key (optional)',
              hintText: 'Paste your API key',
              prefixIcon: const Icon(Icons.key_rounded),
              filled: true,
              fillColor: AdaptiveColors.surfaceWarm(context),
            ),
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _saveError!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _completeOnboarding,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('START STUDYING'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isSaving ? null : _completeOnboarding,
            child: Text(
              _isSaving ? 'Saving…' : 'Skip for now',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      // The optional AI key must never block first study start: save it
      // best-effort and continue even if it fails.
      final key = _apiKeyController.text.trim();
      if (key.isNotEmpty) {
        try {
          await ref.read(geminiServiceProvider).saveApiKey(key);
        } catch (e) {
          debugPrint('Optional API key save failed (non-blocking): $e');
        }
      }

      final authState = ref.read(authProvider);
      await OnboardingCompletionService.markComplete(
        userId: authState.user?.id,
        isGuest: authState.isGuest,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      ref.read(onboardingCompleteProvider.notifier).state = true;

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError =
            'Could not save your setup (${e.toString().split('\n').first}). Check your connection and tap START STUDYING to retry — your study plan is safe.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
