import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models/subject_model.dart';
import '../../core/models/question_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../quiz/enhanced_quiz_screen.dart';

class TopicDetailScreen extends ConsumerWidget {
  final Topic topic;
  final String subjectName;
  final String chapterName;

  const TopicDetailScreen({
    super.key,
    required this.topic,
    required this.subjectName,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsForTopicProvider(topic.id));
    final progress = ref.watch(userProgressProvider).topicProgress[topic.id];
    final accuracy = progress?.accuracy ?? 0.0;
    final isCompleted = progress?.isCompleted ?? false;
    final hasQuestions = questions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(topic.name), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topic.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Chapter: $chapterName',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoPill(
                        label: 'Questions',
                        value: '${questions.length}',
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      _InfoPill(
                        label: 'Difficulty',
                        value: topic.difficulty,
                        color: AppColors.secondary.withValues(alpha: 0.15),
                      ),
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
            const SizedBox(height: 24),
            Text(
              'Why this topic matters',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              topic.description ??
                  'This topic is essential for building strong NEET fundamentals. Practice questions here reinforce core concepts and help improve accuracy for the related chapter.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: 24),
            // === KEY CONCEPTS SECTION ===
            Text(
              'Key Concepts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._getKeyConceptsForTopic(topic).map((concept) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        concept,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            // === DIFFICULTY BREAKDOWN ===
            Text(
              'Question Difficulty',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDifficultyBreakdown(context, questions),
            const SizedBox(height: 24),
            Text(
              'Topic progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: hasQuestions ? (accuracy / 100).clamp(0.0, 1.0) : 0.0,
              minHeight: 10,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              isCompleted
                  ? 'Topic completed'
                  : hasQuestions
                  ? 'Keep practicing to improve your accuracy'
                  : 'No practice questions available yet.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasQuestions
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnhancedQuizScreen(
                                  questions: questions,
                                  topicName: topic.name,
                                  topicId: topic.id,
                                  subject: subjectName,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      hasQuestions ? 'Start Topic Quiz' : 'No Questions Yet',
                    ),
                  ),
                ),
              ],
            ),
            if (hasQuestions) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  final question = questions.first;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sample Question'),
                      content: Text(question.questionText),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Preview first question'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<String> _getKeyConceptsForTopic(Topic topic) {
  // In a real app, this would come from the model or a database
  // For now, we provide some sample concepts based on the topic
  final concepts = {
    'Characteristics of Living Organisms': [
      'Metabolism: Sum total of all chemical reactions',
      'Growth: Irreversible increase in mass and number',
      'Reproduction: Production of progeny similar to parents',
      'Consciousness: Ability to sense and respond to environment',
    ],
    'Diversity in Living Organisms': [
      'Binomial Nomenclature: Genus and Species naming',
      'Taxonomic Hierarchy: Kingdom to Species',
      'Systematics: Study of evolutionary relationships',
      'Herbaria and Museums: Tools for taxonomic study',
    ],
    'Mole Concept': [
      "Avogadro's Number: 6.022 × 10²³ particles",
      'Molar Mass: Mass of one mole of substance',
      'STP Conditions: 22.4 L for 1 mole of gas',
      'Empirical and Molecular Formulas',
    ],
    'Kinematics': [
      'Scalar vs Vector: Distance vs Displacement',
      'Average vs Instantaneous Speed/Velocity',
      'Uniform vs Non-uniform Acceleration',
      'Relative Motion in 1D',
    ],
  };

  return concepts[topic.name] ??
      [
        'Core principles and definitions of ${topic.name}',
        'Key mechanisms and processes involved',
        'Important formulas and relationships',
        'Common applications and examples',
      ];
}

Widget _buildDifficultyBreakdown(BuildContext context, List<Question> questions) {
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
    height: 180,
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                if (easyCount > 0)
                  PieChartSectionData(
                    color: Colors.green.shade400,
                    value: easyCount.toDouble(),
                    title: '${(easyCount / questions.length * 100).toInt()}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (mediumCount > 0)
                  PieChartSectionData(
                    color: Colors.orange.shade400,
                    value: mediumCount.toDouble(),
                    title: '${(mediumCount / questions.length * 100).toInt()}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (hardCount > 0)
                  PieChartSectionData(
                    color: Colors.red.shade400,
                    value: hardCount.toDouble(),
                    title: '${(hardCount / questions.length * 100).toInt()}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textDark),
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
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
