import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/models/question_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/ncert_book_catalog.dart';
import '../../core/services/pdf_service.dart';
import '../../core/theme/app_colors.dart';
import 'paragraph_question_pool.dart';

class NcertPdfScreen extends ConsumerStatefulWidget {
  final String entryId;

  const NcertPdfScreen({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<NcertPdfScreen> createState() => _NcertPdfScreenState();
}

class _NcertPdfScreenState extends ConsumerState<NcertPdfScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final Map<String, int> _chapterPageCache = {};
  late final List<NcertBookEntry> _bookChapters;

  bool _loaded = false;
  int _currentPage = 1;
  String? _scanningChapter;

  NcertBookEntry get _entry {
    final entry = NcertBookCatalog.entryByChapterKey(widget.entryId);
    if (entry != null) return entry;
    // Fallback: find by exact asset path across the full catalog.
    final asset = widget.entryId;
    return NcertBookCatalog.allEntries.firstWhere(
      (e) => e.assetPath == asset,
      orElse: () => NcertBookCatalog.allEntries.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _bookChapters = NcertBookCatalog.chaptersOfBook(_entry);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Question> _questionsForChapter(List<Question> all) {
    // Find questions matching this chapter's topics
    return all.where((q) => q.chapter == _entry.chapterTitle).toList();
  }

  void _openQuestionPool(List<Question> questions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParagraphQuestionPoolSheet(
        chapterQuestions: questions,
        pageNumber: _currentPage,
        assetPath: _entry.assetPath,
      ),
    );
  }

  Future<void> _jumpToChapterStart() async {
    if (!_loaded) return;
    final cached = _chapterPageCache[_entry.assetPath];
    if (cached != null) {
      _controller.jumpToPage(cached + 1);
      return;
    }
    setState(() => _scanningChapter = _entry.chapterTitle);
    final page = await PdfService.findChapterStartPage(
      _entry.assetPath,
      _entry.chapterTitle,
    );
    if (!mounted) return;
    setState(() => _scanningChapter = null);
    if (page != null) {
      _chapterPageCache[_entry.assetPath] = page;
      _controller.jumpToPage(page + 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find the chapter start automatically.'),
        ),
      );
    }
  }

  void _openChapter(NcertBookEntry entry) {
    if (entry.assetPath == _entry.assetPath) {
      context.pop();
      _jumpToChapterStart();
      return;
    }
    context.go('/pdf?entryId=${Uri.encodeComponent(entry.chapterTitle.replaceAll(" ", "_").toLowerCase())}');
  }

  @override
  Widget build(BuildContext context) {
    final allQuestions = ref.watch(allQuestionsProvider).valueOrNull ?? [];
    final chapterQuestions = _questionsForChapter(allQuestions);

    return Scaffold(
      backgroundColor: AppColors.surfaceWarm,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _entry.chapterTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '${_entry.subject} • ${_entry.classLevel} • '
              'Chapter ${_entry.chapterNumber}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            tooltip: 'Chapters',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  _entry.bookName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _bookChapters.length,
                  itemBuilder: (context, index) {
                    final entry = _bookChapters[index];
                    final isCurrent =
                        entry.assetPath == _entry.assetPath;
                    final isActiveChapter =
                        isCurrent && _loaded;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isCurrent
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.divider,
                        child: Text(
                          '${entry.chapterNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textSubtle,
                          ),
                        ),
                      ),
                      title: Text(
                        entry.chapterTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textDark,
                        ),
                      ),
                      trailing: isActiveChapter
                          ? Text(
                              _scanningChapter != null ? 'Scanning…' : 'Page $_currentPage',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSubtle,
                              ),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.textSubtle,
                            ),
                      onTap: () => _openChapter(entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SfPdfViewer.asset(
              _entry.assetPath,
              controller: _controller,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              canShowPaginationDialog: true,
              onDocumentLoaded: (details) {
                setState(() {
                  _loaded = true;
                  _currentPage = 1;
                });
              },
              onPageChanged: (details) {
                setState(() => _currentPage = details.newPageNumber);
              },
            ),
          ),
          if (chapterQuestions.isNotEmpty)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NCERT-linked questions',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Page $_currentPage • ${chapterQuestions.length} available',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openQuestionPool(chapterQuestions),
                      icon: const Icon(Icons.quiz, size: 18),
                      label: const Text('View'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

