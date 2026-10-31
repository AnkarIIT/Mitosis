import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import 'user_pdf_index.dart';

/// Lazy loader for user-uploaded PDF text indices.
///
/// Indices are stored as JSON files under:
///   `getApplicationDocumentsDirectory()/pdf_index/<pdfId>.json`
///
/// The index directory is created on first use.
class UserPdfIndexService {
  static const String _indexDirName = 'pdf_index';
  static const int _maxPdfsPerUser = 20; // LRU cap
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int _maxPages = 50;

  /// Maximum pages allowed per user PDF (enforced during extraction).
  static int get maxPages => _maxPages;

  Directory? _indexDir;
  final Map<String, Future<UserPdfIndex?>> _cache = {};

  Future<Directory> get _dir async {
    _indexDir ??= await _ensureDir();
    return _indexDir!;
  }

  Future<Directory> _ensureDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_indexDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// All indexed PDF IDs for the current user (sorted by recency, newest first).
  Future<List<String>> listPdfIds() async {
    final dir = await _dir;
    if (!await dir.exists()) return const [];
    final files = await dir.list().toList();
    final ids = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
        .toList();

    // Sort by modified time, newest first (LRU)
    final withTime = <String, DateTime>{};
    for (final id in ids) {
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) {
        withTime[id] = await file.lastModified();
      }
    }
    ids.sort((a, b) => withTime[b]!.compareTo(withTime[a]!));
    return ids;
  }

  /// All loaded indices (newest first) for the ribbon picker.
  Future<List<UserPdfIndex>> listIndices() async {
    final ids = await listPdfIds();
    final indices = <UserPdfIndex>[];
    for (final id in ids) {
      final idx = await load(id);
      if (idx != null) indices.add(idx);
    }
    return indices;
  }

  /// Loads one PDF's index, or `null` if missing/corrupt.
  Future<UserPdfIndex?> load(String pdfId) {
    return _cache.putIfAbsent(pdfId, () => _readIndex(pdfId));
  }

  Future<UserPdfIndex?> _readIndex(String pdfId) async {
    try {
      final dir = await _dir;
      final file = File('${dir.path}/$pdfId.json');
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      return UserPdfIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _cache.remove(pdfId);
      return null;
    }
  }

  /// Saves an index (used by extraction service).
  Future<void> save(UserPdfIndex index) async {
    final dir = await _dir;
    final file = File('${dir.path}/${index.pdfId}.json');
    await file.writeAsString(
      jsonEncode(index.toJson()),
      flush: true,
    );
    _cache[index.pdfId] = Future.value(index);
    await _enforceQuota();
  }

  /// Deletes a PDF's index and its sandboxed copy.
  Future<void> delete(String pdfId) async {
    final dir = await _dir;
    final indexFile = File('${dir.path}/$pdfId.json');
    if (await indexFile.exists()) await indexFile.delete();

    // Also try to delete the sandboxed PDF copy
    final idx = await load(pdfId);
    if (idx != null) {
      final pdfFile = File(idx.localPath);
      if (await pdfFile.exists()) await pdfFile.delete();
    }
    _cache.remove(pdfId);
  }

  /// Enforces the per-user PDF count limit (LRU eviction).
  Future<void> _enforceQuota() async {
    final ids = await listPdfIds();
    if (ids.length <= _maxPdfsPerUser) return;
    for (final id in ids.skip(_maxPdfsPerUser)) {
      await delete(id);
    }
  }

  /// Computes a stable PDF ID from file content + timestamp.
  static Future<String> computePdfId(File file) async {
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString().substring(0, 16);
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return '${hash}_$ts';
  }

  /// Validates a picked PDF against size/page limits.
  /// Returns error message if invalid, null if OK.
  static Future<String?> validatePdf(File file) async {
    if (!await file.exists()) return 'File not found.';
    final stat = await file.stat();
    if (stat.size > _maxFileSizeBytes) {
      return 'File too large (max ${_maxFileSizeBytes ~/ (1024 * 1024)} MB).';
    }
    // Page count check will be done during extraction
    return null;
  }
}