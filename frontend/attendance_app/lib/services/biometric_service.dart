import 'package:local_auth/local_auth.dart';

/// Handles on-device biometric authentication (fingerprint / face).
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if a hardware biometric sensor is present and enrolled.
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) return false;

    final available = await _localAuth.getAvailableBiometrics();
    return available.contains(BiometricType.fingerprint) ||
        available.contains(BiometricType.face) ||
        available.contains(BiometricType.strong);
  }

  /// Prompt the user for biometric authentication.
  /// Returns `true` if authentication succeeds.
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirm your identity to mark attendance',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
