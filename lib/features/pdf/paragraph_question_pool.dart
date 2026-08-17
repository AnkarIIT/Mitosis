import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/question_model.dart';
import '../../core/services/paragraph_question_matcher.dart';
import '../../core/services/pdf_service.dart';
import '../../core/theme/app_colors.dart';

class ParagraphQuestionPoolSheet extends ConsumerStatefulWidget {
  final List<Question> chapterQuestions;
  final int pageNumber;
  final String assetPath;

  const ParagraphQuestionPoolSheet({
    super.key,
    required this.chapterQuestions,
    required this.pageNumber,
    required this.assetPath,
  });

  @override
  ConsumerState<ParagraphQuestionPoolSheet> createState() =>
      _ParagraphQuestionPoolSheetState();
}

class _ParagraphQuestionPoolSheetState
    extends ConsumerState<ParagraphQuestionPoolSheet> {
  List<PdfParagraph> _paragraphs = [];
  bool _loadingParagraphs = true;
  int? _selectedIndex;
  List<Question> _matched = [];

  @override
  void initState() {
    super.initState();
    _loadParagraphs();
  }

  Future<void> _loadParagraphs() async {
    try {
      final text = await PdfService.extractPageText(
        widget.assetPath,
        widget.pageNumber - 1,
      );
      if (!mounted) return;
      setState(() {
        _paragraphs = PdfService.segmentParagraphs(text, widget.pageNumber - 1);
        _loadingParagraphs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingParagraphs = false);
    }
  }

  List<Question> get _visibleQuestions {
    if (_selectedIndex == null) return widget.chapterQuestions;
    final matched = _matched.isEmpty ? null : _matched;
    return matched ?? widget.chapterQuestions;
  }

  void _onParagraphTap(int index) {
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null;
        _matched = [];
        return;
      }
      _selectedIndex = index;
      _matched = ParagraphQuestionMatcher.matchingQuestions(
        _paragraphs[index].text,
        widget.chapterQuestions,
      );
    });
  }

  void _startQuiz(List<Question> questions, {String? source}) {
    context.go('/quiz', extra: {
      'questions': questions,
      'topicName': source ?? 'NCERT Linked Questions',
      'topicId': 'ncert_reader',
      'subject': 'Mixed',
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleQuestions;
    final hasMatch = _selectedIndex != null && _matched.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.quiz, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Questions from Page ${widget.pageNumber}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Tap a paragraph to filter questions from that section',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                if (_loadingParagraphs)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_paragraphs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No extractable text on this page (may be image-based).',
                      style: TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'PARAGRAPHS ON THIS PAGE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSubtle,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ..._paragraphs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final paragraph = entry.value;
                  final selected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _onParagraphTap(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: selected
                                    ? AppColors.primary
                                    : AppColors.divider,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSubtle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  paragraph.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'QUESTIONS FROM THIS SECTION'
                        '${hasMatch ? ' (${visible.length} matched)' : ''}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSubtle,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (_selectedIndex != null)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedIndex = null;
                          _matched = [];
                        }),
                        child: const Text('Clear filter'),
                      ),
                  ],
                ),
                if (_selectedIndex != null && _matched.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No strong keyword match for this paragraph — showing '
                      'all chapter questions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No questions tagged to this chapter yet.',
                        style: TextStyle(color: AppColors.textSubtle),
                      ),
                    ),
                  )
                else
                  ...visible.map((q) => _buildQuestionTile(context, q)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTile(BuildContext context, Question q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _startQuiz([q], source: q.topic),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _subjectColor(q.subject).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        q.topic,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _subjectColor(q.subject),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textSubtle,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: AppColors.textDark,
                  ),
                ),
                if (q.ncertReference != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '📖 ${q.ncertReference}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return AppColors.physicsAccent;
      case 'chemistry':
        return AppColors.chemistryAccent;
      case 'biology':
        return AppColors.biologyAccent;
      default:
        return AppColors.primary;
    }
  }
}
