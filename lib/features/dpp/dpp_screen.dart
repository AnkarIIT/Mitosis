import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_providers.dart';
import '../../core/providers/user_providers.dart';
import '../../core/models/subject_model.dart';
import '../../core/services/dpp_engine.dart';
import '../../core/utils/answer_normalizer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

class DppScreen extends ConsumerStatefulWidget {
  final String subject;

  const DppScreen({super.key, required this.subject});

  @override
  ConsumerState<DppScreen> createState() => _DppScreenState();
}

class _DppScreenState extends ConsumerState<DppScreen> {
  bool _isGenerating = false;
  DppConfig? _lastConfig;
  DppResult? _currentResult;

  Future<void> _startDpp(DppResult result, DppConfig config) async {
    final durationMinutes =
        result.set.durationMinutes ?? config.durationMinutes;
    if (!mounted) return;

    await context.push(
      '/dpp/attempt',
      extra: {
        'dppResult': result,
        'durationMinutes': durationMinutes,
        'config': config,
      },
    );
  }

  Future<void> _generateDpp(DppConfig config) async {
    setState(() {
      _isGenerating = true;
      _lastConfig = config;
    });
    try {
      final engine = ref.read(dppEngineProvider);
      final result = await engine.generate(config, forceRefresh: true);
      if (!mounted) return;

      if (result.questions.isNotEmpty) {
        setState(() => _currentResult = result);
        if (result.isShortage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only ${result.questions.length} of ${result.requestedQuestions} '
                'questions are available. This paper is shorter than requested.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        await _startDpp(result, config);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Not enough questions available for DPP. Please import more questions.',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate DPP: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _regenerateLast() async {
    if (_lastConfig != null) {
      await _generateDpp(_lastConfig!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    // `widget.subject` arrives in two shapes depending on the caller: a
    // Subject.id ('phys') from the home tab, and a display name ('Physics')
    // from chapter notes. Resolve to the Subject, then use its canonical NAME
    // everywhere below — the DPP engine matches questions on that string
    // exactly, so passing an id here silently produced an empty pool and a
    // "not enough questions" message for every paper.
    final subject = subjects.firstWhere(
      (s) =>
          s.id.toLowerCase() == widget.subject.toLowerCase() ||
          s.name.toLowerCase() == widget.subject.toLowerCase(),
      orElse: () => subjects.isNotEmpty
          ? subjects.first
          : Subject(id: '', name: 'Unknown', icon: '📝', chapters: const []),
    );
    final subjectName = subject.name;

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.name} - Daily Practice'),
        actions: [
          PopupMenuButton<DppConfig>(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Generate DPP',
            onSelected: (config) => _generateDpp(config),
            itemBuilder: (context) => [
              if (ref.read(learningRecommendationsProvider).isNotEmpty)
                PopupMenuItem(
                  value: DppConfig.fromRecommendation(
                    ref.read(learningRecommendationsProvider).first,
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.auto_awesome),
                    title: Text('Recommended Focus DPP'),
                    subtitle: Text('Based on your weakest topic'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem(
                value: DppConfig.single(subject: subjectName),
                child: const ListTile(
                  leading: Icon(Icons.assignment_rounded),
                  title: Text('Single Subject (20 Q, 20 min)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: DppConfig.mixed(
                  subjects: [subjectName],
                  weights: {subjectName: 100},
                  totalQuestions: 40,
                  durationMinutes: 40,
                ),
                child: const ListTile(
                  leading: Icon(Icons.assignment_rounded),
                  title: Text('Extended Single (40 Q, 40 min)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (subjectName == 'Physics' ||
                  subjectName == 'Chemistry' ||
                  subjectName == 'Biology')
                PopupMenuItem(
                  value: DppConfig.neetPattern(),
                  child: const ListTile(
                    leading: Icon(Icons.science_rounded),
                    title: Text('NEET Pattern (180 Q, 180 min)'),
                    subtitle: Text('Physics 45, Chem 45, Bio 90'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(context, subject),
    );
  }

  Widget _buildBody(BuildContext context, Subject subject) {
    if (_currentResult == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 64,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No DPP available yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Generate your daily practice paper for ${subject.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _regenerateLast,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_rounded),
                label: Text(_isGenerating ? 'Generating...' : 'Generate DPP'),
              ),
            ],
          ),
        ),
      );
    }

    final result = _currentResult!;
    final dppSet = result.set;
    final total = dppSet.totalQuestions;
    final correct = dppSet.correctCount;
    final incorrect = dppSet.incorrectCount;
    final unattempted = dppSet.unattemptedCount;
    final isCompleted = dppSet.isCompleted;
    final duration = dppSet.durationMinutes ?? 20;

    final subjectBreakdown = _calculateSubjectBreakdown();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DPP - ${dppSet.date}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Total', '$total', context),
                      _buildStat(
                        'Correct',
                        '$correct',
                        context,
                        color: AdaptiveColors.success(context),
                      ),
                      _buildStat(
                        'Incorrect',
                        '$incorrect',
                        context,
                        color: AdaptiveColors.error(context),
                      ),
                      _buildStat(
                        'Skipped',
                        '$unattempted',
                        context,
                        color: AdaptiveColors.warning(context),
                      ),
                    ],
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: total > 0 ? correct / total : 0,
                      backgroundColor: AdaptiveColors.surfaceContainerHighest(
                        context,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AdaptiveColors.success(context),
                      ),
                    ),
                  ],
                  if (subjectBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Subject Breakdown',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: subjectBreakdown.entries.map((entry) {
                        final subj = entry.key;
                        final stats = entry.value;
                        final subjTotal = stats['total']!;
                        final subjCorrect = stats['correct']!;
                        final subjAccuracy = subjTotal > 0
                            ? (subjCorrect / subjTotal * 100)
                            : 0.0;
                        final color = _subjectColor(subj);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle_rounded,
                                size: 10,
                                color: color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$subj: $subjCorrect/$subjTotal (${subjAccuracy.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Questions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: result.questions.length,
            itemBuilder: (context, index) {
              final q = result.questions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ExpansionTile(
                  title: Text(
                    'Q${index + 1}. ${q.questionText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${q.subject} • ${q.difficulty} • ${q.year ?? 'No year'}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.questionText,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          ...q.options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final option = entry.value;
                            final isCorrect = AnswerNormalizer.isCorrect(
                              option,
                              q,
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCorrect
                                          ? AdaptiveColors.success(context)
                                          : AdaptiveColors.surfaceContainerHighest(
                                              context,
                                            ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + idx),
                                        style: TextStyle(
                                          color: isCorrect
                                              ? Colors.white
                                              : AdaptiveColors.textPrimary(
                                                  context,
                                                ),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(option)),
                                ],
                              ),
                            );
                          }),
                          if (q.explanation != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            Text(
                              'Explanation:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(q.explanation!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isGenerating
                ? null
                : () async {
                    await _startDpp(result, _lastConfig!);
                  },
            icon: Icon(
              isCompleted ? Icons.play_arrow_rounded : Icons.timer_rounded,
            ),
            label: Text(
              isCompleted ? 'Retake DPP' : 'Start DPP ($duration min)',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Map<String, Map<String, int>> _calculateSubjectBreakdown() {
    // Per-question answers are owned by DppAttemptScreen and are not part of
    // DppResult. Do not render a fabricated 0-correct breakdown.
    return const {};
  }

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return SubjectColors.physics;
    if (s.contains('chem')) return SubjectColors.chemistry;
    return SubjectColors.biology;
  }

  Widget _buildStat(
    String label,
    String value,
    BuildContext context, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
