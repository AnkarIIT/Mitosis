import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_providers.dart';
import '../../core/models/subject_model.dart';
import '../../core/services/dpp_engine.dart';
import '../../core/services/exam_engine_service.dart';


class DppScreen extends ConsumerStatefulWidget {
  final String subject;

  const DppScreen({super.key, required this.subject});

  @override
  ConsumerState<DppScreen> createState() => _DppScreenState();
}

class _DppScreenState extends ConsumerState<DppScreen> {
  bool _isGenerating = false;

  Future<void> _startDpp(DppResult result) async {
    final config = ExamConfig.neet();
    final questionPool = result.questions;

    if (!mounted) return;

    await context.push('/cbt', extra: {
      'config': config,
      'questionPool': questionPool,
    });
  }

  Future<void> _generateDpp() async {
    setState(() => _isGenerating = true);
    try {
      final result = await ref.read(todayDppProvider(widget.subject).future);
      if (!mounted) return;

      if (result != null && result.questions.isNotEmpty) {
        await _startDpp(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough questions available for DPP. Please import more questions.'),
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

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final subject = subjects.firstWhere(
      (s) => s.id == widget.subject,
      orElse: () => subjects.isNotEmpty
          ? subjects.first
          : Subject(id: '', name: 'Unknown', icon: '📝', chapters: const []),
    );
    final dppAsync = ref.watch(todayDppProvider(widget.subject));

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.name} - Daily Practice'),
      ),
      body: dppAsync.when(
        data: (result) {
          if (result == null || result.questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 64, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
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
                      onPressed: _isGenerating ? null : _generateDpp,
                      icon: _isGenerating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_fix_high_rounded),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate DPP'),
                    ),
                  ],
                ),
              ),
            );
          }

          final dppSet = result.set;
          final total = dppSet.totalQuestions;
          final correct = dppSet.correctCount;
          final incorrect = dppSet.incorrectCount;
          final unattempted = dppSet.unattemptedCount;
          final isCompleted = dppSet.isCompleted;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: Theme.of(context).primaryColor),
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
                            _buildStat('Correct', '$correct', context, color: Colors.green),
                            _buildStat('Incorrect', '$incorrect', context, color: Colors.red),
                            _buildStat('Unattempted', '$unattempted', context, color: Colors.orange),
                          ],
                        ),
                        if (isCompleted) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: total > 0 ? correct / total : 0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Questions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                        subtitle: Text('${q.difficulty} • ${q.year ?? "No year"}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(q.questionText, style: const TextStyle(fontSize: 16)),
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
                                            color: isCorrect ? Colors.green : Colors.grey[300],
                                          ),
                                          child: Center(
                                            child: Text(
                                              String.fromCharCode(65 + idx),
                                              style: TextStyle(
                                                color: isCorrect ? Colors.white : Colors.black87,
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
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
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
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load DPP', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ref.invalidate(todayDppProvider(widget.subject)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, BuildContext context, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }
}
