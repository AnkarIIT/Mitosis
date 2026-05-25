import 'package:flutter/material.dart';
import 'theme/app_colors.dart';

/// Utility class for common formatting and calculations
class AppUtils {
  /// Format time from seconds to HH:MM:SS
  static String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Get difficulty color
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.primary;
      case 'medium':
        return AppColors.secondary;
      case 'hard':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }

  /// Get difficulty icon
  static IconData getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.help;
    }
  }

  /// Calculate accuracy color based on percentage
  static Color getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return AppColors.primary;
    if (accuracy >= 60) return AppColors.secondary;
    if (accuracy >= 40) return AppColors.secondary;
    return AppColors.primary;
  }

  /// Get subject emoji/icon
  static String getSubjectEmoji(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
        return '🧬';
      case 'chemistry':
        return '⚗️';
      case 'physics':
        return '⚛️';
      default:
        return '📚';
    }
  }

  /// Get subject color
  static Color getSubjectColor(String subject) {
    // All subjects use the primary color for consistency
    return AppColors.primary;
  }

  /// Capitalize first letter
  static String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Get formatted percentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Get accuracy feedback message
  static String getAccuracyFeedback(double accuracy) {
    if (accuracy == 100) return 'Perfect! Outstanding!';
    if (accuracy >= 80) return 'Excellent work!';
    if (accuracy >= 60) return 'Good effort! Keep practicing!';
    if (accuracy >= 40) return 'You\'re on the right track!';
    return 'Keep learning! Don\'t give up!';
  }

  /// Get time feedback
  static String getTimeFeedback(int seconds, int questionCount) {
    final avgTimePerQuestion = seconds ~/ questionCount;
    if (avgTimePerQuestion < 30) return 'Very fast! ⚡';
    if (avgTimePerQuestion < 60) return 'Good pace! 👍';
    if (avgTimePerQuestion < 120) return 'Thoughtful approach! 🤔';
    return 'Take your time! ⏰';
  }

  /// Check if topic is eligible for daily test (min 5 attempts)
  static bool isTopicEligibleForDailyTest(int attemptCount) {
    return attemptCount >= 1;
  }

  /// Get recommended next action
  static String getRecommendedAction(double accuracy, int attempts) {
    if (accuracy == 0) return 'Try this topic!';
    if (accuracy < 50 && attempts < 3) return 'Revisit this topic';
    if (accuracy >= 80 && attempts >= 2) {
      return 'Master this! Try harder questions';
    }
    return 'Good! Try another topic';
  }

  /// Get streak emoji based on count
  static String getStreakEmoji(int count) {
    if (count >= 7) return '🔥🔥🔥';
    if (count >= 5) return '🔥🔥';
    if (count >= 3) return '🔥';
    return '✨';
  }

  /// Parse question options from pipe-separated string
  static List<String> parseOptions(String optionsString) {
    return optionsString.split('|||');
  }

  /// Join options with pipe separator
  static String joinOptions(List<String> options) {
    return options.join('|||');
  }

  /// Validate question model
  static bool isValidQuestion(dynamic question) {
    return question != null &&
        question.questionText != null &&
        question.questionText.isNotEmpty &&
        question.options != null &&
        question.options.length == 4 &&
        question.correctAnswer != null;
  }

  /// Get difficulty icon and color for quick display
  static Map<String, dynamic> getDifficultyStyle(String difficulty) {
    return {
      'color': getDifficultyColor(difficulty),
      'icon': getDifficultyIcon(difficulty),
      'label': capitalizeFirstLetter(difficulty),
    };
  }

  /// Calculate study streak
  static int calculateStudyStreak(List<DateTime> attemptDates) {
    if (attemptDates.isEmpty) return 0;

    attemptDates.sort();
    int streak = 1;
    for (int i = 1; i < attemptDates.length; i++) {
      final diff = attemptDates[i].difference(attemptDates[i - 1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        streak = 1;
      }
    }
    return streak;
  }

  /// Get motivational quote
  static String getMotivationalQuote() {
    final quotes = [
      'Success is not final, failure is not fatal. - Winston Churchill',
      'The only impossible journey is the one you never begin. - Tony Robbins',
      'Your limitation—it\'s only your imagination. - Unknown',
      'Push yourself, because no one else is going to do it for you.',
      'Sometimes we\'re tested not to show our weaknesses, but to discover our strengths.',
      'The key to success is to stay humble and keep learning.',
      'Don\'t watch the clock; do what it does. Keep going!',
      'You are capable of amazing things!',
    ];
    return quotes[DateTime.now().hashCode % quotes.length];
  }

  /// Get study recommendation based on performance
  static String getStudyRecommendation(
    double biologyAccuracy,
    double chemistryAccuracy,
    double physicsAccuracy,
  ) {
    final avgAccuracy =
        (biologyAccuracy + chemistryAccuracy + physicsAccuracy) / 3;

    if (avgAccuracy < 50) {
      return 'Focus on understanding fundamentals. Start with easier questions.';
    } else if (avgAccuracy < 70) {
      final weakSubject = [
        ('Biology', biologyAccuracy),
        ('Chemistry', chemistryAccuracy),
        ('Physics', physicsAccuracy),
      ]..sort((a, b) => a.$2.compareTo(b.$2));
      return 'Your ${weakSubject.first.$1} needs work. Practice more in this area!';
    } else if (avgAccuracy < 85) {
      return 'Great progress! Mix in harder questions to push your limits.';
    } else {
      return 'Outstanding! You\'re exam-ready. Practice full-length tests now!';
    }
  }
}

/// Extensions for common operations
extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    return AppUtils.capitalizeFirstLetter(this);
  }

  /// Parse options (assumes pipe-separated)
  List<String> parseAsOptions() {
    return AppUtils.parseOptions(this);
  }
}

extension DoubleExtension on double {
  /// Format as percentage
  String asPercentage() {
    return AppUtils.formatPercentage(this);
  }

  /// Get color for this percentage
  Color asAccuracyColor() {
    return AppUtils.getAccuracyColor(this);
  }

  /// Get accuracy feedback
  String getAccuracyFeedback() {
    return AppUtils.getAccuracyFeedback(this);
  }
}

extension IntExtension on int {
  /// Format seconds as HH:MM:SS
  String formatAsTime() {
    return AppUtils.formatTime(this);
  }

  /// Get streak emoji
  String getStreakEmoji() {
    return AppUtils.getStreakEmoji(this);
  }
}

extension DateTimeExtension on DateTime {
  /// Check if date is today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Get relative date string (Today, Yesterday, 2 days ago)
  String getRelativeDateString() {
    if (isToday()) return 'Today';
    if (isYesterday()) return 'Yesterday';

    final daysAgo = DateTime.now().difference(this).inDays;
    if (daysAgo < 7) return '$daysAgo days ago';
    if (daysAgo < 30) return '${(daysAgo / 7).ceil()} weeks ago';
    if (daysAgo < 365) return '${(daysAgo / 30).ceil()} months ago';

    return '${(daysAgo / 365).ceil()} years ago';
  }
}

/// Constants for the app
class AppConstants {
  // NEET related
  static const int neetTotalQuestions = 200;
  static const int neetDuration = 180; // minutes
  static const String neetYear = '2024';

  // Thresholds
  static const double excellentAccuracy = 80.0;
  static const double goodAccuracy = 60.0;
  static const double minPassingAccuracy = 40.0;

  // Time constants
  static const int secondsPerMinute = 60;
  static const int minutesPerHour = 60;

  // Subjects
  static const List<String> neetSubjects = ['Biology', 'Chemistry', 'Physics'];

  // Difficulties
  static const List<String> difficulties = ['Easy', 'Medium', 'Hard'];

  // UI
  static const double borderRadius = 12.0;
  static const double defaultPadding = 16.0;
}

/// Validators for input
class Validators {
  static bool isValidQuestion(Map<String, dynamic> question) {
    return question.containsKey('questionText') &&
        question.containsKey('options') &&
        question.containsKey('correctAnswer');
  }

  static bool isValidProgress(Map<String, dynamic> progress) {
    return progress.containsKey('topicId') &&
        progress.containsKey('questionsAttempted');
  }

  static String? validateQuestionText(String? value) {
    if (value == null || value.isEmpty) {
      return 'Question text cannot be empty';
    }
    if (value.length < 10) {
      return 'Question must be at least 10 characters';
    }
    return null;
  }
}
