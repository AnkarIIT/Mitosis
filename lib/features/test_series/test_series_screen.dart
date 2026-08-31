import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/question_model.dart';
import '../../core/services/exam_engine_service.dart';
import '../../core/services/exam_checkpoint_service.dart';
import 'package:go_router/go_router.dart';

class TestSeriesScreen extends ConsumerStatefulWidget {
  const TestSeriesScreen({super.key});

  @override
  ConsumerState<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends ConsumerState<TestSeriesScreen> {
  @override
  Widget build(BuildContext context) {
    final allQuestionsAsync = ref.watch(allQuestionsProvider);
    final subjects = ref.watch(subjectsProvider);
    final allQuestions = allQuestionsAsync.valueOrNull ?? [];
    final resumeCheckpoint = ref.watch(activeCbtCheckpointProvider).valueOrNull;

    if (allQuestionsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (allQuestionsAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Series'), elevation: 0),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Unable to load test questions right now.'),
          ),
        ),
      );
    }

    // Subtitle is derived from ExamConfig so it never drifts from the actual
    // pattern. (Exact NEET numbers live in ExamConfig — verify vs NTA bulletin.)
    final neetCfg = ExamConfig.neet();
    final neetSubtitle =
        '${neetCfg.totalQuestionSlots} Questions • '
        '${neetCfg.totalDurationSeconds ~/ 60} Minutes • '
        '+${neetCfg.marksPerCorrect}/${neetCfg.marksPerWrong} • '
        '${neetCfg.sectionLock ? 'Section lock' : 'Free navigation'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Test Series'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resumeCheckpoint != null) ...[
              _buildResumeCard(context, resumeCheckpoint, allQuestions),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle(context, 'Full Mock Tests'),
            _buildTestCard(
              context,
              title: 'NEET Full Mock Test',
              subtitle: neetSubtitle,
              icon: Icons.assignment_turned_in,
              color: AppColors.primary,
              onTap: () => _startNeetMock(context, allQuestions),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Custom Test Generator'),
            _buildTestCard(
              context,
              title: 'CBT Practice Mode',
              subtitle: 'Timed computer-based practice • No section lock',
              icon: Icons.desktop_windows,
              color: Colors.teal,
              onTap: () => _showCbtPracticeDialog(context, allQuestions),
            ),
            const SizedBox(height: 12),
            _buildTestCard(
              context,
              title: 'Dynamic Test Builder',
              subtitle: 'Select subjects, difficulty, and question types',
              icon: Icons.tune,
              color: Colors.purple,
              onTap: () => _showCustomTestDialog(context, allQuestions),
            ),
            const SizedBox(height: 12),
            _buildTestCard(
              context,
              title: 'Smart Question Paper Generator',
              subtitle:
                  '5 / 10 / 30 / 180 questions • Balanced 40-40-20 difficulty • Clean PYQs (no year marks)',
              icon: Icons.library_add,
              color: AppColors.primary,
              onTap: () {
                context.push('/test-series/paper');
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Subject-wise Tests'),
            ...subjects.map((subject) {
              final subjectQuestions = allQuestions
                  .where((q) => q.subject == subject.name)
                  .toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTestCard(
                  context,
                  title: '${subject.name} Subject Test',
                  subtitle:
                      '${subjectQuestions.length} Questions • ${subjectQuestions.length} Minutes',
                  icon: Icons.science,
                  color: _getSubjectColor(subject.name),
                  onTap: () => _startTest(
                    context,
                    ref,
                    subjectQuestions,
                    '${subject.name} Test',
                    'subject',
                    subjectName: subject.name,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AdaptiveColors.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomTestDialog(
    BuildContext context,
    List<Question> allQuestions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CustomTestBuilderSheet(allQuestions: allQuestions),
    );
  }

  void _startTest(
    BuildContext context,
    WidgetRef ref,
    List<Question> questions,
    String title,
    String type, {
    String? subjectName,
  }) {
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available for this test.')),
      );
      return;
    }

    if (type == 'subject' && subjectName != null) {
      context.push(
        '/quiz',
        extra: {
          'questions': questions,
          'topicName': title,
          'topicId': 'subject_${Uri.encodeComponent(subjectName)}',
          'subject': subjectName,
          'testType': 'subject',
        },
      );
    } else {
      context.push(
        '/quiz',
        extra: {
          'questions': questions,
          'topicName': title,
          'topicId': type == 'mock'
              ? 'mock_test'
              : (subjectName ?? 'custom_test'),
          'subject': subjectName ?? 'Mixed',
        },
      );
    }
  }

  void _startNeetMock(BuildContext context, List<Question> allQuestions) {
    final pool = ExamEngineService.validatePool(allQuestions);
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Not enough valid questions to start a mock test. '
            'Import or sync more questions and try again.',
          ),
        ),
      );
      return;
    }

    context.push(
      '/cbt',
      extra: {'config': ExamConfig.neet(), 'questionPool': pool},
    );
  }

  Widget _buildResumeCard(
    BuildContext context,
    ExamCheckpoint cp,
    List<Question> allQuestions,
  ) {
    final answered = cp.answersByIndex.values
        .where((v) => v != null && v.isNotEmpty)
        .length;
    final total = cp.sectionQuestionIds.fold<int>(
      0,
      (s, ids) => s + ids.length,
    );
    final remaining = cp.remainingSecondsAt(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume Mock Test',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$answered/$total answered • ${_fmtRemaining(remaining)} left',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _resumeMock(context, cp, allQuestions),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _discardCheckpoint,
                child: const Text('Discard'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resumeMock(
    BuildContext context,
    ExamCheckpoint cp,
    List<Question> allQuestions,
  ) {
    // Pass the FULL pool so the saved question IDs resolve on restore.
    context.push(
      '/cbt',
      extra: {
        'config': cp.config,
        'questionPool': allQuestions,
        'resumeCheckpoint': cp,
      },
    );
  }

  Future<void> _discardCheckpoint() async {
    await ref.read(examCheckpointServiceProvider).clear();
    ref.invalidate(activeCbtCheckpointProvider);
  }

  String _fmtRemaining(int seconds) {
    if (seconds <= 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    final s = seconds % 60;
    return m > 0 ? '${m}m' : '${s}s';
  }

  void _showCbtPracticeDialog(
    BuildContext context,
    List<Question> allQuestions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CbtPracticeSheet(allQuestions: allQuestions),
    );
  }

  Color _getSubjectColor(String name) {
    switch (name.toLowerCase()) {
      case 'biology':
        return Colors.green;
      case 'chemistry':
        return Colors.blue;
      case 'physics':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}

class _CustomTestBuilderSheet extends ConsumerStatefulWidget {
  final List<Question> allQuestions;
  const _CustomTestBuilderSheet({required this.allQuestions});

  @override
  ConsumerState<_CustomTestBuilderSheet> createState() =>
      _CustomTestBuilderSheetState();
}

class _CustomTestBuilderSheetState
    extends ConsumerState<_CustomTestBuilderSheet> {
  final Set<String> _selectedSubjects = {'Biology', 'Chemistry', 'Physics'};
  final Set<String> _selectedDifficulties = {'Easy', 'Medium', 'Hard'};
  final Set<String> _selectedTypes = {'MCQ', 'AR', 'Statement'};
  int _questionCount = 45;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize Your Test',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection('Subjects', [
                    'Biology',
                    'Chemistry',
                    'Physics',
                  ], _selectedSubjects),
                  const SizedBox(height: 20),
                  _buildFilterSection('Difficulty', [
                    'Easy',
                    'Medium',
                    'Hard',
                  ], _selectedDifficulties),
                  const SizedBox(height: 20),
                  _buildFilterSection('Question Types', [
                    'MCQ',
                    'AR',
                    'Statement',
                  ], _selectedTypes),
                  const SizedBox(height: 20),
                  Text(
                    'Number of Questions: $_questionCount',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _questionCount.toDouble(),
                    min: 10,
                    max: 180,
                    divisions: 17,
                    label: _questionCount.toString(),
                    onChanged: (val) =>
                        setState(() => _questionCount = val.toInt()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _generateAndStart,
              child: const Text('GENERATE TEST'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    Set<String> selection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = selection.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    selection.add(opt);
                  } else if (selection.length > 1) {
                    selection.remove(opt);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _generateAndStart() {
    final filtered = widget.allQuestions.where((q) {
      return _selectedSubjects.contains(q.subject) &&
          _selectedDifficulties.contains(q.difficulty) &&
          _selectedTypes.contains(q.type);
    }).toList();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions found matching your criteria.'),
        ),
      );
      return;
    }

    filtered.shuffle();
    final questions = filtered.take(_questionCount).toList();

    context.pop();
    context.push(
      '/quiz',
      extra: {
        'questions': questions,
        'topicName': 'Custom Practice',
        'topicId': 'custom_builder',
        'subject': 'Mixed',
      },
    );
  }
}

class _CbtPracticeSheet extends ConsumerStatefulWidget {
  final List<Question> allQuestions;
  const _CbtPracticeSheet({required this.allQuestions});

  @override
  ConsumerState<_CbtPracticeSheet> createState() => _CbtPracticeSheetState();
}

class _CbtPracticeSheetState extends ConsumerState<_CbtPracticeSheet> {
  int _questionCount = 50;
  int _durationMinutes = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CBT Practice Mode',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'A timed computer-based test with free navigation, +4/-1 '
            'marking, and instant analytics.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: 20),
          Text(
            'Number of Questions: $_questionCount',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _questionCount.toDouble(),
            min: 10,
            max: 100,
            divisions: 9,
            label: _questionCount.toString(),
            onChanged: (val) => setState(() => _questionCount = val.toInt()),
          ),
          const SizedBox(height: 8),
          Text(
            'Duration: $_durationMinutes Minutes',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _durationMinutes.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            label: '$_durationMinutes min',
            onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _start,
              child: const Text('START CBT PRACTICE'),
            ),
          ),
        ],
      ),
    );
  }

  void _start() {
    final pool = ExamEngineService.validatePool(widget.allQuestions);
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough valid questions for a practice test.'),
        ),
      );
      return;
    }
    final config = ExamConfig.practice(
      questionCount: _questionCount,
      durationMinutes: _durationMinutes,
    );
    context.pop();
    context.push('/cbt', extra: {'config': config, 'questionPool': pool});
  }
}
