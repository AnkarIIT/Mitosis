import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/providers/providers.dart';
import '../../core/services/pdf_extraction_service.dart';
import '../../core/services/user_pdf_index_service.dart';
import '../../core/theme/app_theme.dart';

/// Bottom sheet to attach a new PDF for grounded chat.
/// Handles file picking, validation, extraction progress, and adds to index.
class PdfAttachmentBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback onPdfAdded;

  const PdfAttachmentBottomSheet({super.key, required this.onPdfAdded});

  @override
  ConsumerState<PdfAttachmentBottomSheet> createState() =>
      _PdfAttachmentBottomSheetState();
}

class _PdfAttachmentBottomSheetState
    extends ConsumerState<PdfAttachmentBottomSheet> {
  String? _status;
  double? _progress;
  int _pagesDone = 0;
  int _pagesTotal = 0;
  bool _extracting = false;

  Future<void> _pickAndExtract() async {
    if (_extracting) return;

    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (files.isEmpty) return;

    final pickedFile = files.single;
    final filePath = pickedFile.path!;
    final file = File(filePath);

    // Validate
    final validationError = await UserPdfIndexService.validatePdf(file);
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    // Compute ID and sandbox path
    final pdfId = await UserPdfIndexService.computePdfId(file);
    final docs = await getApplicationDocumentsDirectory();
    final sandboxPath = '${docs.path}/pdf_index/$pdfId.pdf';

    setState(() {
      _extracting = true;
      _status = 'Starting extraction...';
      _progress = 0;
      _pagesDone = 0;
      _pagesTotal = 0;
    });

    try {
      await for (final event in PdfExtractionService.extract(
        pdfFilePath: filePath,
        pdfId: pdfId,
        originalName: pickedFile.name,
        sandboxPath: sandboxPath,
      )) {
        if (!mounted) return;
        setState(() {
          switch (event) {
            case ExtractionStarted(totalPages: final t):
              _pagesTotal = t;
              _status = 'Extracting page 1 of $t...';
              _progress = 0;
            case PageExtracted(page: final p, totalPages: final t, wordsSoFar: _):
              _pagesDone = p;
              _status = 'Extracting page $p of $t...';
              _progress = p / t;
            case ExtractionCompleted(index: final idx):
              _status = 'Done! ${idx.pages.length} pages indexed.';
              _progress = 1;
              // Save outside setState since it's async
              ref.read(userPdfIndexProvider).save(idx).then((_) {
                if (mounted) widget.onPdfAdded();
              });
            case ExtractionFailed(error: final e):
              _status = 'Failed: $e';
              _progress = null;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Error: $e';
        _progress = null;
      });
    } finally {
      if (mounted) {
        setState(() => _extracting = false);
        // Auto-close on success after brief delay
        if (_progress == 1) {
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AdaptiveColors.divider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Attach PDF for Grounding',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a PDF (max 10 MB, 50 pages). Its text will be indexed and used to ground AI answers with [p.N] citations.',
              style: TextStyle(
                color: AdaptiveColors.textSecondary(context),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (!_extracting) ...[
              FilledButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Choose PDF'),
                onPressed: _pickAndExtract,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ] else ...[
              // Extraction progress
              Column(
                children: [
                  Text(_status ?? '',
                      style: TextStyle(color: AdaptiveColors.textSecondary(context))),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AdaptiveColors.surfaceContainerHighest(context),
                  ),
                  if (_pagesTotal > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$_pagesDone / $_pagesTotal pages',
                        style: TextStyle(
                          color: AdaptiveColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            TextButton(
              onPressed: _extracting ? null : () => context.pop(),
              child: Text(_extracting ? 'Cancel' : 'Close'),
            ),
          ],
        ),
      ),
    );
  }
}