import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class StudyHubScreen extends StatelessWidget {
  final String? initialSection;

  const StudyHubScreen({super.key, this.initialSection});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _StudySection(
        title: 'Learn',
        subtitle: 'Build understanding, one topic at a time',
        icon: Icons.auto_stories_outlined,
        items: [
          _StudyItem(
            'Subjects & chapters',
            'Browse the NEET syllabus',
            Icons.school_outlined,
            '/subjects/bio?subjectName=Biology',
          ),
          _StudyItem(
            'NCERT library',
            'Read offline',
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
            'Ask the tutor',
            'Get help with a concept',
            Icons.chat_bubble_outline_rounded,
            '/chat',
          ),
        ],
      ),
      _StudySection(
        title: 'Practice',
        subtitle: 'Turn what you know into marks',
        icon: Icons.edit_note_rounded,
        items: [
          _StudyItem(
            'Daily practice paper',
            'A focused mixed set',
            Icons.today_outlined,
            '/dpp/neet',
          ),
          _StudyItem(
            'Topic practice',
            'Questions by subject and chapter',
            Icons.quiz_outlined,
            '/subjects/bio?subjectName=Biology',
          ),
          _StudyItem(
            'Previous year questions',
            'Practice past NEET questions',
            Icons.history_edu_outlined,
            '/pyq',
          ),
          _StudyItem(
            'Mock tests',
            'Timed NEET-style practice',
            Icons.timer_outlined,
            '/test-series',
          ),
          _StudyItem(
            'Mark booster',
            'Revise high-yield concepts',
            Icons.trending_up_rounded,
            '/mark-booster',
          ),
        ],
      ),
      _StudySection(
        title: 'Review',
        subtitle: 'Remember more of what you study',
        icon: Icons.replay_rounded,
        items: [
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
    ];

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text('Study', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Everything you need, in one place.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 24),
            for (final section in sections) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: Icon(
                    section.icon,
                    color: AdaptiveColors.primary(context),
                  ),
                  title: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(section.subtitle),
                  initiallyExpanded:
                      section.title.toLowerCase() ==
                      initialSection?.toLowerCase(),
                  children: [
                    for (
                      var index = 0;
                      index < section.items.length;
                      index++
                    ) ...[
                      if (index > 0) const Divider(height: 1, indent: 56),
                      _StudyRow(item: section.items[index]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudySection {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_StudyItem> items;

  const _StudySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });
}

class _StudyItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _StudyItem(this.title, this.subtitle, this.icon, this.route);
}

class _StudyRow extends StatelessWidget {
  final _StudyItem item;
  const _StudyRow({required this.item});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
    leading: Icon(item.icon, color: AdaptiveColors.primary(context)),
    title: Text(item.title),
    subtitle: Text(item.subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => context.push(item.route),
  );
}
