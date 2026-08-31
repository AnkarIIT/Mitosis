import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import 'package:go_router/go_router.dart';

class AllenStudyModuleScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;

  const AllenStudyModuleScreen({super.key, this.initialSubjectId});

  @override
  ConsumerState<AllenStudyModuleScreen> createState() =>
      _AllenStudyModuleScreenState();
}

class _AllenStudyModuleScreenState extends ConsumerState<AllenStudyModuleScreen> {
  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final initialSubjectId = widget.initialSubjectId;
    final selectedSubjectId = initialSubjectId ??
        (subjects.isNotEmpty ? subjects.first.id : null);

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: const Text('Allen Study Modules'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: AdaptiveColors.textPrimary(context)),
        titleTextStyle: TextStyle(
          color: AdaptiveColors.textPrimary(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: AppColors.secondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.secondary.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubjectSelector(context, subjects, selectedSubjectId),
                Expanded(
                  child: selectedSubjectId == null
                      ? const SizedBox.shrink()
                      : _buildModuleList(
                          context,
                          subjects,
                          selectedSubjectId,
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSubjectSelector(
    BuildContext context,
    List<Subject> subjects,
    String? selectedSubjectId,
  ) {
    if (subjects.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final isSelected = subject.id == selectedSubjectId;
          final color = _getSubjectAccent(subject.id);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(subject.name),
              selected: isSelected,
              onSelected: (_) {
                context.pushReplacement(
                  '/study-modules?subjectId=${Uri.encodeComponent(subject.id)}',
                );
              },
              selectedColor: color.withValues(alpha: 0.15),
              backgroundColor: AdaptiveColors.surface(context),
              labelStyle: TextStyle(
                color: isSelected ? color : AdaptiveColors.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? color : AdaptiveColors.divider(context),
              ),
              avatar: Icon(
                _getSubjectIcon(subject.id),
                size: 18,
                color: isSelected ? color : AdaptiveColors.textSecondary(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModuleList(
    BuildContext context,
    List<Subject> subjects,
    String subjectId,
  ) {
    final subject = subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => subjects.first,
    );

    final chapters = subject.chapters;
    if (chapters.isEmpty) {
      return Center(
        child: Text(
          'No chapters available',
          style: TextStyle(color: AdaptiveColors.textSecondary(context)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _AllenModuleCard(
            subjectId: subjectId,
            subjectName: subject.name,
            chapter: chapter,
          ),
        );
      },
    );
  }

  Color _getSubjectAccent(String id) {
    switch (id.toLowerCase()) {
      case 'biology':
      case 'bio':
        return SubjectColors.biology;
      case 'physics':
      case 'phys':
        return SubjectColors.physics;
      case 'chemistry':
      case 'chem':
        return SubjectColors.chemistry;
      default:
        return SubjectColors.physics;
    }
  }

  IconData _getSubjectIcon(String id) {
    switch (id.toLowerCase()) {
      case 'biology':
      case 'bio':
        return Icons.eco_rounded;
      case 'physics':
      case 'phys':
        return Icons.bolt_rounded;
      case 'chemistry':
      case 'chem':
        return Icons.science_rounded;
      default:
        return Icons.school;
    }
  }
}

class _AllenModuleCard extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final Chapter chapter;

  const _AllenModuleCard({
    required this.subjectId,
    required this.subjectName,
    required this.chapter,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _getSubjectAccent(subjectId);
    final topicCount = chapter.topics.length;

    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            chapter.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$topicCount topics • Allen-style module',
              style: TextStyle(
                fontSize: 12,
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getSubjectIcon(subjectId),
              color: accent,
              size: 22,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: chapter.topics.map((topic) {
            return _AllenTopicTile(
              subjectId: subjectId,
              subjectName: subjectName,
              chapterName: chapter.name,
              topic: topic,
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getSubjectAccent(String id) {
    switch (id.toLowerCase()) {
      case 'biology':
      case 'bio':
        return SubjectColors.biology;
      case 'physics':
      case 'phys':
        return SubjectColors.physics;
      case 'chemistry':
      case 'chem':
        return SubjectColors.chemistry;
      default:
        return SubjectColors.physics;
    }
  }

  IconData _getSubjectIcon(String id) {
    switch (id.toLowerCase()) {
      case 'biology':
      case 'bio':
        return Icons.eco_rounded;
      case 'physics':
      case 'phys':
        return Icons.bolt_rounded;
      case 'chemistry':
      case 'chem':
        return Icons.science_rounded;
      default:
        return Icons.school;
    }
  }
}

class _AllenTopicTile extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final String chapterName;
  final Topic topic;

  const _AllenTopicTile({
    required this.subjectId,
    required this.subjectName,
    required this.chapterName,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openChapterDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AdaptiveColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AdaptiveColors.divider(context).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildModuleMeta(topic),
                    style: TextStyle(
                      fontSize: 12,
                      color: AdaptiveColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AdaptiveColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  String _buildModuleMeta(Topic topic) {
    final parts = <String>['Allen module'];
    if (topic.questionCount > 0) {
      parts.add('${topic.questionCount} Q');
    }
    return parts.join(' • ');
  }

  void _openChapterDetail(BuildContext context) {
    context.push(
      '/study-modules/chapter?subjectId=${Uri.encodeComponent(subjectId)}&chapterName=${Uri.encodeComponent(chapterName)}&topicId=${Uri.encodeComponent(topic.id)}',
    );
  }
}

class AllenChapterDetailScreen extends ConsumerWidget {
  final String subjectId;
  final String chapterName;
  final String topicId;

  const AllenChapterDetailScreen({
    super.key,
    required this.subjectId,
    required this.chapterName,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSubjects = ref.watch(subjectsProvider);
    final subject = allSubjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => allSubjects.isNotEmpty ? allSubjects.first : allSubjects.first,
    );

    final chapter = subject.chapters.firstWhere(
      (c) => c.name == chapterName,
      orElse: () => subject.chapters.isNotEmpty ? subject.chapters.first : subject.chapters.first,
    );

    final topic = chapter.topics.firstWhere(
      (t) => t.id == topicId,
      orElse: () => chapter.topics.isNotEmpty ? chapter.topics.first : chapter.topics.first,
    );

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: Text(topic.name),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: AdaptiveColors.textPrimary(context)),
        titleTextStyle: TextStyle(
          color: AdaptiveColors.textPrimary(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${subject.name} • ${chapter.name}',
              style: TextStyle(
                fontSize: 13,
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            _buildTheoryCard(context, topic),
            const SizedBox(height: 16),
            _buildIllustrationsCard(context, topic),
            const SizedBox(height: 16),
            _buildExercisesCard(context, topic),
            const SizedBox(height: 24),
            _buildStartPracticeButton(context, topic),
          ],
        ),
      ),
    );
  }

  Widget _buildTheoryCard(BuildContext context, Topic topic) {
    final theory = topic.summary?.trim();
    final body = theory != null && theory.isNotEmpty
        ? theory
        : 'This Allen-style module covers the core theory for ${topic.name}. '
              'Study the key concepts carefully, then attempt the exercises '
              'below to check your understanding.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AdaptiveColors.divider(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Theory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AdaptiveColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationsCard(BuildContext context, Topic topic) {
    final illustrations = topic.keyPoints;
    final items = illustrations != null && illustrations.isNotEmpty
        ? illustrations
        : <String>[
              'Understand the definition and core principle behind ${topic.name}.',
              'Relate this concept to previous topics you have already studied.',
              'Draw a quick diagram or flowchart in your notebook.',
              'Note down the most common mistakes students make in NEET.',
            ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AdaptiveColors.divider(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_outlined, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Illustrations & Examples',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AdaptiveColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 10,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesCard(BuildContext context, Topic topic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AdaptiveColors.divider(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Exercises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AdaptiveColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            topic.questionCount > 0
                ? 'This module links to ${topic.questionCount} practice questions. '
                      'Use the practice button below to attempt them topic-wise.'
                : 'Practice questions for this module will be added shortly. '
                      'You can still revise using the theory and illustrations above.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartPracticeButton(BuildContext context, Topic topic) {
    final hasQuestions = topic.questionCount > 0;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          if (hasQuestions) {
            context.push(
              '/quiz?topicId=${Uri.encodeComponent(topic.id)}&topicName=${Uri.encodeComponent(topic.name)}&subject=${Uri.encodeComponent(subjectId)}',
            );
          } else {
            context.push('/test-series');
          }
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
    );
  }
}
