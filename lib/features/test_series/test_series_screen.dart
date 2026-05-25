import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/question_model.dart';
import '../quiz/enhanced_quiz_screen.dart';

class TestSeriesScreen extends ConsumerWidget {
  const TestSeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allQuestions = ref.watch(allQuestionsProvider);
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Series'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Full Mock Tests'),
            _buildTestCard(
              context,
              title: 'NEET Full Mock Test',
              subtitle: '180 Questions • 180 Minutes',
              icon: Icons.assignment_turned_in,
              color: AppColors.primary,
              onTap: () => _startTest(context, ref, allQuestions, 'Full Mock Test', 'mock'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Subject-wise Tests'),
            ...subjects.map((subject) {
              final subjectQuestions = allQuestions.where((q) => q.subject == subject.name).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTestCard(
                  context,
                  title: '${subject.name} Subject Test',
                  subtitle: '${subjectQuestions.length} Questions • ${subjectQuestions.length} Minutes',
                  icon: Icons.science,
                  color: _getSubjectColor(subject.name),
                  onTap: () => _startTest(context, ref, subjectQuestions, '${subject.name} Test', 'subject', subjectName: subject.name),
                ),
              );
            }),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Custom Test'),
            _buildTestCard(
              context,
              title: 'Daily Practice Set',
              subtitle: '20 Randomized Questions',
              icon: Icons.bolt,
              color: Colors.orange,
              onTap: () {
                final shuffled = List<Question>.from(allQuestions)..shuffle();
                _startTest(context, ref, shuffled.take(20).toList(), 'Daily Practice', 'topic');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }

  void _startTest(
    BuildContext context,
    WidgetRef ref,
    List<Question> questions,
    String title,
    String type, {
    String? subjectName,
  }) {
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available for this test.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedQuizScreen(
          questions: questions,
          topicName: title,
          topicId: type == 'mock' ? 'mock_test' : (subjectName ?? 'custom_test'),
          subject: subjectName ?? 'Mixed',
        ),
      ),
    );
  }

  Color _getSubjectColor(String name) {
    switch (name.toLowerCase()) {
      case 'biology': return Colors.green;
      case 'chemistry': return Colors.blue;
      case 'physics': return Colors.orange;
      default: return AppColors.primary;
    }
  }
}
