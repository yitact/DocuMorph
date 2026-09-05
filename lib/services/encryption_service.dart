import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:logger/logger.dart';

final logger = Logger();

/// Service for client-side AES-256-GCM encryption
class EncryptionService {
  late enc.Key _encryptionKey;
  bool _isInitialized = false;

  /// Initialize with a passphrase
  Future<void> initialize(String passphrase, {String? salt}) async {
    try {
      final saltValue = salt ?? 'documorph_default_salt_2026';
      
      // Derive key from passphrase using PBKDF2-like approach
      _encryptionKey = enc.Key.fromUtf8(
        _deriveKey(passphrase, saltValue),
      );
      
      _isInitialized = true;
      logger.i('EncryptionService initialized');
    } catch (e) {
      logger.e('Failed to initialize EncryptionService', error: e);
      rethrow;
    }
  }

  /// Encrypt plaintext
  String encrypt(String plaintext) {
    try {
      _checkInitialized();
      
      final iv = enc.IV.fromSecureRandom(16);
      final cipher = enc.Fernet(_encryptionKey);
      
      final encrypted = cipher.encrypt(plaintext, iv: iv);
      
      logger.i('Data encrypted: ${plaintext.length} chars -> ${encrypted.base64.length} chars');
      return encrypted.base64;
    } catch (e) {
      logger.e('Encryption failed', error: e);
      rethrow;
    }
  }

  /// Decrypt ciphertext
  String decrypt(String ciphertext) {
    try {
      _checkInitialized();
      
      final cipher = enc.Fernet(_encryptionKey);
      final decrypted = cipher.decrypt(ciphertext);
      
      logger.i('Data decrypted: ${ciphertext.length} chars -> ${decrypted.length} chars');
      return decrypted;
    } catch (e) {
      logger.e('Decryption failed', error: e);
      rethrow;
    }
  }

  /// Encrypt JSON object
  String encryptJson(Map<String, dynamic> json) {
    try {
      final jsonString = jsonEncode(json);
      return encrypt(jsonString);
    } catch (e) {
      logger.e('JSON encryption failed', error: e);
      rethrow;
    }
  }

  /// Decrypt JSON object
  Map<String, dynamic> decryptJson(String ciphertext) {
    try {
      final decrypted = decrypt(ciphertext);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      logger.e('JSON decryption failed', error: e);
      rethrow;
    }
  }

  /// Hash data for verification
  String hashData(String data) {
    try {
      final hash = sha256.convert(utf8.encode(data));
      return hash.toString();
    } catch (e) {
      logger.e('Hashing failed', error: e);
      rethrow;
    }
  }

  /// Verify hashed data
  bool verifyHash(String data, String hash) {
    try {
      return hashData(data) == hash;
    } catch (e) {
      logger.e('Hash verification failed', error: e);
      return false;
    }
  }

  /// Generate secure random string
  String generateRandomString(int length) {
    try {
      final randomBytes = enc.Key.fromSecureRandom(length);
      return base64Encode(randomBytes.bytes).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').substring(0, length);
    } catch (e) {
      logger.e('Random string generation failed', error: e);
      rethrow;
    }
  }

  /// Derive encryption key from passphrase
  String _deriveKey(String passphrase, String salt) {
    // Simple PBKDF2-like key derivation
    var key = passphrase + salt;
    for (var i = 0; i < 1000; i++) {
      key = sha256.convert(utf8.encode(key)).toString();
    }
    return key.substring(0, 32); // 256-bit key
  }

  /// Check if service is initialized
  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('EncryptionService not initialized. Call initialize() first.');
    }
  }

  /// Change passphrase
  Future<void> changePassphrase(String oldPassphrase, String newPassphrase) async {
    try {
      _checkInitialized();
      
      // Verify old passphrase
      final oldKey = _deriveKey(oldPassphrase, 'documorph_default_salt_2026');
      if (oldKey != _encryptionKey.base64) {
        throw Exception('Invalid current passphrase');
      }
      
      // Set new passphrase
      _encryptionKey = enc.Key.fromUtf8(
        _deriveKey(newPassphrase, 'documorph_default_salt_2026'),
      );
      
      logger.i('Passphrase changed successfully');
    } catch (e) {
      logger.e('Failed to change passphrase', error: e);
      rethrow;
    }
  }
}
