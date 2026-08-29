import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_providers.dart';
import '../../core/models/subject_model.dart';
import '../../core/services/dpp_engine.dart';

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

      if (result != null && result.questions.isNotEmpty) {
        setState(() => _currentResult = result);
        await _startDpp(result, config);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Not enough questions available for DPP. Please import more questions.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate DPP: $e'),
          backgroundColor: Colors.red,
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
    final subject = subjects.firstWhere(
      (s) => s.id == widget.subject,
      orElse: () => subjects.isNotEmpty
          ? subjects.first
          : Subject(id: '', name: 'Unknown', icon: '📝', chapters: const []),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.name} - Daily Practice'),
        actions: [
          PopupMenuButton<DppConfig>(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Generate DPP',
            onSelected: (config) => _generateDpp(config),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: DppConfig.single(subject: widget.subject),
                child: const ListTile(
                  leading: Icon(Icons.assignment_rounded),
                  title: Text('Single Subject (20 Q, 20 min)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: DppConfig.mixed(
                  subjects: [widget.subject],
                  weights: {widget.subject: 100},
                  totalQuestions: 40,
                  durationMinutes: 40,
                ),
                child: const ListTile(
                  leading: Icon(Icons.assignment_rounded),
                  title: Text('Extended Single (40 Q, 40 min)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (widget.subject == 'Physics' ||
                  widget.subject == 'Chemistry' ||
                  widget.subject == 'Biology')
                PopupMenuItem(
                  value: DppConfig.mixed(
                    subjects: const ['Physics', 'Chemistry', 'Biology'],
                    weights: const {
                      'Physics': 45,
                      'Chemistry': 45,
                      'Biology': 90,
                    },
                    totalQuestions: 180,
                    durationMinutes: 180,
                  ),
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

    final subjectBreakdown = _calculateSubjectBreakdown(result);

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
                        color: Colors.green,
                      ),
                      _buildStat(
                        'Incorrect',
                        '$incorrect',
                        context,
                        color: Colors.red,
                      ),
                      _buildStat(
                        'Skipped',
                        '$unattempted',
                        context,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: total > 0 ? correct / total : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
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
                            final isCorrect = idx.toString() == q.correctAnswer;
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
                                          ? Colors.green
                                          : Colors.grey[300],
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + idx),
                                        style: TextStyle(
                                          color: isCorrect
                                              ? Colors.white
                                              : Colors.black87,
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

  Map<String, Map<String, int>> _calculateSubjectBreakdown(DppResult result) {
    final breakdown = <String, Map<String, int>>{};
    for (final q in result.questions) {
      breakdown.putIfAbsent(
        q.subject,
        () => {'total': 0, 'correct': 0, 'incorrect': 0, 'unattempted': 0},
      );
      breakdown[q.subject]!['total'] = breakdown[q.subject]!['total']! + 1;
    }
    return breakdown;
  }

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return Colors.blue;
    if (s.contains('chem')) return Colors.orange;
    return Colors.green;
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
