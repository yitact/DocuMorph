import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:documorph/models/stored_document.dart';
import 'package:documorph/services/document_store.dart';

void main() {
  group('DocumentStore', () {
    late Directory tempDir;
    late DocumentStore store;

    StoredDocument doc(
      String id,
      String title, {
      String ocrText = '',
      String? vendor,
      DateTime? createdAt,
    }) {
      return StoredDocument(
        id: id,
        title: title,
        documentType: 'scan',
        ocrText: ocrText,
        vendor: vendor,
        createdAt: createdAt ?? DateTime(2026, 10, 18, 12),
      );
    }

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('documorph_store_test');
      store = DocumentStore(directoryProvider: () async => tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('starts empty when no file exists', () async {
      expect(await store.loadAll(), isEmpty);
    });

    test('saves and loads documents, newest first', () async {
      await store.save(doc('1', 'Older',
          createdAt: DateTime(2026, 10, 17, 9)));
      await store.save(doc('2', 'Newer',
          createdAt: DateTime(2026, 10, 18, 9)));

      final docs = await store.loadAll();
      expect(docs.map((d) => d.id), ['2', '1']);
    });

    test('persists across store instances (data really hits disk)', () async {
      await store.save(doc('1', 'Receipt', ocrText: 'Total \$42.00'));

      final reopened = DocumentStore(directoryProvider: () async => tempDir);
      final docs = await reopened.loadAll();
      expect(docs, hasLength(1));
      expect(docs.single.title, 'Receipt');
      expect(docs.single.ocrText, 'Total \$42.00');
    });

    test('saving with an existing id replaces instead of duplicating',
        () async {
      await store.save(doc('1', 'First version'));
      await store.save(doc('1', 'Second version'));

      final docs = await store.loadAll();
      expect(docs, hasLength(1));
      expect(docs.single.title, 'Second version');
    });

    test('delete removes a document and reports what happened', () async {
      await store.save(doc('1', 'To delete'));
      await store.save(doc('2', 'To keep'));

      expect(await store.delete('1'), isTrue);
      expect(await store.delete('missing'), isFalse);

      final docs = await store.loadAll();
      expect(docs.map((d) => d.id), ['2']);
    });

    test('search matches title, OCR text and vendor, case-insensitively',
        () async {
      await store.save(doc('1', 'Grocery run', ocrText: 'milk and eggs'));
      await store.save(
          doc('2', 'Invoice', ocrText: 'payment due', vendor: 'Staples'));
      await store.save(doc('3', 'Lease', ocrText: 'monthly rent'));

      expect((await store.search('MILK')).map((d) => d.id), ['1']);
      expect((await store.search('staples')).map((d) => d.id), ['2']);
      expect((await store.search('invoice')).map((d) => d.id), ['2']);
      expect(await store.search('nothing-matches-this'), isEmpty);
      expect(await store.search(''), hasLength(3));
    });
  });
}
