import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/question_model.dart';

/// Top-level helper function for compute isolate execution.
Set<String> _normalizeBatch(List<String> texts) {
  return texts.map(QuestionImporter.normalizeText).toSet();
}

/// Result of a question import run.
class QuestionImportResult {
  final int parsed;
  final int imported;
  final int skippedDuplicates;
  final List<String> errors;

  QuestionImportResult({
    required this.parsed,
    required this.imported,
    required this.skippedDuplicates,
    required this.errors,
  });

  int get rejected => errors.length;
}

/// Parses and validates bulk question data (JSON or CSV) into [Question]s.
///
/// Accepted JSON shape (a list, or an object with a `questions`/`data` key):
/// ```json
/// [
///   {
///     "questionText": "...",
///     "options": ["A", "B", "C", "D"],
///     "correctAnswer": "A",
///     "subject": "Biology",
///     "chapter": "The Living World",
///     "topic": "Characteristics",
///     "difficulty": "Easy",
///     "year": 2023
///   }
/// ]
/// ```
///
/// CSV files use the same field names as headers (`options` may also be given
/// as `option1`, `option2`, ... columns, or as one column using `|||`).
class QuestionImporter {
  QuestionImporter({Set<String>? existingTexts, String? baseId})
      : _existingTexts = existingTexts ?? const {},
        _baseId = baseId ?? 'imp_${DateTime.now().microsecondsSinceEpoch}';

  final Set<String> _existingTexts;
  final String _baseId;

  static const _subjectAliases = {
    'bio': 'Biology',
    'biology': 'Biology',
    'botany': 'Biology',
    'zoology': 'Biology',
    'chem': 'Chemistry',
    'chemistry': 'Chemistry',
    'phys': 'Physics',
    'physics': 'Physics',
  };

  /// Canonicalizes a question text so duplicates can be detected.
  static String normalizeText(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Runs normalization in a background isolate using [compute] for large batches.
  static Future<Set<String>> normalizeTextsInBackground(List<String> texts) async {
    return await compute(_normalizeBatch, texts);
  }

  /// Parses a JSON document into raw question rows.
  ///
  /// Accepts either a top-level array or an object wrapping a `questions`
  /// (or `data`) array. Throws [FormatException] for malformed input.
  List<Map<String, dynamic>> parseJson(String raw) {
    final decoded = jsonDecode(raw);
    final dynamic items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final list = map['questions'] ?? map['data'];
      if (list is! List) {
        throw const FormatException(
          'JSON must be a list of questions or an object with a "questions" array.',
        );
      }
      items = list;
    } else {
      throw const FormatException('Unsupported JSON structure.');
    }

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is Map) {
        rows.add(Map<String, dynamic>.from(item));
      } else {
        throw FormatException('Row $i is not a JSON object.');
      }
    }
    return rows;
  }

  /// Parses CSV text into raw question rows, mapping headers to canonical
  /// field names. Returns an empty list for blank input.
  List<Map<String, dynamic>> parseCsv(String raw, {bool hasHeader = true}) {
    final table = _parseCsvTable(raw);
    if (table.isEmpty) return const [];

    List<String> headers;
    final Iterable<List<String>> body;
    if (hasHeader) {
      headers = table.first.map((h) => h.trim()).toList();
      body = table.skip(1);
    } else {
      headers = List.generate(table.first.length, (i) => 'option$i');
      body = table;
    }

    final rows = <Map<String, dynamic>>[];
    for (final line in body) {
      final row = <String, dynamic>{};
      for (var i = 0; i < headers.length && i < line.length; i++) {
        row[_canonicalHeader(headers[i])] = line[i];
      }
      if (row.values.any((v) => (v.toString()).trim().isNotEmpty)) {
        rows.add(row);
      }
    }
    return rows;
  }

  static String _canonicalHeader(String header) {
    final h = header.trim().toLowerCase().replaceAll('-', '_');
    const aliases = <String, String>{
      'questiontext': 'questionText',
      'question': 'questionText',
      'text': 'questionText',
      'q': 'questionText',
      'correctanswer': 'correctAnswer',
      'correct_answer': 'correctAnswer',
      'answer': 'correctAnswer',
      'answerkey': 'correctAnswer',
      'answer_key': 'correctAnswer',
      'correct': 'correctAnswer',
      'topicid': 'topicId',
      'topic_id': 'topicId',
      'ncertreference': 'ncertReference',
      'ncert_reference': 'ncertReference',
      'imageurl': 'imageUrl',
      'image_url': 'imageUrl',
    };
    if (RegExp(r'^option\d+$').hasMatch(h)) return h;
    return aliases[h] ?? h;
  }

  /// Builds validated [Question]s from parsed rows, skipping duplicates and
  /// invalid entries (which are reported in [QuestionImportResult.errors]).
  (List<Question>, QuestionImportResult) buildQuestions(
    List<Map<String, dynamic>> rows,
  ) {
    final questions = <Question>[];
    final errors = <String>[];
    final seen = <String>{..._existingTexts};
    var duplicates = 0;

    for (var i = 0; i < rows.length; i++) {
      final rowNumber = i + 1;
      final normalized = _normalizeRow(rows[i]);

      final questionText = normalized['questionText']?.toString().trim() ?? '';
      if (questionText.isEmpty) {
        errors.add('Row $rowNumber: missing questionText.');
        continue;
      }

      final correctAnswer = normalized['correctAnswer']?.toString().trim() ?? '';
      if (correctAnswer.isEmpty) {
        errors.add('Row $rowNumber: missing correctAnswer.');
        continue;
      }

      final options = _parseOptions(normalized);
      if (options.length < 2) {
        errors.add('Row $rowNumber: needs at least 2 options.');
        continue;
      }

      final key = normalizeText(questionText);
      if (seen.contains(key)) {
        duplicates++;
        continue;
      }
      seen.add(key);

      questions.add(
        Question(
          id: '$_baseId${questions.length}',
          subject: _canonicalSubject(
            normalized['subject']?.toString().trim() ?? 'General',
          ),
          chapter: normalized['chapter']?.toString().trim() ?? 'General',
          topic: normalized['topic']?.toString().trim() ?? 'General',
          topicId: _parseTopicId(normalized),
          questionText: questionText,
          options: options,
          correctAnswer: correctAnswer,
          explanation: normalized['explanation']?.toString().trim(),
          ncertReference: normalized['ncertReference']?.toString().trim(),
          year: _parseYear(normalized['year']),
          difficulty: _parseDifficulty(normalized['difficulty']),
          tags: _parseTags(normalized['tags']),
          imageUrl: normalized['imageUrl']?.toString().trim(),
          type: _parseType(normalized['type']),
        ),
      );
    }

    return (
      questions,
      QuestionImportResult(
        parsed: rows.length,
        imported: questions.length,
        skippedDuplicates: duplicates,
        errors: errors,
      ),
    );
  }

  // ============= row normalization =============

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final out = <String, dynamic>{};
    void pick(List<String> keys, String target) {
      for (final key in keys) {
        final v = row[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          out[target] = v;
          return;
        }
      }
    }

    pick(['questionText', 'question', 'text', 'q'], 'questionText');
    pick(
      ['correctAnswer', 'correct_answer', 'answer', 'correct', 'answerKey'],
      'correctAnswer',
    );
    pick(['options'], 'options');
    pick(['subject'], 'subject');
    pick(['chapter'], 'chapter');
    pick(['topic'], 'topic');
    pick(['topicId', 'topic_id'], 'topicId');
    pick(['explanation'], 'explanation');
    pick(['ncertReference', 'ncert_reference'], 'ncertReference');
    pick(['difficulty'], 'difficulty');
    pick(['year'], 'year');
    pick(['tags'], 'tags');
    pick(['type'], 'type');
    pick(['imageUrl', 'image_url'], 'imageUrl');

    // Multi-column options (option1..optionN).
    final optionCols = row.keys
        .where((k) => RegExp(r'^option\d+$').hasMatch(k))
        .toList()
      ..sort((a, b) {
        final na = int.parse(a.replaceAll(RegExp(r'\D'), ''));
        final nb = int.parse(b.replaceAll(RegExp(r'\D'), ''));
        return na.compareTo(nb);
      });
    if (optionCols.isNotEmpty) {
      out['optionColumns'] = optionCols
          .map((k) => row[k]?.toString().trim() ?? '')
          .where((v) => v.isNotEmpty)
          .toList();
    }

    return out;
  }

  List<String> _parseOptions(Map<String, dynamic> row) {
    final cols = row['optionColumns'];
    if (cols is List && cols.isNotEmpty) {
      return cols.cast<String>().toList();
    }

    final raw = row['options'];
    if (raw is List) {
      return raw
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw != null) {
      final text = raw.toString().trim();
      for (final sep in ['|||', ';', '|', '\n', ',']) {
        if (text.contains(sep)) {
          return text
              .split(sep)
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    }
    return const [];
  }

  String _parseTopicId(Map<String, dynamic> row) {
    final topicId = row['topicId']?.toString().trim();
    if (topicId != null && topicId.isNotEmpty) return topicId;

    final chapter = row['chapter']?.toString().trim() ?? '';
    final topic = row['topic']?.toString().trim() ?? '';
    final base = (chapter + topic).isEmpty
        ? 'imported'
        : '$chapter-$topic';
    return base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  int? _parseYear(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    final parsed = int.tryParse(RegExp(r'\d{4}').firstMatch(text)?.group(0) ?? '');
    return parsed;
  }

  String _parseDifficulty(dynamic value) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text.isEmpty || text == 'medium' || text == 'moderate') return 'Medium';
    if (text == 'easy' || text == 'e') return 'Easy';
    if (text == 'hard' || text == 'difficult' || text == 'h') return 'Hard';
    return 'Medium';
  }

  String _parseType(dynamic value) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'integer' || text == 'numerical') return 'integer';
    if (text == 'short' || text == 'shortanswer' || text == 'subjective') {
      return 'short';
    }
    return 'mcq';
  }

  List<String> _parseTags(dynamic value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value != null) {
      return value
          .toString()
          .split(RegExp(r'[,|||]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String _canonicalSubject(String subject) =>
      _subjectAliases[subject.toLowerCase()] ?? subject;

  // ============= CSV table parser =============

  static List<List<String>> _parseCsvTable(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < input.length) {
      final c = input[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
      } else {
        if (c == '"') {
          inQuotes = true;
        } else if (c == ',') {
          row.add(field.toString().trim());
          field = StringBuffer();
        } else if (c == '\n' || c == '\r') {
          row.add(field.toString().trim());
          field = StringBuffer();
          if (!_isBlankRow(row)) {
            rows.add(row);
          }
          row = [];
        } else {
          field.write(c);
        }
      }
      i++;
    }

    row.add(field.toString().trim());
    if (!_isBlankRow(row)) {
      rows.add(row);
    }
    return rows;
  }

  static bool _isBlankRow(List<String> row) =>
      row.isEmpty || (row.length == 1 && row.first.isEmpty);
}
