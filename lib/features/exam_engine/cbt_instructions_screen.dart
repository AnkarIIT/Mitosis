import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/question_model.dart';
import '../../core/services/exam_engine_service.dart';
import '../../core/theme/app_colors.dart';

/// NTA-style instructions screen shown before starting a fresh CBT mock test.
/// Mirrors the real NEET exam instructions flow: shows rules, timing, marking,
/// and proctoring warnings, then lets the candidate start the timed attempt.
class CbtInstructionsScreen extends StatelessWidget {
  const CbtInstructionsScreen({
    super.key,
    required this.config,
    required this.questionPool,
  });

  final ExamConfig config;
  final List<Question> questionPool;

  @override
  Widget build(BuildContext context) {
    final isFullLength = config.isFullLengthMock;
    final totalQuestions = config.totalPresented;
    final totalMinutes = config.totalDurationSeconds ~/ 60;
    final hasSections = config.sections.isNotEmpty;
    final sectionCount = config.sections.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Instructions'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, totalQuestions, totalMinutes, hasSections, sectionCount),
              const SizedBox(height: 24),
              _buildSection('General Instructions', _generalInstructions(totalQuestions, totalMinutes)),
              const SizedBox(height: 16),
              if (hasSections) ...[
                _buildSection('Section Structure', _sectionInstructions(sectionCount, config)),
                const SizedBox(height: 16),
              ],
              _buildSection('Marking Scheme', _markingInstructions()),
              const SizedBox(height: 16),
              _buildSection('Navigation & Controls', _navigationInstructions()),
              const SizedBox(height: 16),
              _buildSection('Proctoring & Integrity', _proctoringInstructions()),
              const SizedBox(height: 16),
              _buildSection('Emergency & Technical', _emergencyInstructions()),
              const SizedBox(height: 32),
              _buildAcknowledgeAndStart(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int totalQuestions,
    int totalMinutes,
    bool hasSections,
    int sectionCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NEET Mock Test',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(label: '$totalQuestions Questions', icon: Icons.help_outline),
              _InfoChip(label: '$totalMinutes Minutes', icon: Icons.timer_outlined),
              if (hasSections)
                _InfoChip(label: '$sectionCount Sections', icon: Icons.view_module_outlined),
              _InfoChip(
                label: config.isFullLengthMock ? 'Full Length' : 'Practice',
                icon: Icons.flag_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...points.map((p) => _BulletPoint(text: p)),
      ],
    );
  }

  List<String> _generalInstructions(int totalQuestions, int totalMinutes) => [
        'This test contains $totalQuestions questions to be completed in $totalMinutes minutes.',
        'The timer starts immediately when you tap "Start Test" and cannot be paused.',
        'All questions are multiple-choice with a single correct answer.',
        'Read each question carefully before selecting your answer.',
      ];

  List<String> _sectionInstructions(int sectionCount, ExamConfig config) => [
        'The test is divided into $sectionCount sections as per the NTA NEET pattern.',
        'Each section has a fixed time limit. You cannot return to a section after its time expires.',
        'A warning will appear 5 minutes before each section ends.',
        'Section-wise submission is mandatory — you must submit the current section to proceed.',
      ];

  List<String> _markingInstructions() => [
        'Correct answer: +4 marks',
        'Incorrect answer: −1 mark (negative marking)',
        'Unattempted question: 0 marks',
        'Marking multiple options for the same question is treated as incorrect (−1).',
      ];

  List<String> _navigationInstructions() => [
        'Use "Save & Next" to save your answer and move to the next question.',
        'Use "Mark & Next" to flag a question for review and move forward.',
        'Use "Clear" to remove your selected answer for the current question.',
        'The question palette on the right shows: Answered (green), Marked (orange), Not Answered (gray), Current (blue).',
        'You can jump to any question by tapping its number in the palette.',
        'Questions marked for review appear with an orange dot in the palette.',
      ];

  List<String> _proctoringInstructions() => [
        'This test runs in secure mode — screenshots and screen recording are blocked.',
        'Leaving the app or switching windows during the test is recorded as a violation.',
        'More than 3 violations may result in test termination.',
        'Do not minimize, switch apps, or use split-screen while the test is active.',
      ];

  List<String> _emergencyInstructions() => [
        'If the app crashes or you lose internet, reopen the app — your progress is auto-saved every 15 seconds.',
        'You can resume from the "Resume" button on the home screen or test series screen.',
        'In case of a critical issue, contact support immediately with your attempt ID.',
      ];

  Widget _buildAcknowledgeAndStart(BuildContext context) {
    return Column(
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Important',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Once you start, the timer runs continuously. Ensure you have a stable internet connection, sufficient battery, and a quiet environment for the full duration.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.warning.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _startTest(context),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              'Start Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  void _startTest(BuildContext context) {
    context.push(
      '/cbt',
      extra: {
        'config': config,
        'questionPool': questionPool,
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}