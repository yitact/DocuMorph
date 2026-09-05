import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Service for biometric authentication management
class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  bool _isAuthenticated = false;

  /// Initialize and check biometric availability
  Future<void> initialize() async {
    try {
      _isBiometricAvailable = await _localAuth.canCheckBiometrics;
      final canUseDeviceCredential = await _localAuth.deviceSupportsBiometrics;
      
      _isBiometricAvailable =
          _isBiometricAvailable || canUseDeviceCredential;
      
      logger.i(
        'AuthService initialized - Biometric available: $_isBiometricAvailable',
      );
    } catch (e) {
      logger.e('Failed to initialize AuthService', error: e);
      _isBiometricAvailable = false;
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric({
    required String reason,
    bool sensitiveTransaction = false,
  }) async {
    try {
      if (!_isBiometricAvailable) {
        logger.w('Biometric not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !sensitiveTransaction,
          useErrorDialogs: true,
        ),
      );

      _isAuthenticated = authenticated;
      logger.i('Biometric authentication: ${authenticated ? 'success' : 'failed'}');
      return authenticated;
    } catch (e) {
      logger.e('Biometric authentication error', error: e);
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      logger.e('Failed to get available biometrics', error: e);
      return [];
    }
  }

  /// Check if biometric is enrolled
  Future<bool> isBiometricEnrolled() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return canCheckBiometrics;
    } catch (e) {
      logger.e('Failed to check biometric enrollment', error: e);
      return false;
    }
  }

  /// Check if currently authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Check if biometric is available
  bool get isBiometricAvailable => _isBiometricAvailable;

  /// Reset authentication state
  void resetAuthentication() {
    _isAuthenticated = false;
    logger.i('Authentication state reset');
  }

  /// Stop any ongoing biometric operations
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      logger.i('Biometric operations stopped');
    } catch (e) {
      logger.e('Failed to stop authentication', error: e);
    }
  }
}
