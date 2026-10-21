import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:documorph/main.dart';
import 'package:documorph/services/document_store.dart';
import 'package:documorph/services/encryption_service.dart';
import 'package:documorph/services/ocr_service.dart';

class _StubOcrService implements OcrService {
  @override
  Future<String> recognizeText(File imageFile) async => 'stub';
  @override
  void dispose() {}
}

/// Alternates real-async windows (for file IO and PBKDF2) with framework
/// pumps until [until] reports the expected widget, or gives up.
Future<void> _pumpUntil(
  WidgetTester tester, {
  required bool Function() until,
  int attempts = 80,
}) async {
  for (var i = 0; i < attempts && !until(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('library stays gated until a passphrase is created',
      (WidgetTester tester) async {
    late Directory tempDir;
    late DocumentStore store;
    final encryption = EncryptionService();

    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('documorph_gate_test');
      store = DocumentStore(
        directoryProvider: () async => tempDir,
        encryption: encryption,
      );
    });
    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      DocumentScannerApp(
        ocrService: _StubOcrService(),
        documentStore: store,
        encryptionService: encryption,
        unlockIterations: 1000, // fast PBKDF2 for tests; app default is 210k
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('library_button')));
    await _pumpUntil(
      tester,
      until: () => tester.any(find.textContaining('Create a passphrase')),
    );
    expect(find.textContaining('Create a passphrase'), findsOneWidget);
    expect(find.text('Saved Documents'), findsNothing);

    await tester.enterText(
        find.byKey(const Key('passphrase_field')), 'gate-pass-123');
    await tester.enterText(
        find.byKey(const Key('confirm_passphrase_field')), 'gate-pass-123');
    await tester.tap(find.byKey(const Key('unlock_button')));

    await _pumpUntil(
      tester,
      until: () => tester.any(find.text('Saved Documents')),
    );
    expect(find.text('Saved Documents'), findsOneWidget);
    expect(find.textContaining('No saved documents yet'), findsOneWidget);
    expect(encryption.isInitialized, isTrue);
  });
}
