import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';

/// Learn hub: subjects / NCERT / notes grouped in one place.
///
/// Part of the Today · Learn · Practice · Review · Progress structure —
/// deep study content lives here instead of scattered quick actions.
class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        title: 'Subjects & Chapters',
        subtitle: 'Biology • Physics • Chemistry topic browser',
        icon: Icons.school_rounded,
        color: SubjectColors.biology,
        route: '/subjects/bio?subjectName=Biology',
      ),
      (
        title: 'NCERT Resource Library',
        subtitle: 'Read every chapter offline',
        icon: Icons.library_books_rounded,
        color: AppColors.primary,
        route: '/resources',
      ),
      (
        title: 'Allen Study Modules',
        subtitle: 'Theory, illustrations & exercises',
        icon: Icons.menu_book_rounded,
        color: SubjectColors.physics,
        route: '/study-modules',
      ),
      (
        title: 'Flashcards',
        subtitle: 'Memory decks & spaced recall',
        icon: Icons.style_rounded,
        color: SubjectColors.chemistry,
        route: '/flashcards',
      ),
      (
        title: 'AI Tutor',
        subtitle: 'Doubts, explanations & NCERT help',
        icon: Icons.psychology_rounded,
        color: AppColors.primary,
        route: '/chat',
      ),
    ];

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(title: const Text('Learn'), centerTitle: false),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final e = entries[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: e.color.withValues(alpha: 0.12),
                child: Icon(e.icon, color: e.color),
              ),
              title: Text(
                e.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(e.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push(e.route),
            ),
          );
        },
      ),
    );
  }
}
