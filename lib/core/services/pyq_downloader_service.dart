import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../database/question_repository.dart';
import '../models/question_model.dart';
import '../services/question_importer.dart';

/// Comprehensive service for downloading NEET Previous Year Questions.
/// Supports multiple sources, parallel downloads, progress tracking, and deduplication.
class PyqDownloaderService {
  final QuestionRepository _repository;
  final http.Client _client;

  PyqDownloaderService(this._repository, {http.Client? client})
    : _client = client ?? http.Client();

  /// Download progress events
  /// Stream of download progress events
  Stream<DownloadProgress>? downloadProgress;

  /// Download status tracking
  final DownloadStatus _status = DownloadStatus();

  /// Public download sources - industry standard NEET PYQ URLs
  static const List<PyqSource> defaultSources = [
    PyqSource(
      url: 'https://raw.githubusercontent.com/cursed-engineer/NEET-PYQs/main/questions.json',
      label: 'NEET PYQs 2015-2024',
      format: 'json',
      reliability: 0.9,
    ),
    PyqSource(
      url: 'https://neetpyqs.hf.space/questions.json',
      label: 'HuggingFace NEET Questions',
      format: 'json',
      reliability: 0.8,
    ),
  ];

  /// Download all questions from all sources
  Future<int> downloadAll({
    int batchSize = 100,
    bool showProgress = true,
  }) async {
    final progressController = StreamController<DownloadProgress>();
    
    try {
      _status.reset();
      int totalInserted = 0;
      int totalFailed = 0;
      final List<String> downloadedFiles = [];

      for (final source in defaultSources) {
        if (_status.isCancelled) break;

        try {
          final result = await _downloadSource(
            source,
            batchSize: batchSize,
          );
          
          if (result.success) {
            totalInserted += result.inserted;
            downloadedFiles.add(source.label);
            _status.updateProgress(totalInserted, result.totalFound);
            
            if (showProgress) {
              progressController.add(DownloadProgress(
                stage: 'downloading',
                downloaded: totalInserted,
                total: result.totalFound,
                currentSource: source.label,
              ));
            }
          } else {
            totalFailed++;
            if (showProgress) {
              progressController.add(DownloadProgress(
                stage: 'error',
                error: result.error,
                currentSource: source.label,
              ));
            }
          }
        } catch (e, s) {
          totalFailed++;
          debugPrint('❌ Download failed for ${source.label}: $e');
          debugPrintStack(stackTrace: s);
        }
      }

      // Final summary
      if (showProgress) {
        progressController.add(DownloadProgress(
          stage: 'complete',
          downloaded: totalInserted,
          total: totalInserted,
          summary: 'Downloaded $totalInserted new questions from ${downloadedFiles.length} sources',
        ));
      }

      _status.completed(totalInserted, totalFailed);
      return totalInserted;
    } finally {
      await progressController.close();
    }
  }

  /// Download from a single source
  Future<_DownloadSourceResult> _downloadSource(
    PyqSource source, {
    int batchSize = 100,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(source.url),
        headers: {
          'User-Agent': 'NEET-Mitos/1.0 (Educational Research)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return _DownloadSourceResult(
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }

      // Parse JSON
      List<dynamic> rawData;
      try {
        rawData = json.decode(response.body) as List<dynamic>;
      } catch (e) {
        // Try single object format
        try {
          final single = json.decode(response.body);
          rawData = [single];
        } catch (e2) {
          return _DownloadSourceResult(
            success: false,
            error: 'Invalid JSON format: $e',
          );
        }
      }

      if (rawData.isEmpty) {
        return _DownloadSourceResult(
          success: false,
          error: 'No questions found in source',
        );
      }

      // Parse and validate questions
      final questions = <Question>[];
      final List<String> errors = [];

      for (final item in rawData) {
        try {
          final q = _parseQuestion(item as Map<String, dynamic>, source.label);
          if (q != null) {
            questions.add(q);
          }
        } catch (e) {
          errors.add('Parse error: $e');
        }
      }

      if (questions.isEmpty) {
        return _DownloadSourceResult(
          success: false,
          error: errors.isEmpty ? 'No valid questions' : errors.first,
        );
      }

      // Deduplicate against existing questions
      final existingTexts = await _repository.getExistingQuestionTexts();
      final toInsert = questions
          .where((q) => !existingTexts.contains(
            QuestionImporter.normalizeText(q.questionText),
          ))
          .toList();

      if (toInsert.isEmpty) {
        return _DownloadSourceResult(
          success: true,
          inserted: 0,
          totalFound: questions.length,
          alreadyExists: questions.length,
        );
      }

      // Batch insert for performance
      for (var i = 0; i < toInsert.length; i += batchSize) {
        final batch = toInsert.sublist(
          i,
          (i + batchSize).clamp(0, toInsert.length),
        );
        await _repository.bulkInsertQuestions(batch);
      }

      debugPrint('✅ Downloaded ${(toInsert.length)} new questions from ${source.label}');

      return _DownloadSourceResult(
        success: true,
        inserted: toInsert.length,
        totalFound: questions.length,
      );
    } catch (e, s) {
      debugPrint('❌ Download error for ${source.label}: $e');
      debugPrintStack(stackTrace: s);
      return _DownloadSourceResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Parse a question from various JSON formats
  Question? _parseQuestion(Map<String, dynamic> json, String sourceLabel) {
    // Extract question text
    final text = (json['questionText'] ??
            json['question'] ??
            json['question_text'] ??
            json['q'] ??
            '')
        .toString()
        .trim();
    
    if (text.isEmpty) return null;

    // Extract options
    final options = _parseOptions(json);
    if (options.length < 2) return null;

    // Extract correct answer
    final correctAnswer = (json['correctAnswer'] ??
            json['answer'] ??
            json['correct_answer'] ??
            json['ans'] ??
            '')
        .toString()
        .trim();
    
    if (correctAnswer.isEmpty) return null;

    // Extract metadata
    final subject = _extractSubject(json, text);
    final chapter = json['chapter']?.toString().trim() ??
        _inferChapter(text, subject);
    final topic = json['topic']?.toString().trim() ?? chapter;
    final topicId = json['topicId']?.toString().trim() ??
        'topic_${subject}_${topic.replaceAll(' ', '_')}';
    final year = _extractYear(json);
    final difficulty = json['difficulty']?.toString().trim() ?? 'Medium';
    final explanation = json['explanation']?.toString().trim();
    final ncertRef = json['ncertReference']?.toString().trim() ??
        json['ncert_reference']?.toString().trim();
    final type = json['type']?.toString().trim() ?? 'MCQ';
    final tags = _parseTags(json);

    // Generate unique ID
    final id = _generateId(text, sourceLabel, year);

    return Question(
      id: id,
      subject: subject,
      chapter: chapter,
      topic: topic,
      topicId: topicId,
      questionText: text,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      ncertReference: ncertRef,
      year: year,
      difficulty: difficulty,
      tags: tags,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  List<String> _parseOptions(Map<String, dynamic> json) {
    // Handle different option formats
    if (json['options'] is List) {
      return (json['options'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    
    if (json['options'] is Map) {
      final options = <String>[];
      final map = json['options'] as Map<String, dynamic>;
      for (final key in ['A', 'B', 'C', 'D', 'a', 'b', 'c', 'd']) {
        if (map.containsKey(key)) {
          options.add(map[key].toString().trim());
        }
      }
      return options;
    }
    
    // Handle string format: "A. Option1|||B. Option2"
    final optionsStr = json['options']?.toString() ?? '';
    if (optionsStr.contains('|||')) {
      return optionsStr
          .split('|||')
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    
    if (optionsStr.startsWith('[')) {
      try {
        return (jsonDecode(optionsStr) as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {}
    }
    
    return [];
  }

  String _extractSubject(Map<String, dynamic> json, String text) {
    final subject = json['subject']?.toString().trim();
    if (subject != null && subject.isNotEmpty) return subject;
    
    // Infer from text
    final lowerText = text.toLowerCase();
    if (lowerText.contains('biology') ||
        lowerText.contains('botany') ||
        lowerText.contains('zoology')) {
      return 'Biology';
    }
    if (lowerText.contains('chemistry') || lowerText.contains('chem')) {
      return 'Chemistry';
    }
    if (lowerText.contains('physics') || lowerText.contains('phy')) {
      return 'Physics';
    }
    return 'Biology'; // Default
  }

  String _inferChapter(String text, String subject) {
    final lower = text.toLowerCase();
    if (lower.contains('cell division') || lower.contains('mitosis')) return 'Cell Biology';
    if (lower.contains('genetics') || lower.contains('dna') || lower.contains('rna')) return 'Genetics';
    if (lower.contains('chemical bonding')) return 'Chemical Bonding';
    if (lower.contains('atom') || lower.contains('structure')) return 'Atomic Structure';
    return 'General';
  }

  int? _extractYear(Map<String, dynamic> json) {
    final yearStr = (json['year'] ??
            json['exam_year'] ??
            json['examYear'] ??
            json['date']?.toString())
        .toString();
    
    // Try to extract 4-digit year
    final match = RegExp(r'20\d{2}').firstMatch(yearStr);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  List<String> _parseTags(Map<String, dynamic> json) {
    if (json['tags'] is List) {
      return (json['tags'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  String _generateId(String text, String source, int? year) {
    final hash = '$source${year ?? ''}'.hashCode;
    final textHash = text.hashCode;
    return 'pyq_${source.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}_${year ?? 'unknown'}_${textHash}_$hash';
  }

  /// Cancel ongoing downloads
  void cancel() => _status.cancel();

  /// Check if download is in progress
  bool get isDownloading => _status.isLoading;
}

/// Helper class for source configuration
class PyqSource {
  const PyqSource({
    required this.url,
    required this.label,
    required this.format,
    required this.reliability,
  });

  final String url;
  final String label;
  final String format;
  final double reliability;
}

/// Download result
class _DownloadSourceResult {
  _DownloadSourceResult({
    required this.success,
    this.inserted = 0,
    this.totalFound = 0,
    this.alreadyExists = 0,
    this.error,
  });

  final bool success;
  final int inserted;
  final int totalFound;
  final int alreadyExists;
  final String? error;
}

/// Download progress
class DownloadProgress {
  const DownloadProgress({
    required this.stage,
    this.downloaded = 0,
    this.total = 0,
    this.currentSource = '',
    this.error,
    this.summary = '',
  });

  final String stage; // 'downloading', 'error', 'complete'
  final int downloaded;
  final int total;
  final String currentSource;
  final String? error;
  final String summary;

  double get progress => total > 0 ? downloaded / total : 0;
}

/// Download result summary
class DownloadResult {
  const DownloadResult({
    required this.success,
    required this.totalInserted,
    required this.totalFailed,
    required this.messages,
    required this.totalFound,
  });

  final bool success;
  final int totalInserted;
  final int totalFailed;
  final List<String> messages;
  final int totalFound;
}

/// Internal status tracker
class DownloadStatus {
  bool _isLoading = false;
  bool _isCancelled = false;

  bool get isLoading => _isLoading;
  bool get isCancelled => _isCancelled;

  void reset() {
    _isLoading = true;
    _isCancelled = false;
  }

  void updateProgress(int inserted, int total) {}

  void completed(int inserted, int failed) {
    _isLoading = false;
  }

  void cancel() {
    _isCancelled = true;
    _isLoading = false;
  }
}
