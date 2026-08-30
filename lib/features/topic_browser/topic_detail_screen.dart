import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models/subject_model.dart';
import '../../core/models/question_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/ncert_book_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class TopicDetailScreen extends ConsumerWidget {
  final String topicId;
  final String subjectName;
  final String chapterName;

  const TopicDetailScreen({
    super.key,
    required this.topicId,
    required this.subjectName,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSubjects = ref.watch(subjectsProvider);
    Topic? topic;
    for (final subject in allSubjects) {
      for (final chapter in subject.chapters) {
        try {
          topic = chapter.topics.firstWhere((t) => t.id == topicId);
          break;
        } catch (_) {}
      }
      if (topic != null) break;
    }

    if (topic == null) {
      return const Scaffold(body: Center(child: Text('Topic not found')));
    }
    final resolvedTopic = topic;
    final questionsAsync = ref.watch(questionsForTopicProvider(topicId));
    final subjects = ref.watch(subjectsProvider);
    final chapter = subjects
        .expand((s) => s.chapters)
        .where((c) => c.id == resolvedTopic.chapterId)
        .firstOrNull;
    final ncertEntry = chapter == null
        ? null
        : NcertBookCatalog.entryFor(chapter);

    if (questionsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final questions = questionsAsync.valueOrNull ?? [];
    final progress = ref.watch(userProgressProvider).topicProgress[topicId];
    final accuracy = progress?.accuracy ?? 0.0;
    final isCompleted = progress?.isCompleted ?? false;
    final hasQuestions = questions.isNotEmpty;

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: Text(resolvedTopic.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AdaptiveColors.textPrimary(context)),
        titleTextStyle: TextStyle(
          color: AdaptiveColors.textPrimary(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOPIC OVERVIEW CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdaptiveColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AdaptiveColors.divider(context).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subjectName.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  $chapterName',
                        style: TextStyle(
                          color: AdaptiveColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    resolvedTopic.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AdaptiveColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoPill(
                        label: 'Questions',
                        value: '${questions.length}',
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 12),
                      _InfoPill(
                        label: 'Difficulty',
                        value: resolvedTopic.difficulty,
                        color: AppColors.secondary.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 12),
                      _InfoPill(
                        label: 'Accuracy',
                        value: '${accuracy.toStringAsFixed(0)}%',
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- NCERT SUMMARY SECTION ---
            Text(
              'NCERT Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedTopic.summary ??
                        'Review the core concepts from the NCERT textbook to prepare for your test.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _showFullSummary(context, topic!),
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('Read Full Revision Notes'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (ncertEntry != null)
              _buildNcertReaderCard(context, ncertEntry, chapter!),
            const SizedBox(height: 32),

            // --- KEY REVISION POINTS ---
            Text(
              'Quick Revision Points',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            ...(resolvedTopic.keyPoints ?? _getDefaultKeyPoints(topic)).map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 14,
                          color: AdaptiveColors.textPrimary(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),
            // === DIFFICULTY BREAKDOWN ===
            Text(
              'Question Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            _buildDifficultyBreakdown(context, questions),

            const SizedBox(height: 32),
            // === PROGRESS SECTION ===
            Text(
              'Topic Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: hasQuestions ? (accuracy / 100).clamp(0.0, 1.0) : 0.0,
                minHeight: 12,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  accuracy >= 70 ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isCompleted
                  ? '🎯 Mastery Achieved!'
                  : hasQuestions
                  ? 'Aim for 70%+ accuracy to master this topic.'
                  : 'No topic-specific questions are available yet. Try a test series to keep practicing.',
              style: TextStyle(
                color: AdaptiveColors.textSecondary(context),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 48),
            // --- ACTION BUTTONS ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
onPressed: () {
                    if (hasQuestions) {
                      context.push('/quiz?topicId=${Uri.encodeComponent(resolvedTopic.id)}&topicName=${Uri.encodeComponent(resolvedTopic.name)}&subject=${Uri.encodeComponent(subjectName)}');
                      return;
                    }

                    context.push('/test-series');
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  hasQuestions ? 'START TOPIC TEST' : 'TRY TEST SERIES INSTEAD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _openAiTutor(context, topic!),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('ASK AI TUTOR ABOUT THIS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _openAiTutor(BuildContext context, Topic topic) {
    final prompt =
        'Explain ${topic.name} for NEET in a simple, high-yield way. Include the core idea, the most common mistake students make, and one quick practice tip.';

    context.push('/chat?initialMessage=${Uri.encodeComponent(prompt)}');
  }

  Widget _buildNcertReaderCard(
    BuildContext context,
    NcertBookEntry entry,
    Chapter chapter,
  ) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openNcertPdf(context, entry, chapter),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Read the Actual NCERT Chapter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.subject} • ${entry.classLevel} • '
                      'Chapter ${entry.chapterNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdaptiveColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tap paragraphs for questions from that section',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNcertPdf(
    BuildContext context,
    NcertBookEntry entry,
    Chapter chapter,
  ) {
    context.push('/pdf?entryId=${Uri.encodeComponent(entry.assetPath)}');
  }

  void _showFullSummary(BuildContext context, Topic topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AdaptiveColors.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AdaptiveColors.divider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'NCERT Revision Notes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              topic.name,
              style: TextStyle(color: AdaptiveColors.textSecondary(context)),
            ),
            const Divider(height: 40),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      topic.summary ?? 'No summary available.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Key Learning Points',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(topic.keyPoints ?? _getDefaultKeyPoints(topic)).map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AdaptiveColors.textPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'NCERT Tip: Many questions from this topic in previous years have focused on the definitions and examples provided in the textbook.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getDefaultKeyPoints(Topic topic) {
    return [
      'Core principles and definitions of ${topic.name}',
      'Key mechanisms and processes involved',
      'Important formulas and relationships',
      'Common applications and examples',
    ];
  }

  Widget _buildDifficultyBreakdown(
    BuildContext context,
    List<Question> questions,
  ) {
    if (questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No question data available for breakdown'),
        ),
      );
    }

    int easyCount = questions.where((q) => q.difficulty == 'Easy').length;
    int mediumCount = questions.where((q) => q.difficulty == 'Medium').length;
    int hardCount = questions.where((q) => q.difficulty == 'Hard').length;

    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  if (easyCount > 0)
                    PieChartSectionData(
                      color: Colors.green.shade400,
                      value: easyCount.toDouble(),
                      title: '${(easyCount / questions.length * 100).toInt()}%',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (mediumCount > 0)
                    PieChartSectionData(
                      color: Colors.orange.shade400,
                      value: mediumCount.toDouble(),
                      title:
                          '${(mediumCount / questions.length * 100).toInt()}%',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (hardCount > 0)
                    PieChartSectionData(
                      color: Colors.red.shade400,
                      value: hardCount.toDouble(),
                      title: '${(hardCount / questions.length * 100).toInt()}%',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DifficultyLegend(
                  label: 'Easy',
                  count: easyCount,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 8),
                _DifficultyLegend(
                  label: 'Medium',
                  count: mediumCount,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(height: 8),
                _DifficultyLegend(
                  label: 'Hard',
                  count: hardCount,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyLegend extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _DifficultyLegend({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: TextStyle(
            color: AdaptiveColors.textPrimary(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AdaptiveColors.textPrimary(context).withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: AdaptiveColors.textPrimary(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
