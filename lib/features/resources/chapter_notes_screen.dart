import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/models/study_resource_content.dart';
import '../../core/models/subject_model.dart' as subject_model;
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';

class ChapterNotesScreen extends ConsumerWidget {
  final String chapterId;

  const ChapterNotesScreen({super.key, required this.chapterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nullable: chapterByIdProvider returns null for an unknown id, and the
    // very next line handles that case.
    final subject_model.Chapter? chapter = ref.watch(
      chapterByIdProvider(chapterId),
    );
    if (chapter == null) {
      return const Scaffold(body: Center(child: Text('Chapter not found')));
    }
    final content = ref.watch(studyResourceContentProvider(chapterId));

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: Text('${chapter.name} Notes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Original Mitosis revision notes • ${chapter.classLevel ?? 'NEET'}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildRevisionStrip(context, chapter, content),
          const SizedBox(height: 16),
          _buildAuthoredSection(context, content),
          const SizedBox(height: 16),
          ...chapter.topics.map(
            (topic) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  topic.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${topic.difficulty} • Quick revision'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      topic.summary?.trim().isNotEmpty == true
                          ? topic.summary!
                          : 'Detailed notes for this topic are being prepared.',
                      style: const TextStyle(height: 1.55),
                    ),
                  ),
                  if (topic.keyPoints?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    ...topic.keyPoints!.map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(child: Text(point)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _practiceActions(
                    context,
                    chapter.subjectId,
                    topic.id,
                    topic.name,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionStrip(
    BuildContext context,
    subject_model.Chapter chapter,
    StudyResourceContent content,
  ) {
    final points = content.keyFacts.take(8).toList();
    return Card(
      color: AdaptiveColors.primary(context).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'One-page revision sheet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (points.isEmpty)
              const Text('Topic-wise revision points are being prepared.')
            else
              ...points.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('• $point'),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              chapter.subjectId == 'bio'
                  ? 'Fact and diagram revision'
                  : 'Formula, concept and mistake revision',
              style: TextStyle(color: AdaptiveColors.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthoredSection(
    BuildContext context,
    StudyResourceContent content,
  ) {
    final sections = <({String title, IconData icon, List<String> items})>[
      (
        title: 'High-yield concept map',
        icon: Icons.account_tree,
        items: content.diagrams,
      ),
      (
        title: 'Formula and fact sheet',
        icon: Icons.functions,
        items: content.formulas,
      ),
      (title: 'PYQ traps', icon: Icons.warning_amber, items: content.pyqTraps),
      (
        title: 'Revision rules',
        icon: Icons.fact_check,
        items: content.revisionRules,
      ),
    ].where((section) => section.items.isNotEmpty).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mitosis authored guide',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(content.overview, style: const TextStyle(height: 1.5)),
            for (final section in sections) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(section.icon, size: 19, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...section.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $item', style: const TextStyle(height: 1.4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _practiceActions(
    BuildContext context,
    String subjectId,
    String topicId,
    String topicName,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push(
            '/quiz?topicId=${Uri.encodeComponent(topicId)}'
            '&topicName=${Uri.encodeComponent(topicName)}'
            '&subject=${Uri.encodeComponent(subjectId)}',
          ),
          icon: const Icon(Icons.quiz, size: 18),
          label: const Text('Quiz'),
        ),
        FilledButton.icon(
          // Pass the subject NAME, not a lowercased id: DppScreen resolves
          // either, but the DPP engine matches the questions table on the
          // exact name, so '/dpp/chemistry' produced an empty pool and a
          // "not enough questions" message on every press.
          onPressed: () => context.push('/dpp/${_subjectName(subjectId)}'),
          icon: const Icon(Icons.assignment, size: 18),
          label: const Text('DPP'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push(
            '/quiz?topicId=${Uri.encodeComponent(topicId)}'
            '&topicName=${Uri.encodeComponent(topicName)}'
            '&subject=${Uri.encodeComponent(subjectId)}'
            '&testType=pyq',
          ),
          icon: const Icon(Icons.history_edu, size: 18),
          label: const Text('PYQ'),
        ),
      ],
    );
  }

  String _subjectName(String subjectId) {
    switch (subjectId) {
      case 'bio':
        return 'Biology';
      case 'phys':
        return 'Physics';
      case 'chem':
        return 'Chemistry';
      default:
        return subjectId;
    }
  }
}
