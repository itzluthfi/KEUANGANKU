import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._privateConstructor();
  static final BiometricService instance = BiometricService._privateConstructor();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Memeriksa apakah hardware perangkat mendukung keamanan biometrik
  Future<bool> isBiometricSupported() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool hasBiometrics = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && hasBiometrics;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Memeriksa tipe biometrik yang tersedia (sidik jari, wajah, dll)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  /// Memicu dialog autentikasi biometrik native
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari atau wajah Anda untuk membuka kunci Danaku',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
