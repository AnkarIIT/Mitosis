import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/question_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/database_service.dart';
import '../../core/services/question_importer.dart';
import '../../core/theme/app_colors.dart';

enum _ImportSource { file, paste }

class ImportQuestionsScreen extends ConsumerStatefulWidget {
  const ImportQuestionsScreen({super.key});

  @override
  ConsumerState<ImportQuestionsScreen> createState() =>
      _ImportQuestionsScreenState();
}

class _ImportQuestionsScreenState extends ConsumerState<ImportQuestionsScreen> {
  final _pasteController = TextEditingController();

  _ImportSource _source = _ImportSource.file;
  bool _isCsv = false;
  String _fileName = '';
  String _raw = '';
  List<Question> _built = const [];
  QuestionImportResult? _result;
  String? _formatError;
  bool _isImporting = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _formatError = 'Could not read the selected file.');
        return;
      }
      var text = utf8.decode(bytes, allowMalformed: true);
      if (text.startsWith('\uFEFF')) text = text.substring(1);

      setState(() {
        _fileName = file.name;
        _raw = text;
        _isCsv = file.name.toLowerCase().endsWith('.csv');
        _clearPreview();
      });
    } catch (e) {
      setState(() => _formatError = 'Error reading file: $e');
    }
  }

  void _clearPreview() {
    _built = const [];
    _result = null;
    _formatError = null;
  }

  Future<void> _parse() async {
    final raw = _source == _ImportSource.paste
        ? _pasteController.text
        : _raw;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() => _formatError = 'No content to parse.');
      return;
    }

    final importer = QuestionImporter();
    try {
      final rows = _isCsv
          ? importer.parseCsv(trimmed)
          : importer.parseJson(trimmed);

      final existing = await DatabaseService.instance.getExistingQuestionTexts();
      final (built, result) = QuestionImporter(
        existingTexts: existing,
      ).buildQuestions(rows);

      setState(() {
        _built = built;
        _result = result;
        _formatError = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _built = const [];
        _result = null;
        _formatError = e.message;
      });
    } catch (e) {
      setState(() => _formatError = 'Failed to parse: $e');
    }
  }

  Future<void> _import() async {
    if (_built.isEmpty) return;
    setState(() => _isImporting = true);

    try {
      final count = await DatabaseService.instance.bulkInsertQuestions(_built);
      ref.invalidate(allQuestionsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count questions successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Questions'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bulk-import questions from a JSON or CSV file (or pasted text). '
            'Useful for loading large NCERT / PYQ banks. Existing question '
            'texts are skipped automatically.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_ImportSource>(
            segments: const [
              ButtonSegment(
                value: _ImportSource.file,
                label: Text('File'),
                icon: Icon(Icons.upload_file),
              ),
              ButtonSegment(
                value: _ImportSource.paste,
                label: Text('Paste'),
                icon: Icon(Icons.content_paste),
              ),
            ],
            selected: {_source},
            onSelectionChanged: (selection) {
              setState(() {
                _source = selection.first;
                _clearPreview();
              });
            },
          ),
          const SizedBox(height: 16),
          if (_source == _ImportSource.file) ...[
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(
                _fileName.isEmpty ? 'Choose JSON / CSV file' : _fileName,
              ),
            ),
          ] else ...[
            TextField(
              controller: _pasteController,
              maxLines: 10,
              onChanged: (_) => _clearPreview(),
              decoration: const InputDecoration(
                hintText:
                    'Paste a JSON array or CSV text (with header row) here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Format:'),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('JSON'),
                selected: !_isCsv,
                onSelected: (_) {
                  setState(() {
                    _isCsv = false;
                    _clearPreview();
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('CSV'),
                selected: _isCsv,
                onSelected: (_) {
                  setState(() {
                    _isCsv = true;
                    _clearPreview();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _parse,
              icon: const Icon(Icons.preview_outlined),
              label: const Text('PARSE & PREVIEW'),
            ),
          ),
          if (_formatError != null) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.error.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _formatError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _buildSummaryCard(_result!),
            if (_result!.imported > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isImporting ? null : _import,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt),
                  label: Text(
                    _isImporting
                        ? 'Importing...'
                        : 'IMPORT ${_result!.imported} QUESTIONS',
                  ),
                ),
              ),
            ],
            if (_result!.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Skipped rows (fix and re-import):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _result!.errors.take(50).join('\n'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          _buildFormatHelp(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(QuestionImportResult result) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    'Parsed',
                    '${result.parsed}',
                    Icons.receipt_long_outlined,
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    'Ready',
                    '${result.imported}',
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    'Duplicates',
                    '${result.skippedDuplicates}',
                    Icons.content_copy,
                    color: AppColors.warning,
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    'Errors',
                    '${result.rejected}',
                    Icons.error_outline,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textDark,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildFormatHelp() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expected format',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'JSON: a list of question objects, or {"questions": [...]}.\n'
              'Required keys: questionText, correctAnswer, options '
              '(list, or "opt1|||opt2|||opt3|||opt4").\n'
              'Optional keys: subject, chapter, topic, topicId, difficulty '
              '(Easy/Medium/Hard), year, explanation, ncertReference, tags, '
              'type (mcq/integer/short).\n\n'
              'CSV: header row with the same names; options can also be '
              'option1, option2, ... columns.\n\n'
              'Subjects are auto-mapped: bio→Biology, chem→Chemistry, '
              'phys→Physics.',
              style: TextStyle(fontSize: 12, color: AppColors.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
