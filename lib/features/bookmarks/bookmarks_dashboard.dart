import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/models/question_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class BookmarksDashboard extends ConsumerWidget {
  const BookmarksDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final allQuestionsAsync = ref.watch(allQuestionsProvider);

    return allQuestionsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: const Text('Revision Vault'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load bookmarked questions right now.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (allQuestions) {
        final bookmarkedQuestions = allQuestions.where((question) {
          return bookmarks.any((b) => b.questionId == question.id);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Revision Vault'),
            centerTitle: true,
            elevation: 0,
          ),
          body: bookmarkedQuestions.isEmpty
              ? _buildEmptyState(context)
              : _buildBookmarksList(context, ref, bookmarkedQuestions),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Revision Vault is Empty',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Questions you bookmark during quizzes will appear here for fast revision.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList(
    BuildContext context,
    WidgetRef ref,
    List<Question> questions,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${questions.length} Questions Saved',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap questions below to reveal formulas, core concepts, and NCERT links.',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Saved list title
          Text(
            'Bookmarked Items',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Question list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return _buildQuestionCard(context, ref, question);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    WidgetRef ref,
    Question question,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: _getSubjectBadge(question.subject),
            title: Text(
              question.questionText,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${question.chapter} • ${question.difficulty}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary,
                ),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.primary),
              tooltip: 'Delete bookmark',
              onPressed: () {
                ref
                    .read(bookmarksProvider.notifier)
                    .toggleBookmark(
                      questionId: question.id,
                      subject: question.subject,
                      topicId: question.topic,
                    );
              },
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppColors.secondary),
                    const SizedBox(height: 8),

                    // Options list
                    const Text(
                      'Options:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...question.options.map((option) {
                      final isCorrect = option == question.correctAnswer;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.secondary.withValues(alpha: 0.03),
                          border: Border.all(
                            color: isCorrect
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : AppColors.secondary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 16,
                              color: isCorrect
                                  ? AppColors.primary
                                  : AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: isCorrect
                                      ? AppColors.primary
                                      : AdaptiveColors.textPrimary(context),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    // Explanation block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Revision Explanation',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.explanation ?? 'No explanation available',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (question.ncertReference != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '📖 Reference: ${question.ncertReference}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSubjectBadge(String subject) {
    Color color;
    IconData icon;

    switch (subject.toLowerCase()) {
      case 'biology':
        color = Colors.green;
        icon = Icons.health_and_safety;
        break;
      case 'chemistry':
        color = Colors.blue;
        icon = Icons.science;
        break;
      case 'physics':
        color = Colors.orange;
        icon = Icons.bolt;
        break;
      default:
        color = Colors.purple;
        icon = Icons.book;
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
