import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../models/stored_document.dart';

final logger = Logger();

/// Local, file-backed persistence for scanned documents.
///
/// Documents are stored as a JSON array in `documorph_documents.json` inside
/// the app's documents directory (via path_provider). This is deliberately
/// simple — no database or code generation — and matches StoredDocument's
/// existing toJson/fromJson. Writes go to a temp file that is then renamed
/// over the data file, so an interrupted write cannot corrupt the library.
///
/// The directory provider is injectable so tests can point the store at a
/// temporary directory.
class DocumentStore {
  static const String dataFileName = 'documorph_documents.json';

  final Future<Directory> Function() _directoryProvider;
  List<StoredDocument>? _cache;

  DocumentStore({Future<Directory> Function()? directoryProvider})
      : _directoryProvider =
            directoryProvider ?? getApplicationDocumentsDirectory;

  Future<File> _dataFile() async {
    final dir = await _directoryProvider();
    return File('${dir.path}/$dataFileName');
  }

  /// Load all documents, newest first. Returns an empty list when nothing
  /// has been saved yet or the file cannot be read.
  Future<List<StoredDocument>> loadAll() async {
    if (_cache != null) return List.unmodifiable(_cache!);
    try {
      final file = await _dataFile();
      if (!await file.exists()) {
        _cache = [];
        return List.unmodifiable(_cache!);
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        _cache = [];
        return List.unmodifiable(_cache!);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        logger.w('Document store file has unexpected shape; starting empty');
        _cache = [];
        return List.unmodifiable(_cache!);
      }
      final docs = decoded
          .whereType<Map>()
          .map((e) => StoredDocument.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _cache = docs;
      return List.unmodifiable(_cache!);
    } catch (e) {
      logger.e('Failed to load documents', error: e);
      _cache = [];
      return List.unmodifiable(_cache!);
    }
  }

  /// Insert a document, or replace the existing one with the same id.
  Future<void> save(StoredDocument document) async {
    final docs = List<StoredDocument>.from(await loadAll());
    final index = docs.indexWhere((d) => d.id == document.id);
    if (index >= 0) {
      docs[index] = document;
    } else {
      docs.add(document);
    }
    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache = docs;
    await _persist(docs);
    logger.i('Document saved: ${document.id}');
  }

  /// Delete the document with [id]. Returns true when one was removed.
  Future<bool> delete(String id) async {
    final docs = List<StoredDocument>.from(await loadAll());
    final before = docs.length;
    docs.removeWhere((d) => d.id == id);
    if (docs.length == before) return false;
    _cache = docs;
    await _persist(docs);
    logger.i('Document deleted: $id');
    return true;
  }

  /// Case-insensitive full-text search across title, OCR text, vendor and
  /// category. An empty query returns everything (newest first).
  Future<List<StoredDocument>> search(String query) async {
    final docs = await loadAll();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return docs;
    return docs
        .where((d) =>
            d.title.toLowerCase().contains(q) ||
            d.ocrText.toLowerCase().contains(q) ||
            (d.vendor?.toLowerCase().contains(q) ?? false) ||
            d.category.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _persist(List<StoredDocument> docs) async {
    final file = await _dataFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(docs.map((d) => d.toJson()).toList()),
      flush: true,
    );
    await tmp.rename(file.path);
  }
}
