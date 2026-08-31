import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/flashcard_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';

class FlashcardDashboardScreen extends ConsumerWidget {
  const FlashcardDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueFlashcardsAsync = ref.watch(dueFlashcardsProvider);
    final allFlashcards = ref.watch(flashcardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/flashcards/settings'),
            tooltip: 'Flashcard Settings',
          ),
        ],
      ),
      body: dueFlashcardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading flashcards: $e')),
        data: (dueCards) => _buildContent(context, dueCards, allFlashcards),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/flashcards/generate'),
        icon: const Icon(Icons.add),
        label: const Text('Create Cards'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Flashcard> dueCards,
    List<Flashcard> allCards,
  ) {
    final dueCount = dueCards.length;
    final totalCount = allCards.length;

    return RefreshIndicator(
      onRefresh: () async {
        // Providers will auto-refresh when we navigate back
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Due Now',
                        value: '$dueCount',
                        color: AppColors.warning,
                        icon: Icons.schedule,
                      ),
                    ),
                    Container(height: 40, width: 1, color: AppColors.divider),
                    Expanded(
                      child: _StatItem(
                        label: 'Total Cards',
                        value: '$totalCount',
                        color: AppColors.primary,
                        icon: Icons.style,
                      ),
                    ),
                    Container(height: 40, width: 1, color: AppColors.divider),
                    Expanded(
                      child: _StatItem(
                        label: 'Mastered',
                        value: '${totalCount - dueCount}',
                        color: AppColors.success,
                        icon: Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                if (dueCount > 0) ...[
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Start Review ($dueCount cards)',
                    icon: Icons.play_arrow,
                    onPressed: () => context.push('/flashcards/study'),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    'All caught up! 🎉',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  onTap: () => context.push('/flashcards/generate'),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate with AI',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create from topics',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  onTap: () => context.push('/flashcards/study'),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 32,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Study Session',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spaced repetition',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Subject Breakdown
          if (allCards.isNotEmpty) ...[
            Text(
              'By Subject',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildSubjectBreakdown(context, allCards),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown(BuildContext context, List<Flashcard> cards) {
    final subjectCounts = <String, int>{};
    for (final card in cards) {
      subjectCounts[card.subject] = (subjectCounts[card.subject] ?? 0) + 1;
    }

    final subjects = subjectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subjects.map((entry) {
        return Chip(
          label: Text('${entry.key} (${entry.value})'),
          avatar: CircleAvatar(
            radius: 10,
            backgroundColor: _getSubjectColor(entry.key),
          ),
        );
      }).toList(),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return Colors.blue;
      case 'chemistry':
        return Colors.orange;
      case 'biology':
      case 'botany':
      case 'zoology':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSubtle),
        ),
      ],
    );
  }
}
