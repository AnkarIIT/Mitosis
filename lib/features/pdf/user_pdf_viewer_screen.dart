import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/providers/providers.dart';
import '../../core/services/user_pdf_index.dart';

/// Viewer for user-uploaded PDFs with citation jump support.
class UserPdfViewerScreen extends ConsumerStatefulWidget {
  final String pdfId;
  final int? initialPage;

  const UserPdfViewerScreen({super.key, required this.pdfId, this.initialPage});

  @override
  ConsumerState<UserPdfViewerScreen> createState() => _UserPdfViewerScreenState();
}

class _UserPdfViewerScreenState extends ConsumerState<UserPdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  UserPdfIndex? _index;

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  Future<void> _loadIndex() async {
    final index = await ref.read(userPdfIndexProvider).load(widget.pdfId);
    if (!mounted) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_index == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final index = _index!;
    final file = File(index.localPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(index.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (index.pages.isNotEmpty)
            PopupMenuButton<int>(
              tooltip: 'Jump to page',
              icon: const Icon(Icons.auto_stories),
              itemBuilder: (context) => [
                for (int i = 0; i < index.pages.length && i < 20; i++)
                  PopupMenuItem(
                    value: index.pages[i].page,
                    child: Text('Page ${index.pages[i].page}'),
                  ),
              ],
              onSelected: (page) => _controller.jumpToPage(page),
            ),
        ],
      ),
      body: file.existsSync()
          ? SfPdfViewer.file(
              file,
              controller: _controller,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              canShowPaginationDialog: true,
              onDocumentLoaded: (details) {
                if (widget.initialPage != null) {
                  _controller.jumpToPage(widget.initialPage!);
                }
              },
              onPageChanged: (details) {},
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('PDF file not found'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
    );
  }
}