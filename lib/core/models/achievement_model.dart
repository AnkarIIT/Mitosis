import 'package:flutter/material.dart';

enum AchievementTier { bronze, silver, gold, platinum }

enum AchievementCategory {
  gettingStarted('Getting Started'),
  quizMaster('Quiz Master'),
  streak('Streak'),
  accuracy('Accuracy'),
  scholar('Scholar'),
  special('Special');

  final String label;
  const AchievementCategory(this.label);
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementTier tier;
  final AchievementCategory category;
  final int threshold;
  final String statKey;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tier,
    required this.category,
    required this.threshold,
    required this.statKey,
  });

  static const List<Achievement> all = [
    Achievement(
      id: 'first_quiz',
      title: 'First Steps',
      description: 'Complete your first quiz attempt.',
      icon: Icons.school_rounded,
      color: Colors.green,
      tier: AchievementTier.bronze,
      category: AchievementCategory.gettingStarted,
      threshold: 1,
      statKey: 'quizCount',
    ),
    Achievement(
      id: 'first_10',
      title: 'Getting Started',
      description: 'Solve 10 questions.',
      icon: Icons.check_circle_outline,
      color: Colors.teal,
      tier: AchievementTier.bronze,
      category: AchievementCategory.gettingStarted,
      threshold: 10,
      statKey: 'totalAttempted',
    ),
    Achievement(
      id: 'first_100',
      title: 'Centurion',
      description: 'Solve 100 questions.',
      icon: Icons.horizontal_rule_rounded,
      color: Colors.blue,
      tier: AchievementTier.silver,
      category: AchievementCategory.gettingStarted,
      threshold: 100,
      statKey: 'totalAttempted',
    ),
    Achievement(
      id: 'first_1000',
      title: 'Dedicated Learner',
      description: 'Solve 1,000 questions.',
      icon: Icons.military_tech,
      color: Colors.indigo,
      tier: AchievementTier.gold,
      category: AchievementCategory.gettingStarted,
      threshold: 1000,
      statKey: 'totalAttempted',
    ),
    Achievement(
      id: 'streak_3',
      title: '3-Day Streak',
      description: 'Study for 3 consecutive days.',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      tier: AchievementTier.bronze,
      category: AchievementCategory.streak,
      threshold: 3,
      statKey: 'streak',
    ),
    Achievement(
      id: 'streak_7',
      title: 'Weekly Warrior',
      description: 'Maintain a 7-day study streak.',
      icon: Icons.local_fire_department,
      color: Colors.deepOrange,
      tier: AchievementTier.silver,
      category: AchievementCategory.streak,
      threshold: 7,
      statKey: 'streak',
    ),
    Achievement(
      id: 'streak_30',
      title: 'Unstoppable',
      description: 'Maintain a 30-day study streak.',
      icon: Icons.emoji_events,
      color: Colors.amber,
      tier: AchievementTier.gold,
      category: AchievementCategory.streak,
      threshold: 30,
      statKey: 'streak',
    ),
    Achievement(
      id: 'accuracy_60',
      title: 'Sharp Mind',
      description: 'Reach 60% overall accuracy.',
      icon: Icons.track_changes,
      color: Colors.cyan,
      tier: AchievementTier.bronze,
      category: AchievementCategory.accuracy,
      threshold: 60,
      statKey: 'accuracy',
    ),
    Achievement(
      id: 'accuracy_80',
      title: 'Precision',
      description: 'Reach 80% overall accuracy.',
      icon: Icons.verified,
      color: Colors.lightBlue,
      tier: AchievementTier.silver,
      category: AchievementCategory.accuracy,
      threshold: 80,
      statKey: 'accuracy',
    ),
    Achievement(
      id: 'accuracy_95',
      title: 'Perfectionist',
      description: 'Reach 95% overall accuracy.',
      icon: Icons.star,
      color: Colors.amber,
      tier: AchievementTier.platinum,
      category: AchievementCategory.accuracy,
      threshold: 95,
      statKey: 'accuracy',
    ),
    Achievement(
      id: 'quiz_10',
      title: 'Quiz Enthusiast',
      description: 'Complete 10 quizzes.',
      icon: Icons.quiz,
      color: Colors.purple,
      tier: AchievementTier.bronze,
      category: AchievementCategory.quizMaster,
      threshold: 10,
      statKey: 'quizCount',
    ),
    Achievement(
      id: 'quiz_50',
      title: 'Quiz Champion',
      description: 'Complete 50 quizzes.',
      icon: Icons.emoji_events,
      color: Colors.deepPurple,
      tier: AchievementTier.gold,
      category: AchievementCategory.quizMaster,
      threshold: 50,
      statKey: 'quizCount',
    ),
    Achievement(
      id: 'full_mock',
      title: 'Mock Test Veteran',
      description: 'Complete a full-length mock test.',
      icon: Icons.assignment_turned_in,
      color: Colors.brown,
      tier: AchievementTier.silver,
      category: AchievementCategory.special,
      threshold: 1,
      statKey: 'fullMockCount',
    ),
  ];

  static Achievement? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
