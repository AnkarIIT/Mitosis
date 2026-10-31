import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/feature_flags.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';

class StudyHubScreen extends ConsumerStatefulWidget {
  final String? initialSection;

  const StudyHubScreen({super.key, this.initialSection});

  @override
  ConsumerState<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends ConsumerState<StudyHubScreen> {
  late String _section;

  @override
  void initState() {
    super.initState();
    _section = _validSection(widget.initialSection);
  }

  @override
  void didUpdateWidget(covariant StudyHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _section = _validSection(widget.initialSection);
    }
  }

  String _validSection(String? value) {
    const sections = {'Learn', 'Practice', 'Review'};
    return sections.firstWhere(
      (section) => section.toLowerCase() == value?.toLowerCase(),
      orElse: () => 'Learn',
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text(
                  'Study',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a subject or pick up a practice session.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdaptiveColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),
                _StudySections(
                  selected: _section,
                  onSelected: (value) => setState(() => _section = value),
                ),
                const SizedBox(height: 24),
                if (_section == 'Learn') ...[
                  const _SectionHeading(
                    title: 'Browse subjects',
                    subtitle: 'Start with any part of the NEET syllabus',
                  ),
                  const SizedBox(height: 8),
                  _StudyList(
                    items: [
                      for (final subject in subjects)
                        _StudyItem(
                          subject.name,
                          '${subject.chapters.length} chapters',
                          _subjectIcon(subject.id),
                          '/subjects/${subject.id}?subjectName=${Uri.encodeComponent(subject.name)}',
                          color: SubjectColors.of(subject.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeading(title: 'Study resources'),
                  const SizedBox(height: 8),
                  _StudyList(
                    items: const [
                      _StudyItem(
                        'NCERT library',
                        'Read available chapters offline',
                        Icons.library_books_outlined,
                        '/resources',
                      ),
                      _StudyItem(
                        'Study modules',
                        'Lessons and exercises',
                        Icons.menu_book_outlined,
                        '/study-modules',
                      ),
                      _StudyItem(
                        'AI tutor',
                        'Local explanations where available',
                        Icons.chat_bubble_outline_rounded,
                        '/chat',
                      ),
                    ],
                  ),
                ] else if (_section == 'Practice') ...[
                  const _SectionHeading(
                    title: 'Choose how to practice',
                    subtitle: 'Short question sets or timed exam practice',
                  ),
                  const SizedBox(height: 8),
                  _StudyList(
                    items: [
                      for (final subject in subjects)
                        _StudyItem(
                          '${subject.name} topics',
                          'Questions by chapter and topic',
                          _subjectIcon(subject.id),
                          '/subjects/${subject.id}?subjectName=${Uri.encodeComponent(subject.name)}',
                          color: SubjectColors.of(subject.id),
                        ),
                      const _StudyItem(
                        'Daily practice paper',
                        'A focused mixed question set',
                        Icons.today_outlined,
                        '/dpp/neet',
                      ),
                      if (FeatureFlags.pyqDownloads)
                        const _StudyItem(
                          'Previous year questions',
                          'Practice past NEET questions',
                          Icons.history_edu_outlined,
                          '/pyq',
                        ),
                      const _StudyItem(
                        'Mock tests',
                        'Timed NEET-style practice',
                        Icons.timer_outlined,
                        '/test-series',
                      ),
                      const _StudyItem(
                        'Mark booster',
                        'Review high-yield concepts',
                        Icons.trending_up_rounded,
                        '/mark-booster',
                      ),
                    ],
                  ),
                ] else ...[
                  const _SectionHeading(
                    title: 'Make revision count',
                    subtitle: 'Return to concepts and questions you have seen',
                  ),
                  const SizedBox(height: 8),
                  _StudyList(
                    items: const [
                      _StudyItem(
                        'Flashcards',
                        'Recall and spaced repetition',
                        Icons.style_outlined,
                        '/flashcards',
                      ),
                      _StudyItem(
                        'Error book',
                        'Revisit questions you missed',
                        Icons.menu_book_outlined,
                        '/error-book',
                      ),
                      _StudyItem(
                        'Bookmarks',
                        'Return to saved questions',
                        Icons.bookmark_border_rounded,
                        '/bookmarks',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _subjectIcon(String id) => switch (id) {
    'phys' => Icons.bolt_outlined,
    'chem' => Icons.science_outlined,
    _ => Icons.biotech_outlined,
  };
}

class _StudySections extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _StudySections({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final section in const ['Learn', 'Practice', 'Review']) ...[
        if (section != 'Learn') const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            button: true,
            selected: selected == section,
            child: Material(
              color: selected == section
                  ? AdaptiveColors.primary(context)
                  : AdaptiveColors.surface(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: () => onSelected(section),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: selected == section
                          ? AdaptiveColors.primary(context)
                          : AdaptiveColors.outlineVariant(context),
                    ),
                  ),
                  child: Text(
                    section,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected == section
                          ? AdaptiveColors.onPrimary(context)
                          : AdaptiveColors.textPrimary(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class _StudyItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color? color;

  const _StudyItem(
    this.title,
    this.subtitle,
    this.icon,
    this.route, {
    this.color,
  });
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeading({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AdaptiveColors.textSecondary(context),
          ),
        ),
      ],
    ],
  );
}

class _StudyList extends StatelessWidget {
  final List<_StudyItem> items;
  const _StudyList({required this.items});

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0)
            Divider(
              height: 1,
              indent: 56,
              color: AdaptiveColors.outlineVariant(context),
            ),
          _StudyRow(item: items[index]),
        ],
      ],
    ),
  );
}

class _StudyRow extends StatelessWidget {
  final _StudyItem item;
  const _StudyRow({required this.item});

  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 12,
    leading: Icon(
      item.icon,
      color: item.color ?? AdaptiveColors.primary(context),
    ),
    title: Text(item.title),
    subtitle: Text(item.subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => context.push(item.route),
  );
}
