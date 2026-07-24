import 'package:local_auth/local_auth.dart';

/// Wraps the device local authentication system (fingerprint/face recognition)
/// for authorizing access to saved account credentials.
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Checks if hardware biometrics can be checked and are supported on the host device.
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Triggers a biometric prompt to authorize unlocking saved credentials.
  Future<bool> unlockSavedCredentials() async {
    return _authenticate('Unlock saved credentials for Crowley\'s Cloud.');
  }

  /// Internal helper invoking native device biometrics with fallback protection.
  Future<bool> _authenticate(String reason) async {
    if (!await canAuthenticate()) return false;
    try {
      return _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

