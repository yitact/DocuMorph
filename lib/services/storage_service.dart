//
// Copyright (c) 2026 Samuel. All rights reserved.
// Developed by Samuel with AI assistance.
//

import 'package:hive_flutter/hive_flutter.dart';
import '../models/stored_document.dart';

class StorageService {
  static const String boxName = 'documents';
  late Box<Map> _box;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(boxName);
  }

  Future<void> saveDocument(StoredDocument doc) async {
    await _box.put(doc.id, doc.toJson() as Map);
  }

  Future<StoredDocument?> getDocument(String id) async {
    final data = _box.get(id);
    if (data == null) return null;
    return StoredDocument.fromJson(data.cast<String, dynamic>());
  }

  Future<List<StoredDocument>> getAllDocuments() async {
    final docs = <StoredDocument>[];
    for (final value in _box.values) {
      docs.add(StoredDocument.fromJson(value.cast<String, dynamic>()));
    }
    return docs;
  }

  Future<List<StoredDocument>> searchDocuments(String query) async {
    final allDocs = await getAllDocuments();
    return allDocs
        .where((doc) =>
            doc.title.toLowerCase().contains(query.toLowerCase()) ||
            doc.ocrText.toLowerCase().contains(query.toLowerCase()) ||
            doc.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<StoredDocument>> getDocumentsByCategory(String category) async {
    final allDocs = await getAllDocuments();
    return allDocs.where((doc) => doc.category == category).toList();
  }

  Future<void> deleteDocument(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<int> getDocumentCount() async {
    return _box.length;
  }
}
