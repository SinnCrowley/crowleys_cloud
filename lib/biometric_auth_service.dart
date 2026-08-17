// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
