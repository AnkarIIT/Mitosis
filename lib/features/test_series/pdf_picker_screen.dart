import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/pdf_service.dart';
import '../../core/database/question_repository.dart';
import '../../core/models/question_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';


class PdfPickerScreen extends ConsumerStatefulWidget {
  const PdfPickerScreen({super.key});

  @override
  ConsumerState<PdfPickerScreen> createState() => _PdfPickerScreenState();
}

class _PdfPickerScreenState extends ConsumerState<PdfPickerScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  String _status = "Select an NCERT PDF to begin";
  List<Map<String, String>> _chapters = [];
  String _selectedSubject = "Biology";

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty) {
      final file = files.single;
      setState(() {
        _selectedFile = File(file.path!);
        _status = "File selected: ${file.name}";
      });
      _processPdf();
    }
  }

  Future<void> _processPdf() async {
    if (_selectedFile == null) return;

    setState(() {
      _isProcessing = true;
      _status = "Extracting text from PDF...";
    });

    try {
      final text = await PdfService.extractText(_selectedFile!);
      final chapters = PdfService.splitByChapters(text);

      setState(() {
        _chapters = chapters;
        _isProcessing = false;
        _status = "Found ${chapters.length} chapters. Ready to generate questions.";
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = "Error processing PDF: $e";
      });
    }
  }

  static const int _maxQuestionsPerChapter = 15;
  static const int _chunkSize = 12000;
  static const int _chunkOverlap = 200;
  int _generatedIdSeq = 0;

  Future<void> _generateQuestions(int index) async {
    final gemini = ref.read(geminiServiceProvider);
    if (!gemini.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please configure Gemini API Key in Settings.")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = "AI is generating questions for ${_chapters[index]['title']}...";
    });

    try {
      // Chapters can exceed Gemini's input limit, so send the text in chunks.
      final chunks = _splitIntoChunks(_chapters[index]['content']!);
      final generated = <Map<String, dynamic>>[];
      final seenQuestions = <String>{};

      for (var i = 0;
          i < chunks.length && generated.length < _maxQuestionsPerChapter;
          i++) {
        setState(() {
          _status = "AI is generating questions for ${_chapters[index]['title']}..."
              " (${i + 1}/${chunks.length})";
        });

        final batch = await gemini.generateQuestionsFromText(
          chunks[i],
          _selectedSubject,
        );
        for (var q in batch) {
          final key = (q['questionText'] as String? ?? '').trim();
          if (key.isNotEmpty && seenQuestions.add(key)) {
            generated.add(q);
            if (generated.length >= _maxQuestionsPerChapter) break;
          }
        }
      }

      if (generated.isEmpty) {
        setState(() {
          _isProcessing = false;
          _status = "AI failed to generate questions. Try another chapter.";
        });
        return;
      }

      final repo = ref.read(questionRepositoryProvider);
      for (var qData in generated) {
        final q = Question(
          id: _nextGeneratedId(),
          questionText: qData['questionText'],
          correctAnswer: qData['correctAnswer'],
          options: List<String>.from(qData['options'] ?? []),
          type: qData['type'] ?? 'mcq',
          subject: _selectedSubject,
          chapter: _chapters[index]['title']!,
          topic: _chapters[index]['title']!,
          topicId: const Uuid().v4(),
          difficulty: qData['difficulty'] ?? 'Medium',
          tags: [],
          createdAt: DateTime.now(),
        );
        await repo.insertQuestion(q);
      }
      // Make the freshly generated questions visible to test series & the DB pool.
      ref.invalidate(allQuestionsProvider);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _status = "Successfully generated ${generated.length} questions!";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Generated ${generated.length} questions from NCERT!")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _status = "Error generating questions: $e";
      });
    }
  }

  /// Splits a long text into overlapping chunks, breaking on word boundaries
  /// so the AI never receives a slice of a question.
  List<String> _splitIntoChunks(String text) {
    if (text.length <= _chunkSize) {
      return [text];
    }

    final chunks = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = (start + _chunkSize).clamp(0, text.length);
      if (end < text.length) {
        final lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace > start + _chunkSize ~/ 2) {
          end = lastSpace;
        }
      }
      chunks.add(text.substring(start, end));
      if (end >= text.length) break;
      start = end - _chunkOverlap;
    }
    return chunks;
  }

  /// Generates a collision-resistant string id for AI-created questions.
  /// Sample question ids are small strings, so generated ids stay far away.
  String _nextGeneratedId() {
    final base = DateTime.now().microsecondsSinceEpoch % 100000000;
    return 'gen_${base * 1000 + (_generatedIdSeq++ % 1000)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: const Text("AI PDF Engine"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, size: 56, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 24),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 24),
                  if (!_isProcessing)
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("UPLOAD NCERT BOOK"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_chapters.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Extracted Chapters",
                    style: GoogleFonts.poppins(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedSubject,
                    items: ["Biology", "Chemistry", "Physics"].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSubject = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: AdaptiveColors.surface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AdaptiveColors.divider(context)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          _chapters[index]['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${(_chapters[index]['content']!.length / 1000).toStringAsFixed(1)}k characters of study material",
                          style: TextStyle(color: AdaptiveColors.textSecondary(context)),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _generateQuestions(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                          ),
                          child: const Text("GENERATE"),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
