import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/question_model.dart';

class ErrorBookScreen extends ConsumerWidget {
  const ErrorBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorQuestionsAsync = ref.watch(errorBookProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Warm beige background
      appBar: AppBar(
        title: const Text('Error Book'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: errorQuestionsAsync.when(
        data: (questions) => questions.isEmpty
            ? _buildEmptyState(context)
            : _buildQuestionList(context, questions, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Error Book is Empty!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Incorrectly answered questions will appear here automatically for you to practice.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList(
    BuildContext context,
    List<Question> questions,
    WidgetRef ref,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Review and re-test your mistakes. Once you answer correctly in a re-test, they can be removed.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              return _buildQuestionCard(context, q, ref);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _startReTest(context, questions),
              icon: const Icon(Icons.play_arrow),
              label: const Text('RE-TEST ALL ERRORS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    Question question,
    WidgetRef ref,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        title: Text(
          question.questionText,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${question.subject} • ${question.chapter}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correct Answer:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  question.correctAnswer,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Explanation:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  question.explanation ?? 'No explanation available',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        await db.removeFromErrorBook(question.id);
                        ref.invalidate(errorBookProvider);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove from Error Book'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startReTest(BuildContext context, List<Question> questions) {
    context.push(
      '/quiz',
      extra: {
        'questions': questions,
        'topicName': 'Error Book Re-test',
        'topicId': 'error_retest',
        'subject': 'Mixed',
      },
    );
  }
}
