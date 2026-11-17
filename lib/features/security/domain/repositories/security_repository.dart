abstract class SecurityRepository {
  Future<bool> isAppLockEnabled();
  Future<void> setAppLockEnabled(bool enabled);

  Future<bool> isBiometricsEnabled();
  Future<void> setBiometricsEnabled(bool enabled);

  Future<bool> hasPinSet();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();

  Future<bool> canCheckBiometrics();
  Future<bool> authenticateBiometrics({required String reason});
}
