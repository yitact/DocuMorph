import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../models/stored_document.dart';
import 'encryption_service.dart';

final logger = Logger();

/// Local persistence for scanned documents, with optional encryption at rest.
///
/// Two modes:
/// - **Plain** (default): documents are stored as a JSON array in
///   `documorph_documents.json` in the app's documents directory.
/// - **Encrypted**: when an [EncryptionService] is supplied, the whole
///   library is serialized to JSON, encrypted with AES-256-GCM (see
///   EncryptionService), and stored as a single envelope string in
///   `documorph_documents.enc`. The service must be initialized
///   ("unlocked") before reads/writes, or they throw.
///
/// Encrypted-mode failures are NEVER swallowed into an empty library: a
/// wrong passphrase or tampered vault throws, because silently treating it
/// as "empty" would let the next save wipe the user's real library.
///
/// Migration: in encrypted mode, if a plaintext file from plain mode exists
/// and no encrypted vault does yet, the plaintext library is loaded,
/// re-persisted encrypted, and the plaintext file is deleted.
///
/// Writes go to a temp file renamed over the data file, so an interrupted
/// write cannot corrupt the library. The directory provider is injectable
/// so tests can point the store at a temporary directory.
class DocumentStore {
  static const String dataFileName = 'documorph_documents.json';
  static const String encryptedFileName = 'documorph_documents.enc';

  final Future<Directory> Function() _directoryProvider;
  final EncryptionService? _encryption;
  List<StoredDocument>? _cache;

  DocumentStore({
    Future<Directory> Function()? directoryProvider,
    EncryptionService? encryption,
  })  : _directoryProvider =
            directoryProvider ?? getApplicationDocumentsDirectory,
        _encryption = encryption;

  /// Whether this store encrypts its library at rest.
  bool get isEncrypted => _encryption != null;

  /// Whether the store currently needs a passphrase before it can be used.
  bool get requiresUnlock => isEncrypted && !_encryption!.isInitialized;

  Future<File> _fileFor(String name) async {
    final dir = await _directoryProvider();
    return File('${dir.path}/$name');
  }

  /// Whether an encrypted vault file already exists on disk.
  Future<bool> hasEncryptedVault() async {
    if (!isEncrypted) return false;
    return (await _fileFor(encryptedFileName)).exists();
  }

  /// Load all documents, newest first.
  ///
  /// Plain mode: an unreadable/missing file yields an empty list.
  /// Encrypted mode: decrypt/parse failures are rethrown (see class docs).
  Future<List<StoredDocument>> loadAll() async {
    if (_cache != null) return List.unmodifiable(_cache!);
    final docs = isEncrypted ? await _loadEncrypted() : await _loadPlain();
    _cache = docs;
    return List.unmodifiable(_cache!);
  }

  Future<List<StoredDocument>> _loadPlain() async {
    try {
      final file = await _fileFor(dataFileName);
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      return _parseLibrary(raw);
    } catch (e) {
      logger.e('Failed to load documents', error: e);
      return [];
    }
  }

  Future<List<StoredDocument>> _loadEncrypted() async {
    _requireUnlocked();
    final encFile = await _fileFor(encryptedFileName);

    if (await encFile.exists()) {
      final raw = (await encFile.readAsString()).trim();
      if (raw.isEmpty) return [];
      // Throws on wrong passphrase / tampering — intentionally not caught.
      final plain = await _encryption!.decrypt(raw);
      return _parseLibrary(plain);
    }

    // One-time migration from a plaintext library, if one exists.
    final plainFile = await _fileFor(dataFileName);
    if (await plainFile.exists()) {
      final docs = _parseLibrary(await plainFile.readAsString());
      await _persistEncrypted(docs);
      await plainFile.delete();
      logger.i('Migrated ${docs.length} documents into the encrypted vault');
      return docs;
    }

    return [];
  }

  List<StoredDocument> _parseLibrary(String raw) {
    if (raw.trim().isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Document library has unexpected shape');
    }
    final docs = decoded
        .whereType<Map>()
        .map((e) => StoredDocument.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
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
    if (isEncrypted) {
      await _persistEncrypted(docs);
    } else {
      final file = await _fileFor(dataFileName);
      await _writeAtomic(file, jsonEncode(docs.map((d) => d.toJson()).toList()));
    }
  }

  Future<void> _persistEncrypted(List<StoredDocument> docs) async {
    _requireUnlocked();
    final file = await _fileFor(encryptedFileName);
    final envelope =
        await _encryption!.encrypt(jsonEncode(docs.map((d) => d.toJson()).toList()));
    await _writeAtomic(file, envelope);
  }

  Future<void> _writeAtomic(File file, String contents) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(contents, flush: true);
    await tmp.rename(file.path);
  }

  void _requireUnlocked() {
    if (requiresUnlock) {
      throw StateError(
        'Document library is locked. Initialize the EncryptionService with '
        'the vault passphrase first.',
      );
    }
  }
}
