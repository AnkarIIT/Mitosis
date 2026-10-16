import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';

/// Practice hub: quiz, DPP and mock tests grouped in one place.
///
/// Part of the Today · Learn · Practice · Review · Progress structure.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        title: 'Daily Practice Paper',
        subtitle: '20 mixed NEET questions',
        icon: Icons.edit_note_rounded,
        color: SubjectColors.biology,
        route: '/dpp/neet',
      ),
      (
        title: 'Mock Tests',
        subtitle: 'Full-length CBT with marking & timer',
        icon: Icons.quiz_rounded,
        color: SubjectColors.physics,
        route: '/test-series',
      ),
      (
        title: 'PYQ Papers',
        subtitle: 'Previous-year NEET papers',
        icon: Icons.history_edu_rounded,
        color: SubjectColors.chemistry,
        route: '/pyq',
      ),
      (
        title: 'Mark Booster',
        subtitle: 'High-yield revision drills',
        icon: Icons.rocket_launch_outlined,
        color: AppColors.primary,
        route: '/mark-booster',
      ),
      (
        title: 'Study Planner',
        subtitle: "Today's plan & milestones",
        icon: Icons.calendar_month_rounded,
        color: AppColors.primary,
        route: '/study-plan',
      ),
    ];

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(title: const Text('Practice'), centerTitle: false),
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
