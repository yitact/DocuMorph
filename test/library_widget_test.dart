import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:documorph/main.dart';
import 'package:documorph/models/stored_document.dart';
import 'package:documorph/services/document_store.dart';
import 'package:documorph/services/ocr_service.dart';

class _StubOcrService implements OcrService {
  @override
  Future<String> recognizeText(File imageFile) async => 'stub';
  @override
  void dispose() {}
}

/// Real file IO cannot be awaited directly inside a testWidgets body (it
/// runs in a fake-async zone and the future would never complete), so all
/// IO setup runs through tester.runAsync. After an interaction, the store's
/// future needs several alternating real-async windows and framework pumps
/// to deliver its result into the widget tree — loop until the expected
/// widget appears (or give up after ~2 seconds of real time).
Future<void> _pumpAndLetIoRun(
  WidgetTester tester, {
  required bool Function() until,
}) async {
  for (var i = 0; i < 40 && !until(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('library shows saved documents and opens their text',
      (WidgetTester tester) async {
    late Directory tempDir;
    late DocumentStore store;

    await tester.runAsync(() async {
      tempDir =
          await Directory.systemTemp.createTemp('documorph_library_test');
      // Seed the store's data file synchronously (sync IO is safe here).
      final seed = StoredDocument(
        id: 'doc-1',
        title: 'Invoice #1042',
        documentType: 'scan',
        ocrText: 'Invoice #1042\nTotal Due: \$450.00',
        createdAt: DateTime(2026, 10, 18, 15, 30),
      );
      File('${tempDir.path}/${DocumentStore.dataFileName}')
          .writeAsStringSync(jsonEncode([seed.toJson()]));
      store = DocumentStore(directoryProvider: () async => tempDir);
    });
    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      DocumentScannerApp(ocrService: _StubOcrService(), documentStore: store),
    );
    await tester.pump();

    expect(find.byKey(const Key('library_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('library_button')));
    await _pumpAndLetIoRun(
      tester,
      until: () => tester.any(find.text('Invoice #1042')),
    );

    expect(find.text('Saved Documents'), findsOneWidget);
    expect(find.text('Invoice #1042'), findsOneWidget);

    await tester.tap(find.text('Invoice #1042'));
    await _pumpAndLetIoRun(
      tester,
      until: () => tester.any(find.textContaining('Total Due')),
    );

    expect(find.textContaining('Total Due'), findsOneWidget);
  });

  testWidgets('library shows an empty state when nothing is saved',
      (WidgetTester tester) async {
    late Directory tempDir;
    late DocumentStore store;

    await tester.runAsync(() async {
      tempDir =
          await Directory.systemTemp.createTemp('documorph_library_empty');
      store = DocumentStore(directoryProvider: () async => tempDir);
    });
    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      DocumentScannerApp(ocrService: _StubOcrService(), documentStore: store),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('library_button')));
    await _pumpAndLetIoRun(
      tester,
      until: () => tester.any(find.textContaining('No saved documents yet')),
    );

    expect(find.textContaining('No saved documents yet'), findsOneWidget);
  });
}
