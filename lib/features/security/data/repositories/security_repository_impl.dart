import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../domain/repositories/security_repository.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  final FlutterSecureStorage secureStorage;
  final LocalAuthentication localAuth;

  static const String keyAppLockEnabled = 'security_app_lock_enabled';
  static const String keyBiometricsEnabled = 'security_biometrics_enabled';
  static const String keyPinHash = 'security_pin_hash';
  static const String keyPinSalt = 'security_pin_salt';

  SecurityRepositoryImpl({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : secureStorage = secureStorage ?? const FlutterSecureStorage(),
        localAuth = localAuth ?? LocalAuthentication();

  @override
  Future<bool> isAppLockEnabled() async {
    final value = await secureStorage.read(key: keyAppLockEnabled);
    return value == 'true';
  }

  @override
  Future<void> setAppLockEnabled(bool enabled) async {
    await secureStorage.write(
      key: keyAppLockEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    final value = await secureStorage.read(key: keyBiometricsEnabled);
    return value == 'true';
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await secureStorage.write(
      key: keyBiometricsEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  @override
  Future<bool> hasPinSet() async {
    final hash = await secureStorage.read(key: keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> setPin(String pin) async {
    final pinRegex = RegExp(r'^\d{4,6}$');
    if (!pinRegex.hasMatch(pin)) {
      throw ArgumentError('PIN must be 4 to 6 numeric digits.');
    }

    // Generate random salt
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64Encode(saltBytes);

    // Compute SHA-256 hash
    final hash = _hashPin(pin, salt);

    await secureStorage.write(key: keyPinSalt, value: salt);
    await secureStorage.write(key: keyPinHash, value: hash);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final storedHash = await secureStorage.read(key: keyPinHash);
    final salt = await secureStorage.read(key: keyPinSalt);

    if (storedHash == null || salt == null) {
      return false;
    }

    final candidateHash = _hashPin(pin, salt);
    return candidateHash == storedHash;
  }

  @override
  Future<void> clearPin() async {
    await secureStorage.delete(key: keyPinHash);
    await secureStorage.delete(key: keyPinSalt);
  }

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticateBiometrics({required String reason}) async {
    try {
      return await localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin');
    return sha256.convert(bytes).toString();
  }
}
