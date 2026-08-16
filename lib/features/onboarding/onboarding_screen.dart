import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import 'batch_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _apiKeyController = TextEditingController();

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Master NEET Concepts',
      description: 'Comprehensive coverage of Biology, Chemistry, and Physics based strictly on NCERT.',
      icon: Icons.auto_stories,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'AI-Powered Doubt Solving',
      description: 'Stuck on a question? Take a photo or type it in, and our AI Tutor will guide you to the answer.',
      icon: Icons.psychology,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Track Your Progress',
      description: 'Identify your weak spots with smart analytics and focus on what matters most.',
      icon: Icons.analytics,
      color: Colors.blue,
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
            bottom: 40,
            left: 20,
            right: 20,
            // The batch triage page renders its own back/skip/next controls.
            child: _currentPage == _pages.length
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage < _pages.length)
                        TextButton(
                          onPressed: () {
                            _pageController.animateToPage(
                              _pages.length + 1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('SKIP', style: TextStyle(color: AppColors.secondary)),
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
                              color: _currentPage == index ? AppColors.primary : AppColors.divider,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      if (_currentPage < _pages.length)
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
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
        ],
      ),
    );
  }

  Widget _buildIntroPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 100, color: page.color),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: const TextStyle(fontSize: 16, color: AppColors.secondary),
            textAlign: TextAlign.center,
          ),
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
          const Icon(Icons.settings_suggest, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Final Setup',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'To enable the AI Tutor, enter your free Gemini API Key (you can also do this later in settings).',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              hintText: 'Enter Gemini API Key',
              prefixIcon: const Icon(Icons.vpn_key),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Open link to get API key
            },
            child: const Text(
              'How to get a free key?',
              style: TextStyle(color: AppColors.primary, fontSize: 12, decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              child: const Text('GET STARTED'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      await ref.read(geminiServiceProvider).saveApiKey(key);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
