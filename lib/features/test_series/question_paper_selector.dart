import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/question_paper_model.dart';
import '../../core/services/question_paper_generator.dart';
import '../../core/providers/providers.dart';
import 'package:go_router/go_router.dart';

class QuestionPaperSelector extends ConsumerStatefulWidget {
  const QuestionPaperSelector({super.key});

  @override
  ConsumerState<QuestionPaperSelector> createState() =>
      _QuestionPaperSelectorState();
}

class _QuestionPaperSelectorState extends ConsumerState<QuestionPaperSelector> {
  final subjects = ['Biology', 'Chemistry', 'Physics'];
  final selectedSubjects = <String>{};
  PaperStandard _selectedStandard = PaperStandard.standard;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Question Paper'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Subject Selection
            _buildSection(
              title: 'Step 1: Select Subjects',
              children: [
                Text(
                  'Choose subjects you want in your paper:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: subjects
                      .map((subject) => FilterChip(
                            label: Text(subject),
                            selected: selectedSubjects.contains(subject),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedSubjects.add(subject);
                                } else {
                                  selectedSubjects.remove(subject);
                                }
                              });
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceWarm,
                            labelStyle: TextStyle(
                              color: selectedSubjects.contains(subject)
                                  ? Colors.white
                                  : AppColors.textSubtle,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 2: Paper Size Selection
            _buildSection(
              title: 'Step 2: Select Paper Size',
              children: [
                Text(
                  'How many questions do you want?',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Column(
                  children: PaperStandard.values
                      .map((standard) => _buildPaperStandardCard(standard))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary
            if (selectedSubjects.isNotEmpty)
              _buildSection(
                title: 'Summary',
                children: [
                  _buildSummaryRow('Subjects', selectedSubjects.join(', ')),
                  _buildSummaryRow(
                    'Paper Type',
                    PaperConfig.getConfig(_selectedStandard).displayName,
                  ),
                  _buildSummaryRow(
                    'Questions',
                    '${PaperConfig.getConfig(_selectedStandard).questionCount}',
                  ),
                  _buildSummaryRow(
                    'Duration',
                    '${PaperConfig.getConfig(_selectedStandard).timeLimit?.inMinutes ?? 0} mins',
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedSubjects.isEmpty || _isGenerating
                    ? null
                    : _generatePaper,
                icon: const Icon(Icons.flash_on),
                label: Text(_isGenerating
                    ? 'Generating...'
                    : 'Generate Question Paper'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildPaperStandardCard(PaperStandard standard) {
    final config = PaperConfig.getConfig(standard);
    final isSelected = _selectedStandard == standard;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedStandard = standard),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.textSubtle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.displayName,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.description,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSubtle,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePaper() async {
    setState(() => _isGenerating = true);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Creating your question paper...'),
              const SizedBox(height: 8),
              Text(
                'Selecting random questions...',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      );

      final generator = QuestionPaperGenerator();
      final pool = ref.read(allQuestionsProvider).valueOrNull;
      final paper = await generator.generatePaper(
        selectedSubjects: selectedSubjects.toList(),
        standard: _selectedStandard,
        removeYearMarking: true, // Don't show which year questions are from
        // Use the full DB question bank (includes AI-generated PDF questions),
        // falling back to the built-in sample set when the DB is not ready.
        questionPool: (pool == null || pool.isEmpty) ? null : pool,
      );

      if (!mounted) return;
      context.pop(); // Close loading dialog

      // Show paper summary
      _showPaperSummary(paper);
    } catch (e) {
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showPaperSummary(QuestionPaper paper) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paper Ready!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paper.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total Questions', '${paper.totalQuestions}'),
            _buildStatRow('Time Limit', '${paper.timeLimit?.inMinutes ?? 0} mins'),
            _buildStatRow(
              'Subjects',
              paper.subjects.join(', '),
            ),
            const SizedBox(height: 8),
            Text(
              'Subject Distribution:',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            ...paper.subjectDistribution.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '  • ${e.key}: ${e.value} questions',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Difficulty Mix:',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            ...paper.difficultyDistribution.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '  • ${e.key}: ${e.value} questions',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _startQuiz(paper);
            },
            child: const Text('Start Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  void _startQuiz(QuestionPaper paper) {
    final sub = paper.subjects.length == 1 ? paper.subjects.first : 'Mixed';
    context.push('/quiz', extra: {
      'questions': paper.questions,
      'topicName': paper.title,
      'topicId': 'mock_test',
      'subject': sub,
    });
  }
}

