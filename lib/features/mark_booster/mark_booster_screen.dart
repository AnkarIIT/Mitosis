import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/mark_booster_model.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/mark_booster_service.dart';
import '../../core/theme/app_colors.dart';
import '../quiz/enhanced_quiz_screen.dart';

class MarkBoosterScreen extends ConsumerStatefulWidget {
  const MarkBoosterScreen({super.key});

  @override
  ConsumerState<MarkBoosterScreen> createState() => _MarkBoosterScreenState();
}

class _MarkBoosterScreenState extends ConsumerState<MarkBoosterScreen> {
  int _drillSize = 10;

  static const List<int> _drillSizes = [5, 10, 15, 20];

  Future<void> _launchDrill(MarkBoosterDiagnosis diagnosis) async {
    final allQuestions = await ref.read(allQuestionsProvider.future);
    final drill = MarkBoosterService.buildDrill(
      diagnosis: diagnosis,
      allQuestions: allQuestions,
      size: _drillSize,
    );

    if (!mounted) return;
    if (drill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No questions available yet. Answer more questions to build your drill.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedQuizScreen(
          questions: drill,
          topicName: 'Mark Booster Drill',
          topicId: 'mark_booster',
          subject: 'Mixed',
          testType: 'booster',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diagnosisAsync = ref.watch(markBoosterDiagnosisProvider);

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      appBar: AppBar(
        title: const Text('Mark Booster'),
        centerTitle: false,
      ),
      body: diagnosisAsync.when(
        data: (diagnosis) => _buildBody(context, diagnosis),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your plan.\n$error'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MarkBoosterDiagnosis diagnosis) {
    final sessions = MarkBoosterService.extractBoosterSessions(
      ref.watch(userProgressProvider).quizAttempts,
    );

    if (!diagnosis.hasWeaknesses &&
        sessions.isEmpty &&
        diagnosis.masteredTopics.isEmpty) {
      return const _EmptyState();
    }

    final canDrill =
        diagnosis.errorBookQuestions.isNotEmpty ||
        diagnosis.weakTopics.any((w) => w.questionsAvailable > 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(
          diagnosis: diagnosis,
          drillSize: _drillSize,
          canDrill: canDrill,
          onDrillSizeChanged: _setDrillSize,
          onLaunch: () => _launchDrill(diagnosis),
        ),
        if (diagnosis.masteredTopics.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Mastered',
            subtitle:
                'Topics you have driven to 60%+ accuracy',
            icon: Icons.emoji_events_outlined,
          ),
          const SizedBox(height: 8),
          ...diagnosis.masteredTopics.map((m) => _MasteredTopicRow(mastered: m)),
        ],
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Focus Topics',
          subtitle:
              'Sub-topics where your accuracy is below 60%',
          icon: Icons.flag_circle_outlined,
        ),
        const SizedBox(height: 8),
        if (diagnosis.weakTopics.isEmpty)
          _InfoCard(
            icon: Icons.check_circle_outline,
            text:
                'No weak topics yet. Keep practising and they will appear here.',
          )
        else
          ...diagnosis.weakTopics.map(
            (w) => _WeakTopicCard(weakness: w),
          ),
        if (diagnosis.typeWeaknesses.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Question Types',
            subtitle: 'Where your Error Book answers are concentrated',
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 8),
          ...diagnosis.typeWeaknesses.map(
            (t) => _DistributionRow(
              label: t.type,
              value: t.errorCount,
              share: t.shareOfErrors,
            ),
          ),
        ],
        if (diagnosis.difficultyWeaknesses.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Difficulty',
            subtitle: 'Which difficulty band costs you most marks',
            icon: Icons.speed_outlined,
          ),
          const SizedBox(height: 8),
          ...diagnosis.difficultyWeaknesses.map(
            (d) => _DistributionRow(
              label: d.difficulty,
              value: d.errorCount,
              share: d.shareOfErrors,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Drill History',
          subtitle: 'Your past Mark Booster sessions',
          icon: Icons.history,
        ),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          _InfoCard(
            icon: Icons.info_outline,
            text:
                'No drills yet. Launch your first Booster Drill and your '
                'progress will be tracked here.',
          )
        else
          ...sessions.map((s) => _SessionCard(attempt: s)),
        const SizedBox(height: 24),
      ],
    );
  }

  void _setDrillSize(int size) {
    setState(() => _drillSize = size);
  }
}

class _HeroCard extends StatelessWidget {
  final MarkBoosterDiagnosis diagnosis;
  final int drillSize;
  final bool canDrill;
  final ValueChanged<int> onDrillSizeChanged;
  final VoidCallback onLaunch;

  const _HeroCard({
    required this.diagnosis,
    required this.drillSize,
    required this.canDrill,
    required this.onDrillSizeChanged,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF143D3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Your personalised improvement plan',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${diagnosis.weakTopics.length} weak topic${diagnosis.weakTopics.length == 1 ? '' : 's'} · ${diagnosis.errorBookCount} unresolved error${diagnosis.errorBookCount == 1 ? '' : 's'} · ${diagnosis.masteredTopicCount} mastered',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each drill re-attacks your weak spots, pushes accuracy toward 60% mastery, and clears your Error Book.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            'Drill size',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final size in _MarkBoosterScreenState._drillSizes) ...[
                _SizeChip(
                  size: size,
                  selected: size == drillSize,
                  onTap: () => onDrillSizeChanged(size),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canDrill ? onLaunch : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.bolt),
              label: const Text(
                'Launch Booster Drill',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final int size;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white54,
          ),
        ),
        child: Text(
          '$size',
          style: TextStyle(
            color: selected ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _WeakTopicCard extends StatelessWidget {
  final WeakTopicDiagnosis weakness;

  const _WeakTopicCard({required this.weakness});

  @override
  Widget build(BuildContext context) {
    final accuracy = weakness.accuracy;
    final color = accuracy < 30
        ? AppColors.error
        : accuracy < 45
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adaptiveDivider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  weakness.topic.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.adaptiveText(context),
                  ),
                ),
              ),
              Text(
                '${accuracy.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${weakness.chapterName} · ${weakness.subjectName}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.adaptiveSubtleText(context),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: weakness.masteryProgress,
              minHeight: 6,
              backgroundColor: AppColors.adaptiveDivider(context),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(weakness.masteryProgress * 100).toStringAsFixed(0)}% of the way to 60% mastery',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.adaptiveSubtleText(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.history, size: 14,
                  color: AppColors.adaptiveSubtleText(context)),
              const SizedBox(width: 4),
              Text(
                '${weakness.questionsAttempted} attempted',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.adaptiveSubtleText(context),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.library_books_outlined, size: 14,
                  color: AppColors.adaptiveSubtleText(context)),
              const SizedBox(width: 4),
              Text(
                '${weakness.questionsAvailable} in bank',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.adaptiveSubtleText(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasteredTopicRow extends StatelessWidget {
  final MasteredTopic mastered;

  const _MasteredTopicRow({required this.mastered});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mastered.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${mastered.chapterName} · ${mastered.subjectName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
                ),
              ],
            ),
          ),
          Text(
            '${mastered.accuracy.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final QuizAttempt attempt;

  const _SessionCard({required this.attempt});

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';
    if (isToday) return 'Today · $time';
    return '${date.day} ${months[date.month - 1]} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = attempt.accuracy;
    final color = accuracy >= 60
        ? AppColors.success
        : accuracy >= 30
            ? AppColors.warning
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adaptiveDivider(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(attempt.attemptedAt),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.adaptiveText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${attempt.score}/${attempt.totalQuestions} correct · ${attempt.incorrectCount} wrong',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.adaptiveSubtleText(context),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${accuracy.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${attempt.neetScore} NEET',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.adaptiveSubtleText(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final String label;
  final int value;
  final double share;

  const _DistributionRow({
    required this.label,
    required this.value,
    required this.share,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.adaptiveText(context),
              ),
            ),
          ),
          Text(
            '$value · ${share.toStringAsFixed(0)}% of errors',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.adaptiveSubtleText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adaptiveText(context),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.adaptiveSubtleText(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adaptiveDivider(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.adaptiveText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 72,
              color: AppColors.adaptiveSubtleText(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No weaknesses detected yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.adaptiveText(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Answer more questions across chapters and attempt the Error Book '
              're-tests. Your weak spots will surface here as personalised drills.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.adaptiveSubtleText(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
