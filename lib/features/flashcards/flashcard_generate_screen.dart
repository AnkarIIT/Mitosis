import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/drift_database.dart' show FlashcardsCompanion;
import '../../core/providers/providers.dart';
import '../../core/services/ncert_book_catalog.dart';
import '../../core/services/flashcard_generation_service.dart';
import '../../core/services/gemini_proxy_service.dart';
import '../../core/theme/app_colors.dart';

import 'package:go_router/go_router.dart';

class FlashcardGenerateScreen extends ConsumerStatefulWidget {
  const FlashcardGenerateScreen({super.key});

  @override
  ConsumerState<FlashcardGenerateScreen> createState() => _FlashcardGenerateScreenState();
}

class _FlashcardGenerateScreenState extends ConsumerState<FlashcardGenerateScreen> {
  String? _selectedSubject;
  String? _selectedClassLevel;
  NcertBookEntry? _selectedChapter;
  int _quantity = 20;
  bool _isGenerating = false;
  String? _status;
  int? _processed;
  int? _total;
  String? _lastError;
  List<GeneratedFlashcard> _generatedCards = const [];

  @override
  Widget build(BuildContext context) {
    final subjects = _subjects();
    final chapters = _chaptersForSelection();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate NCERT Flashcards'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Select Subject'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: subjects
                .map(
                  (s) => ButtonSegment(
                    value: s,
                    label: Text(s),
                    icon: Icon(_subjectIcon(s)),
                  ),
                )
                .toList(),
            selected: {?_selectedSubject},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedSubject = selection.first;
                _selectedChapter = null;
                _status = null;
                _generatedCards = const [];
              });
            },
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Class Level'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: ['Class 11', 'Class 12']
                .map(
                  (level) => ChoiceChip(
                    label: Text(level),
                    selected: _selectedClassLevel == level,
                    onSelected: (selected) {
                      setState(() {
                        _selectedClassLevel = selected ? level : null;
                        _selectedChapter = null;
                        _status = null;
                        _generatedCards = const [];
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Chapter'),
          const SizedBox(height: 8),
          DropdownButtonFormField<NcertBookEntry>(
            decoration: const InputDecoration(
              labelText: 'Choose chapter',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
            initialValue: _selectedChapter,
            items: chapters
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry,
                    child: Text('Ch ${entry.chapterNumber}: ${entry.chapterTitle}'),
                  ),
                )
                .toList(),
            onChanged: (entry) {
              setState(() {
                _selectedChapter = entry;
                _status = null;
                _generatedCards = const [];
              });
            },
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Quantity'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 10, label: Text('10')),
                    ButtonSegment(value: 20, label: Text('20')),
                    ButtonSegment(value: 50, label: Text('50')),
                  ],
                  selected: {_quantity},
                  onSelectionChanged: (selection) {
                    setState(() => _quantity = selection.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _canGenerate() && !_isGenerating
                  ? _startGeneration
                  : null,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_isGenerating ? 'Generating…' : 'GENERATE FLASHCARDS'),
            ),
          ),
          const SizedBox(height: 16),

          if (_status != null) ...[
            Card(
              color: _lastError != null
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.success.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _status!,
                      style: TextStyle(
                        color: _lastError != null ? AppColors.error : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_processed != null && _total != null && _total! > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _processed! / _total!,
                          minHeight: 6,
                          backgroundColor: AppColors.premiumChipBg,
                          valueColor: AlwaysStoppedAnimation(
                            _lastError != null ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_processed!} / ${_total!}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
                      ),
                    ],
                    if (_lastError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_lastError',
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_generatedCards.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_generatedCards.length} cards ready',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isGenerating ? null : _persistAndStudy,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('STUDY NOW'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._generatedCards.map((card) => _buildCardPreview(card)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
    );
  }

  Widget _buildCardPreview(GeneratedFlashcard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: const Icon(Icons.style_rounded, color: AppColors.physicsBlue),
        title: Text(
          card.front,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(card.ncertReference, style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(card.back, style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _subjects() {
    if (_selectedClassLevel == null) return const [];
    final subjects = NcertBookCatalog.allEntries
        .where((e) => e.classLevel == _selectedClassLevel)
        .map((e) => e.subject)
        .toSet()
        .toList();
    subjects.sort();
    return subjects;
  }

  List<NcertBookEntry> _chaptersForSelection() {
    if (_selectedSubject == null || _selectedClassLevel == null) return const [];
    return NcertBookCatalog.allEntries
        .where(
          (e) =>
              e.subject == _selectedSubject &&
              e.classLevel == _selectedClassLevel,
        )
        .toList();
  }

  bool _canGenerate() {
    return _selectedSubject != null &&
        _selectedClassLevel != null &&
        _selectedChapter != null &&
        !_isGenerating;
  }

  Future<void> _persistAndStudy() async {
    if (_generatedCards.isEmpty) return;

    final db = ref.read(databaseProvider);
    const uuid = Uuid();
    final now = DateTime.now();
    final chapterId = _selectedChapter?.chapterTitle ?? '';

    final companions = _generatedCards.map((card) {
      return FlashcardsCompanion.insert(
        id: uuid.v4(),
        front: card.front,
        back: card.back,
        subject: _selectedSubject ?? '',
        ncertReference: Value(card.ncertReference),
        sourcePage: Value(card.sourcePage),
        difficulty: Value(card.difficulty),
        chapterId: Value(chapterId),
        isGenerated: const Value(true),
        dueAt: now,
      );
    }).toList();

    await db.insertFlashcardsBatch(companions);
    ref.invalidate(flashcardsFromDbProvider);
    ref.invalidate(dueFlashcardsProvider);

    if (!mounted) return;
    context.push('/flashcards/study');
  }

  Future<void> _startGeneration() async {
    if (_selectedChapter == null) return;

    setState(() {
      _isGenerating = true;
      _status = 'Reading NCERT chapter…';
      _processed = 0;
      _total = null;
      _lastError = null;
      _generatedCards = const [];
    });

    try {
      final service = FlashcardGenerationService(
        proxy: GeminiProxyService(),
        batchSize: 5,
        delayBetweenBatchesMs: 1200,
      );

      final cards = await service.generate(
        subject: _selectedSubject!,
        chapterTitle: _selectedChapter!.chapterTitle,
        chapterNumber: _selectedChapter!.chapterNumber,
        classLevel: _selectedClassLevel!,
        count: _quantity,
        assetPathOverride: _selectedChapter!.assetPath,
      );

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _generatedCards = cards;
        _status = cards.isEmpty
            ? 'No flashcards generated. Try again or pick another chapter.'
            : 'Generated ${cards.length} flashcards';
        _lastError = cards.isEmpty ? 'empty_generation' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _status = 'Generation failed';
        _lastError = e.toString();
      });
    }
  }

  IconData _subjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
        return Icons.eco_rounded;
      case 'physics':
        return Icons.bolt_rounded;
      case 'chemistry':
        return Icons.science_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}
