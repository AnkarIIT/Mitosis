import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './widgets/student_stats_card.dart';
import './widgets/quick_action_button.dart';
import './widgets/topic_progress_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/pyq_pdf_downloader_service.dart';

/// Modern, student-focused home screen with quick actions and progress tracking
class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen> {
  final PyqPdfDownloaderService _pyqService = PyqPdfDownloaderService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with Student Name
            SliverAppBar(
              title: const Text(
                'NEET Prep',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              backgroundColor: theme.colorScheme.surface,
                  elevation: 0,
                  floating: true,
                  snap: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Show notifications
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),

            // Student Stats Overview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: StudentStatsCard(
                  targetScore: 720,
                  currentScore: 680,
                  studyHours: 42,
                  daysStudied: 45,
                ),
              ),
            ),

            // Quick Action Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        QuickActionButton(
                          icon: Icons.book,
                          label: 'PYQ Downloads',
                          color: Colors.blue,
                          onTap: () => Navigator.pushNamed(context, '/pyq'),
                        ),
                        QuickActionButton(
                          icon: Icons.smart_toy,
                          label: 'AI Tutor',
                          color: Colors.purple,
                          onTap: () => Navigator.pushNamed(context, '/chatbot'),
                        ),
                        QuickActionButton(
                          icon: Icons.flash_on,
                          label: 'Flashcards',
                          color: Colors.orange,
                          onTap: () => Navigator.pushNamed(context, '/flashcards'),
                        ),
                        QuickActionButton(
                          icon: Icons.search,
                          label: 'Topic Bank',
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(context, '/topics'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Today's Study Plan
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Today's Plan",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Biology: Cell Biology (2h)',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chemistry: Chemical Bonding (1.5h)',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Physics: Modern Physics (1.5h)',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Study Session'),
                            onPressed: () {
                              // Start study session
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Topic Progress
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Topic Progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const TopicProgressBar(
                          topic: 'Biology',
                          progress: 0.75,
                          questions: 180,
                          mastered: 135,
                        ),
                        const SizedBox(height: 12),
                        const TopicProgressBar(
                          topic: 'Chemistry',
                          progress: 0.60,
                          questions: 150,
                          mastered: 90,
                        ),
                        const SizedBox(height: 12),
                        const TopicProgressBar(
                          topic: 'Physics',
                          progress: 0.55,
                          questions: 120,
                          mastered: 66,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // PYQ Downloads Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.menu_book, size: 20, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'NEET Previous Year Papers',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Download and practice from the last 19 years of NEET question papers (2006-2024).',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildYearBadge('2024', Colors.red),
                            ),
                            Expanded(
                              child: _buildYearBadge('2023', Colors.pink),
                            ),
                            Expanded(
                              child: _buildYearBadge('2022', Colors.deepPurple),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('Download All Papers'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Downloading 19 years of NEET PYQs...'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                              // Trigger download
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Available Space
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearBadge(String year, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          year,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}