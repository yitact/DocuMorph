import 'package:flutter_test/flutter_test.dart';
import 'package:documorph/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    test('encrypt/decrypt round-trips plaintext', () async {
      final service = EncryptionService();
      await service.initialize('correct horse battery staple');

      const plaintext = 'Receipt: Harris Teeter, total \$82.41';
      final ciphertext = service.encrypt(plaintext);

      expect(ciphertext, isNot(plaintext));
      expect(service.decrypt(ciphertext), plaintext);
    });

    test('encryptJson/decryptJson round-trips a map', () async {
      final service = EncryptionService();
      await service.initialize('passphrase-123');

      final data = <String, dynamic>{'vendor': 'Staples', 'total': 129.99};
      final encrypted = service.encryptJson(data);
      final decrypted = service.decryptJson(encrypted);

      expect(decrypted['vendor'], 'Staples');
      expect(decrypted['total'], 129.99);
    });

    test('a different passphrase cannot decrypt', () async {
      final writer = EncryptionService();
      await writer.initialize('right passphrase');
      final ciphertext = writer.encrypt('secret');

      final reader = EncryptionService();
      await reader.initialize('wrong passphrase');
      expect(() => reader.decrypt(ciphertext), throwsA(anything));
    });

    test('changePassphrase rejects the wrong current passphrase', () async {
      final service = EncryptionService();
      await service.initialize('old passphrase');

      expect(
        () => service.changePassphrase('not the old one', 'new passphrase'),
        throwsA(anything),
      );
    });

    test('changePassphrase accepts the correct current passphrase', () async {
      final service = EncryptionService();
      await service.initialize('old passphrase');
      final before = service.encrypt('data');

      await service.changePassphrase('old passphrase', 'new passphrase');
      final after = service.encrypt('data');

      expect(service.decrypt(after), 'data');
      expect(() => service.decrypt(before), throwsA(anything));
    });
  });
}
