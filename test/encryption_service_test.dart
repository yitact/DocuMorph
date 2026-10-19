import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:documorph/services/encryption_service.dart';

/// Tests run PBKDF2 at low iteration counts for speed; production uses
/// EncryptionService.defaultIterations.
const _fast = 1000;

void main() {
  group('EncryptionService v2 (AES-256-GCM + PBKDF2)', () {
    test('encrypt/decrypt round-trips plaintext', () async {
      final service = EncryptionService();
      await service.initialize('correct horse battery staple',
          iterations: _fast);

      const plaintext = 'Receipt: Harris Teeter, total \$82.41';
      final ciphertext = await service.encrypt(plaintext);

      expect(ciphertext, isNot(plaintext));
      expect(await service.decrypt(ciphertext), plaintext);
    });

    test('encryptJson/decryptJson round-trips a map', () async {
      final service = EncryptionService();
      await service.initialize('passphrase-123', iterations: _fast);

      final data = <String, dynamic>{'vendor': 'Staples', 'total': 129.99};
      final encrypted = await service.encryptJson(data);
      final decrypted = await service.decryptJson(encrypted);

      expect(decrypted['vendor'], 'Staples');
      expect(decrypted['total'], 129.99);
    });

    test('ciphertext is a versioned envelope with KDF parameters', () async {
      final service = EncryptionService();
      await service.initialize('passphrase', iterations: _fast);

      final ciphertext = await service.encrypt('hello');
      final envelope =
          jsonDecode(utf8.decode(base64Decode(ciphertext))) as Map;

      expect(envelope['v'], EncryptionService.envelopeVersion);
      expect(envelope['iter'], _fast);
      expect(envelope['salt'], isNotEmpty);
      expect(envelope['nonce'], isNotEmpty);
      expect(envelope['mac'], isNotEmpty);
      expect(envelope['ct'], isNotEmpty);
    });

    test('same passphrase on a fresh instance decrypts (envelope is portable)',
        () async {
      final writer = EncryptionService();
      await writer.initialize('shared passphrase', iterations: _fast);
      final ciphertext = await writer.encrypt('portable secret');

      // A different instance has a different vault salt, yet must decrypt,
      // because the envelope carries its own salt/iterations.
      final reader = EncryptionService();
      await reader.initialize('shared passphrase', iterations: _fast);
      expect(reader.saltBase64, isNot(writer.saltBase64));
      expect(await reader.decrypt(ciphertext), 'portable secret');
    });

    test('salts are random per vault (same passphrase, different keys)',
        () async {
      final a = EncryptionService();
      await a.initialize('same passphrase', iterations: _fast);
      final b = EncryptionService();
      await b.initialize('same passphrase', iterations: _fast);

      expect(a.saltBase64, isNot(b.saltBase64));
      // And identical plaintext encrypts to different envelopes (random
      // salt + random GCM nonce).
      expect(await a.encrypt('data'), isNot(await b.encrypt('data')));
    });

    test('a wrong passphrase cannot decrypt', () async {
      final writer = EncryptionService();
      await writer.initialize('right passphrase', iterations: _fast);
      final ciphertext = await writer.encrypt('secret');

      final reader = EncryptionService();
      await reader.initialize('wrong passphrase', iterations: _fast);
      await expectLater(reader.decrypt(ciphertext), throwsA(anything));
    });

    test('tampering with the ciphertext is detected (GCM authentication)',
        () async {
      final service = EncryptionService();
      await service.initialize('passphrase', iterations: _fast);
      final ciphertext = await service.encrypt('important data');

      final envelope =
          jsonDecode(utf8.decode(base64Decode(ciphertext))) as Map<String, dynamic>;
      final ctBytes = base64Decode(envelope['ct'] as String);
      ctBytes[0] = ctBytes[0] ^ 0xFF; // flip every bit in the first byte
      envelope['ct'] = base64Encode(ctBytes);
      final tampered = base64Encode(utf8.encode(jsonEncode(envelope)));

      await expectLater(service.decrypt(tampered), throwsA(anything));
    });

    test('changePassphrase rejects the wrong current passphrase', () async {
      final service = EncryptionService();
      await service.initialize('old passphrase', iterations: _fast);

      await expectLater(
        service.changePassphrase('not the old one', 'new passphrase'),
        throwsA(anything),
      );
    });

    test('changePassphrase rotates the salt and invalidates old ciphertext',
        () async {
      final service = EncryptionService();
      await service.initialize('old passphrase', iterations: _fast);
      final saltBefore = service.saltBase64;
      final before = await service.encrypt('data');

      await service.changePassphrase('old passphrase', 'new passphrase');

      expect(service.saltBase64, isNot(saltBefore));
      final after = await service.encrypt('data');
      expect(await service.decrypt(after), 'data');
      await expectLater(service.decrypt(before), throwsA(anything));
    });

    test('hashData/verifyHash still work', () async {
      final service = EncryptionService();
      await service.initialize('passphrase', iterations: _fast);
      final hash = service.hashData('documorph');
      expect(service.verifyHash('documorph', hash), isTrue);
      expect(service.verifyHash('tampered', hash), isFalse);
    });

    test('generateRandomString returns alphanumeric strings of any length',
        () async {
      final service = EncryptionService();
      await service.initialize('passphrase', iterations: _fast);
      for (final length in [8, 32, 64, 100]) {
        final value = service.generateRandomString(length);
        expect(value.length, length);
        expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value), isTrue);
      }
    });

    test('default iteration count is production-strength', () {
      expect(
        EncryptionService.defaultIterations,
        greaterThanOrEqualTo(100000),
      );
    });
  });
}
