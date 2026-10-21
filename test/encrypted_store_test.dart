import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:documorph/models/stored_document.dart';
import 'package:documorph/services/document_store.dart';
import 'package:documorph/services/encryption_service.dart';

void main() {
  group('DocumentStore (encrypted at rest)', () {
    late Directory tempDir;

    const passphrase = 'vault passphrase 42';
    const secretText = 'SECRET: account 123456, total \$9,999';

    StoredDocument sampleDoc() => StoredDocument(
          id: 'doc-1',
          title: 'Private invoice',
          documentType: 'scan',
          ocrText: secretText,
          createdAt: DateTime(2026, 10, 18, 20, 0),
        );

    Future<EncryptionService> unlockedService([String pw = passphrase]) async {
      final service = EncryptionService();
      await service.initialize(pw, iterations: 1000);
      return service;
    }

    DocumentStore encryptedStore(EncryptionService service) => DocumentStore(
          directoryProvider: () async => tempDir,
          encryption: service,
        );

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('documorph_encrypted_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saved library is not readable as plaintext on disk', () async {
      final store = encryptedStore(await unlockedService());
      await store.save(sampleDoc());

      final encFile = File('${tempDir.path}/${DocumentStore.encryptedFileName}');
      expect(await encFile.exists(), isTrue);
      final onDisk = await encFile.readAsString();
      expect(onDisk.contains('SECRET'), isFalse);
      expect(onDisk.contains('Private invoice'), isFalse);

      final plainFile = File('${tempDir.path}/${DocumentStore.dataFileName}');
      expect(await plainFile.exists(), isFalse);
    });

    test('a fresh instance with the same passphrase reads the library',
        () async {
      await encryptedStore(await unlockedService()).save(sampleDoc());

      final reopened = encryptedStore(await unlockedService());
      final docs = await reopened.loadAll();
      expect(docs, hasLength(1));
      expect(docs.single.ocrText, secretText);
    });

    test('a wrong passphrase fails loudly instead of returning empty',
        () async {
      await encryptedStore(await unlockedService()).save(sampleDoc());

      final wrong = encryptedStore(await unlockedService('not the passphrase'));
      await expectLater(wrong.loadAll(), throwsA(anything));
    });

    test('a locked (uninitialized) service throws StateError', () async {
      final store = encryptedStore(EncryptionService());
      expect(store.requiresUnlock, isTrue);
      await expectLater(store.loadAll(), throwsStateError);
      await expectLater(store.save(sampleDoc()), throwsStateError);
    });

    test('tampering with the vault file is detected on load', () async {
      await encryptedStore(await unlockedService()).save(sampleDoc());

      final encFile = File('${tempDir.path}/${DocumentStore.encryptedFileName}');
      final raw = await encFile.readAsString();
      // Flip a character in the middle of the envelope payload.
      final mid = raw.length ~/ 2;
      final replacement = raw[mid] == 'A' ? 'B' : 'A';
      await encFile.writeAsString(
        raw.substring(0, mid) + replacement + raw.substring(mid + 1),
      );

      final reopened = encryptedStore(await unlockedService());
      await expectLater(reopened.loadAll(), throwsA(anything));
    });

    test('plaintext library from plain mode migrates into the vault',
        () async {
      // Seed a plaintext library the way step-2 plain mode wrote it.
      final plainFile = File('${tempDir.path}/${DocumentStore.dataFileName}');
      await plainFile.writeAsString(jsonEncode([sampleDoc().toJson()]));

      final store = encryptedStore(await unlockedService());
      final docs = await store.loadAll();

      expect(docs, hasLength(1));
      expect(docs.single.ocrText, secretText);

      // Migration moved the data: vault exists, plaintext is gone.
      final encFile = File('${tempDir.path}/${DocumentStore.encryptedFileName}');
      expect(await encFile.exists(), isTrue);
      expect(await plainFile.exists(), isFalse);
      expect((await encFile.readAsString()).contains('SECRET'), isFalse);

      // And the migrated vault opens with the same passphrase.
      final reopened = encryptedStore(await unlockedService());
      expect(await reopened.loadAll(), hasLength(1));
    });
  });
}
