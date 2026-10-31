import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/question_model.dart';
import '../../core/services/exam_engine_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'nta_palette.dart';

/// NTA-style instructions screen shown before starting a fresh CBT mock test.
/// Mirrors the real NEET exam instructions flow: shows rules, timing, marking,
/// and proctoring warnings, then lets the candidate start the timed attempt.
///
/// The declaration checkbox is not decoration: NTA gates the paper behind it,
/// and gating here also prevents an accidental tap from starting a 200-minute
/// timer the candidate did not mean to begin.
class CbtInstructionsScreen extends StatefulWidget {
  const CbtInstructionsScreen({
    super.key,
    required this.config,
    required this.questionPool,
  });

  final ExamConfig config;
  final List<Question> questionPool;

  @override
  State<CbtInstructionsScreen> createState() => _CbtInstructionsScreenState();
}

class _CbtInstructionsScreenState extends State<CbtInstructionsScreen> {
  bool _declared = false;

  ExamConfig get config => widget.config;
  List<Question> get questionPool => widget.questionPool;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                totalQuestions,
                totalMinutes,
                hasSections,
                sectionCount,
              ),
              const SizedBox(height: 16),
              // Primary facts + start action first: time, questions, marking.
              _buildQuickStartCard(context),
              const SizedBox(height: 12),
              _buildCollapsibleSection(
                context,
                'General Instructions',
                _generalInstructions(totalQuestions, totalMinutes),
                initiallyExpanded: true,
              ),
              if (hasSections)
                _buildCollapsibleSection(
                  context,
                  'Section Structure',
                  _sectionInstructions(sectionCount, config),
                ),
              _buildCollapsibleSection(
                context,
                'Marking Scheme',
                _markingInstructions(),
                initiallyExpanded: true,
              ),
              _buildCollapsibleSection(
                context,
                'Navigation & Controls',
                _navigationInstructions(),
              ),
              _buildCollapsibleSection(
                context,
                'Proctoring & Integrity',
                _proctoringInstructions(),
              ),
              _buildCollapsibleSection(
                context,
                'Emergency & Technical',
                _emergencyInstructions(),
              ),
              const SizedBox(height: 12),
              _buildPaletteLegend(context),
              const SizedBox(height: 12),
              _buildImportantNote(context),
              const SizedBox(height: 12),
              _buildDeclaration(context),
              // Extra space so content never hides behind the sticky bar.
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_declared)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Accept the declaration above to start the test.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AdaptiveColors.textSecondary(context),
                  ),
                ),
              ),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _declared ? () => _startTest(context) : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text(
                  'Start Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartCard(BuildContext context) {
    final items = [
      (Icons.help_outline, '${config.totalPresented} questions'),
      (Icons.timer_outlined, '${config.totalDurationSeconds ~/ 60} min total'),
      (
        Icons.add_circle_outline,
        '+${config.marksPerCorrect} / ${config.marksPerWrong} marking',
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you start',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(item.$1, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Timer starts on tap and cannot be paused. Detailed rules below.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// The palette legend candidates are expected to know cold. The previous
  /// copy described the colours wrongly (marked = orange, current = blue),
  /// which is worse than no legend at all.
  Widget _buildPaletteLegend(BuildContext context) {
    const rows = [
      (NtaPaletteState.answered, 'Option selected and saved.'),
      (NtaPaletteState.notAnswered, 'Visited, but no option selected.'),
      (NtaPaletteState.notVisited, 'Not opened yet.'),
      (
        NtaPaletteState.marked,
        'Flagged for review. Counts as unanswered unless you also answer it.',
      ),
      (
        NtaPaletteState.answeredMarked,
        'Flagged and answered. Considered for evaluation.',
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Palette',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NtaPaletteColors.fill(row.$1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: row.$1 == NtaPaletteState.notVisited
                            ? AdaptiveColors.outline(context)
                            : Colors.transparent,
                      ),
                    ),
                    child: row.$1 == NtaPaletteState.answeredMarked
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${NtaPaletteColors.label(row.$1)} — ${row.$2}',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeclaration(BuildContext context) {
    return Material(
      color: AdaptiveColors.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _declared
              ? AdaptiveColors.primary(context)
              : AdaptiveColors.divider(context),
          width: _declared ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: _declared,
        onChanged: (value) => setState(() => _declared = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'I have read and understood the instructions. I declare that I am '
          'not in possession of, or indulging in, any unfair means.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        subtitle: const Text(
          'Required before the timer starts',
          style: TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildImportantNote(BuildContext context) {
    final warning = AdaptiveColors.warning(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: warning, size: 24),
              const SizedBox(width: 10),
              Text(
                'Important',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Once you start, the timer runs continuously. Ensure you have a stable internet connection, sufficient battery, and a quiet environment for the full duration.',
            style: TextStyle(
              fontSize: 14,
              color: AdaptiveColors.textPrimary(context),
              height: 1.4,
            ),
          ),
        ],
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
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: AdaptiveColors.primary(context),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NEET Mock Test',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AdaptiveColors.primary(context),
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
              _InfoChip(
                label: '$totalQuestions Questions',
                icon: Icons.help_outline,
              ),
              _InfoChip(
                label: '$totalMinutes Minutes',
                icon: Icons.timer_outlined,
              ),
              if (hasSections)
                _InfoChip(
                  label: '$sectionCount Sections',
                  icon: Icons.view_module_outlined,
                ),
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

  Widget _buildCollapsibleSection(
    BuildContext context,
    String title,
    List<String> points, {
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AdaptiveColors.primary(context),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: points.map((p) => _BulletPoint(text: p)).toList(),
      ),
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
    'Use "SAVE & NEXT" to store your answer and move to the next question.',
    'Use "SAVE & MARK FOR REVIEW" to store the answer and flag the question for '
        'a later look; you stay on the question.',
    'Use "MARK FOR REVIEW & NEXT" to flag a question without saving an answer '
        'and move forward.',
    'Use "CLEAR" to deselect the answer you have chosen.',
    '"<< BACK" and "NEXT >>" only move between questions; they do not save '
        'anything.',
    'The question palette shows five states: Answered (green), Not Answered '
        '(orange — opened but skipped), Not Visited (grey), Marked for Review '
        '(purple circle) and Answered & Marked (purple circle with a tick, '
        'which is counted for evaluation).',
    'You can jump to any question by tapping its number in the palette.',
    'On phones, open the palette from the grid icon in the candidate strip.',
  ];

  List<String> _proctoringInstructions() => [
    'This test runs in secure mode — screenshots and screen recording are blocked.',
    'Leaving the app or switching windows during the test is recorded as a violation.',
    'More than 3 violations may result in test termination.',
    'Do not minimize, switch apps, or use split-screen while the test is active.',
  ];

  List<String> _emergencyInstructions() {
    // Only full-length mocks write a checkpoint (cbt_test_screen's
    // `_checkpointable` gate is `config.isFullLengthMock`). Promising
    // auto-save/resume on a practice paper — which is what the test series
    // screen pushes here — was simply false.
    if (!config.isFullLengthMock) {
      return [
        'Practice papers are not saved. If the app closes, this attempt is lost.',
        'Finish and submit the paper before leaving the app to keep your result.',
        'In case of a critical issue, contact support immediately.',
      ];
    }
    return [
      'If the app crashes or you lose internet, reopen the app — your progress is auto-saved every 15 seconds.',
      'You can resume from the "Resume" button on the home screen or test series screen.',
      'In case of a critical issue, contact support immediately with your attempt ID.',
    ];
  }

  void _startTest(BuildContext context) {
    context.push(
      '/cbt',
      extra: {'config': config, 'questionPool': questionPool},
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.primary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
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
                color: AdaptiveColors.primary(context),
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
