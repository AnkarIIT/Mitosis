import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/subject_model.dart';
import '../topic_browser/topic_browser_screen.dart';
import '../progress/progress_dashboard.dart';
import '../bookmarks/bookmarks_dashboard.dart';
import '../chatbot/chatbot_screen.dart';
import '../test_series/test_series_screen.dart';
import '../study_plan/study_plan_screen.dart';
import '../settings/settings_screen.dart';
import '../flashcards/flashcard_screen.dart';
import '../profile/profile_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final stats = ref.watch(overallStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEET Mitos'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${(stats['accuracy'] as double).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildSubjectScreen(context, subjects)
          : _selectedIndex == 1
          ? const FlashcardScreen()
          : _selectedIndex == 2
          ? const ChatbotScreen()
          : _selectedIndex == 3
          ? const ProgressDashboard()
          : _selectedIndex == 4
          ? const BookmarksDashboard()
          : const ProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
            label: 'Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'AI Tutor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectScreen(BuildContext context, List<Subject> subjects) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900
        ? 3
        : (screenWidth > 600 ? 2 : 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.9),
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to NEET Mitos',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Master NEET topics with focused learning & practice',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fade(duration: 600.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 24),

          // Quick access row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAccessChip(
                  context,
                  icon: Icons.assignment_turned_in,
                  label: 'Test Series',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TestSeriesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildQuickAccessChip(
                  context,
                  icon: Icons.warning_rounded,
                  label: 'Weak Topics',
                  color: AppColors.warning,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1; // Go to Progress tab
                    });
                  },
                ),
                const SizedBox(width: 12),
                _buildQuickAccessChip(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Study Plan',
                  color: AppColors.chemistryAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyPlanScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ).animate().fade(delay: 150.ms).slideX(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Practice tests section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice Tests',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Full mock tests, subject drills, and daily practice sets — all in one place.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.secondary,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.quiz_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TestSeriesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_turned_in, size: 18),
                    label: const Text('Open Test Series'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 180.ms).slideY(begin: 0.06, end: 0),

          const SizedBox(height: 32),

          // Subject cards
          Text(
            'Select Subject',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ).animate().fade(delay: 200.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: screenWidth > 900
                  ? 1.6
                  : (screenWidth > 600 ? 1.5 : 2.0),
            ),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final subjectStats = ref.watch(
                subjectStatsProvider(subject.name),
              );
              final accuracy = subjectStats['accuracy'] as double;
              return _buildSubjectCard(context, subject, accuracy)
                  .animate(delay: (300 + (100 * index)).ms)
                  .fade(duration: 500.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    Subject subject,
    double accuracy,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicBrowserScreen(
              subjectId: subject.id,
              subjectName: subject.name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getSubjectColor(subject.id).withValues(alpha: 0.95),
              _getSubjectColor(subject.id).withValues(alpha: 0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getSubjectColor(subject.id).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicBrowserScreen(
                    subjectId: subject.id,
                    subjectName: subject.name,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subject.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${accuracy.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${subject.chapters.length} chapters',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: accuracy / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subjectId) {
    switch (subjectId.toLowerCase()) {
      case 'biology':
        return AppColors.biologyAccent;
      case 'chemistry':
        return AppColors.chemistryAccent;
      case 'physics':
        return AppColors.physicsAccent;
      default:
        return AppColors.primary;
    }
  }
}
