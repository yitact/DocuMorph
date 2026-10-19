import 'package:flutter/material.dart';

import '../services/document_store.dart';
import '../services/encryption_service.dart';

/// Passphrase gate for the encrypted document library.
///
/// Two modes, decided by whether a vault already exists on disk:
/// - **Create**: first run — the user picks a passphrase (entered twice).
/// - **Unlock**: a vault exists — the passphrase is verified by actually
///   attempting to decrypt the library; a wrong one is rejected here.
///
/// Pops with `true` when the library is unlocked and readable.
class UnlockLibraryScreen extends StatefulWidget {
  final DocumentStore store;
  final EncryptionService encryption;

  /// PBKDF2 iterations to use when initializing. Production leaves the
  /// service default; tests pass a small number for speed.
  final int iterations;

  const UnlockLibraryScreen({
    super.key,
    required this.store,
    required this.encryption,
    this.iterations = EncryptionService.defaultIterations,
  });

  @override
  State<UnlockLibraryScreen> createState() => _UnlockLibraryScreenState();
}

class _UnlockLibraryScreenState extends State<UnlockLibraryScreen> {
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  bool? _vaultExists;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.store.hasEncryptedVault().then((exists) {
      if (mounted) setState(() => _vaultExists = exists);
    });
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isCreateMode => _vaultExists == false;

  Future<void> _submit() async {
    final passphrase = _passphraseController.text;
    if (passphrase.isEmpty) {
      setState(() => _error = 'Enter a passphrase.');
      return;
    }
    if (_isCreateMode && passphrase != _confirmController.text) {
      setState(() => _error = 'Passphrases do not match.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    widget.encryption.lock();
    await widget.encryption.initialize(
      passphrase,
      iterations: widget.iterations,
    );
    try {
      // Verification: actually read the library. In unlock mode a wrong
      // passphrase fails GCM authentication here. In create mode this also
      // runs the plaintext migration when an old library exists.
      await widget.store.loadAll();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      widget.encryption.lock();
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Wrong passphrase — the library could not be decrypted.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = _isCreateMode;
    return Scaffold(
      appBar: AppBar(title: const Text('Document Library')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _vaultExists == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    creating ? Icons.lock_outline : Icons.lock,
                    size: 48,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    creating
                        ? 'Create a passphrase to encrypt your library'
                        : 'Enter your passphrase to unlock your library',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    creating
                        ? 'Your scans will be encrypted on this device with '
                            'AES-256-GCM. If you forget this passphrase, '
                            'the library cannot be recovered.'
                        : 'Your library is encrypted on this device. '
                            'It stays locked until you enter the passphrase.',
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('passphrase_field'),
                    controller: _passphraseController,
                    obscureText: true,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Passphrase',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (creating) ...[
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('confirm_passphrase_field'),
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm passphrase',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('unlock_button'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(creating ? 'Create & Encrypt' : 'Unlock'),
                  ),
                ],
              ),
      ),
    );
  }
}
