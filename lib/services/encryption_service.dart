import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' hide Hmac;
import 'package:cryptography/cryptography.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Client-side encryption service — v2 (rewritten 2026-10-18).
///
/// What it actually does (no marketing gloss):
/// - Cipher: **AES-256-GCM** (authenticated encryption) via the
///   `cryptography` package. Tampering with a ciphertext makes decryption
///   fail instead of returning corrupted plaintext.
/// - Key derivation: **PBKDF2-HMAC-SHA256**, [defaultIterations] rounds,
///   256-bit key, from the user's passphrase.
/// - Salt: 16 cryptographically random bytes per vault — NOT a shared
///   hardcoded value. Same passphrase on two devices produces different
///   keys.
/// - Ciphertext format: a versioned, self-describing envelope. `encrypt`
///   returns base64 of a JSON object:
///   `{v, iter, salt, nonce, mac, ct}` (all values base64 except `v`/`iter`).
///   Because KDF parameters and the nonce travel with the ciphertext, any
///   instance initialized with the correct passphrase can decrypt it, and
///   parameters can be upgraded later without breaking old data.
///
/// Breaking change vs v1: v1 used Fernet (AES-128-CBC) with a hardcoded
/// salt and an iterated-SHA256 KDF. v1 ciphertexts cannot be decrypted by
/// this implementation. Acceptable because v1 never shipped and cloud sync
/// was never initialized against real data.
///
/// Note: `encrypt`/`decrypt` are async (the cryptography APIs are), unlike
/// v1's synchronous wrappers.
class EncryptionService {
  static const int envelopeVersion = 2;
  static const int defaultIterations = 210000;
  static const int saltLengthBytes = 16;

  final AesGcm _algorithm = AesGcm.with256bits();
  final Random _secureRandom = Random.secure();

  SecretKey? _key;
  List<int>? _salt;
  int _iterations = defaultIterations;

  /// The current passphrase, held in memory only (never persisted) so that
  /// envelopes carrying older KDF parameters can be re-derived on decrypt.
  String? _passphrase;

  bool get _isInitialized => _key != null;

  /// Whether [initialize] has completed and the service can encrypt/decrypt.
  bool get isInitialized => _isInitialized;

  /// Lock the vault: forget the derived key and the in-memory passphrase.
  /// The next encrypt/decrypt will throw until [initialize] is called again.
  void lock() {
    _key = null;
    _passphrase = null;
    _salt = null;
    logger.i('EncryptionService locked');
  }

  /// The vault salt (base64) in use. Persist this alongside the account so
  /// the vault can be re-derived after passphrase changes; note individual
  /// ciphertext envelopes also carry their own salt, so decryption does not
  /// depend on this value being restored first.
  String get saltBase64 {
    _checkInitialized();
    return base64Encode(_salt!);
  }

  int get iterations => _iterations;

  /// Initialize with a passphrase.
  ///
  /// [salt] is a base64-encoded salt to reuse (e.g., restored from storage);
  /// when omitted, a fresh random salt is generated. [iterations] overrides
  /// the PBKDF2 cost — production code should leave the default; the
  /// parameter exists mainly so tests can run fast.
  Future<void> initialize(
    String passphrase, {
    String? salt,
    int iterations = defaultIterations,
  }) async {
    try {
      _salt = salt != null
          ? base64Decode(salt)
          : List<int>.generate(
              saltLengthBytes,
              (_) => _secureRandom.nextInt(256),
            );
      _iterations = iterations;
      _passphrase = passphrase;
      _key = await _deriveKey(passphrase, _salt!, _iterations);
      logger.i('EncryptionService initialized (AES-256-GCM, PBKDF2 x$_iterations)');
    } catch (e) {
      logger.e('Failed to initialize EncryptionService', error: e);
      rethrow;
    }
  }

  Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt,
    int iterations,
  ) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  /// Encrypt plaintext; returns the base64 envelope string.
  Future<String> encrypt(String plaintext) async {
    _checkInitialized();
    try {
      final box = await _algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: _key!,
      );
      final envelope = <String, dynamic>{
        'v': envelopeVersion,
        'iter': _iterations,
        'salt': base64Encode(_salt!),
        'nonce': base64Encode(box.nonce),
        'mac': base64Encode(box.mac.bytes),
        'ct': base64Encode(box.cipherText),
      };
      final encoded = base64Encode(utf8.encode(jsonEncode(envelope)));
      logger.i('Data encrypted: ${plaintext.length} chars -> ${encoded.length} chars');
      return encoded;
    } catch (e) {
      logger.e('Encryption failed', error: e);
      rethrow;
    }
  }

  /// Decrypt a base64 envelope produced by [encrypt].
  ///
  /// Uses the salt/iterations stored in the envelope, so it succeeds on any
  /// instance initialized with the same passphrase. Throws on a wrong
  /// passphrase or on any tampering (GCM authentication failure).
  Future<String> decrypt(String ciphertext) async {
    _checkInitialized();
    try {
      final envelope =
          jsonDecode(utf8.decode(base64Decode(ciphertext))) as Map<String, dynamic>;
      if (envelope['v'] != envelopeVersion) {
        throw Exception('Unsupported ciphertext version: ${envelope['v']}');
      }
      final salt = base64Decode(envelope['salt'] as String);
      final iter = (envelope['iter'] as num).toInt();
      // Re-derive the key for this envelope's parameters using the current
      // passphrase. _key was derived from the same passphrase, so when the
      // envelope matches the vault parameters this is the same key; deriving
      // per-envelope keeps old parameters decryptable after upgrades.
      final key = await _deriveKeyFromCurrentPassphrase(salt, iter);
      final box = SecretBox(
        base64Decode(envelope['ct'] as String),
        nonce: base64Decode(envelope['nonce'] as String),
        mac: Mac(base64Decode(envelope['mac'] as String)),
      );
      final clear = await _algorithm.decrypt(box, secretKey: key);
      final plaintext = utf8.decode(clear);
      logger.i('Data decrypted: ${ciphertext.length} chars -> ${plaintext.length} chars');
      return plaintext;
    } catch (e) {
      logger.e('Decryption failed', error: e);
      rethrow;
    }
  }

  Future<SecretKey> _deriveKeyFromCurrentPassphrase(
    List<int> salt,
    int iterations,
  ) {
    return _deriveKey(_passphrase!, salt, iterations);
  }

  /// Encrypt a JSON object; returns the base64 envelope string.
  Future<String> encryptJson(Map<String, dynamic> json) {
    return encrypt(jsonEncode(json));
  }

  /// Decrypt a base64 envelope back into a JSON object.
  Future<Map<String, dynamic>> decryptJson(String ciphertext) async {
    final decrypted = await decrypt(ciphertext);
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }

  /// Hash data for verification (integrity checksums, not passwords).
  String hashData(String data) {
    final hash = sha256.convert(utf8.encode(data));
    return hash.toString();
  }

  /// Verify hashed data.
  bool verifyHash(String data, String hash) {
    return hashData(data) == hash;
  }

  /// Generate a cryptographically random alphanumeric string.
  String generateRandomString(int length) {
    final buffer = StringBuffer();
    while (buffer.length < length) {
      final bytes = List<int>.generate(24, (_) => _secureRandom.nextInt(256));
      buffer.write(base64UrlEncode(bytes).replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''));
    }
    return buffer.toString().substring(0, length);
  }

  /// Change the vault passphrase. Verifies the current passphrase first
  /// (a wrong one throws), then rotates to a fresh random salt and the
  /// current default iteration count.
  Future<void> changePassphrase(
    String oldPassphrase,
    String newPassphrase,
  ) async {
    _checkInitialized();
    try {
      final oldKey = await _deriveKey(oldPassphrase, _salt!, _iterations);
      final oldBytes = await oldKey.extractBytes();
      final currentBytes = await _key!.extractBytes();
      if (!_constantTimeEquals(oldBytes, currentBytes)) {
        throw Exception('Invalid current passphrase');
      }

      _salt = List<int>.generate(
        saltLengthBytes,
        (_) => _secureRandom.nextInt(256),
      );
      _iterations = defaultIterations;
      _passphrase = newPassphrase;
      _key = await _deriveKey(newPassphrase, _salt!, _iterations);
      logger.i('Passphrase changed successfully (salt rotated)');
    } catch (e) {
      logger.e('Failed to change passphrase', error: e);
      rethrow;
    }
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('EncryptionService not initialized. Call initialize() first.');
    }
  }
}
