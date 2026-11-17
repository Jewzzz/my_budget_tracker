import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/security_repository.dart';
import 'security_state.dart';

class SecurityCubit extends Cubit<SecurityState> {
  final SecurityRepository _securityRepository;

  SecurityCubit(this._securityRepository) : super(const SecurityState.initial());

  Future<void> initialize() async {
    final isAppLock = await _securityRepository.isAppLockEnabled();
    final hasPin = await _securityRepository.hasPinSet();
    final isBio = await _securityRepository.isBiometricsEnabled();
    final canBio = await _securityRepository.canCheckBiometrics();

    final shouldLock = isAppLock && hasPin;

    emit(
      SecurityState(
        isInitialized: true,
        isAppLockEnabled: isAppLock,
        hasPinSet: hasPin,
        isBiometricsEnabled: isBio,
        isBiometricsAvailable: canBio,
        isLocked: shouldLock,
      ),
    );
  }

  void lockApp() {
    if (state.isAppLockEnabled && state.hasPinSet && !state.isLocked) {
      emit(state.copyWith(isLocked: true, clearError: true));
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    final isValid = await _securityRepository.verifyPin(pin);
    if (isValid) {
      emit(state.copyWith(isLocked: false, clearError: true));
      return true;
    } else {
      emit(state.copyWith(
        isLocked: true,
        errorMessage: 'Incorrect PIN. Please try again.',
      ));
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    final success = await _securityRepository.authenticateBiometrics(
      reason: 'Authenticate to unlock Budget Tracker',
    );
    if (success) {
      emit(state.copyWith(isLocked: false, clearError: true));
      return true;
    } else {
      emit(state.copyWith(
        errorMessage: 'Biometric authentication failed.',
      ));
      return false;
    }
  }

  Future<void> enableAppLock(String pin, {bool enableBiometrics = false}) async {
    await _securityRepository.setPin(pin);
    await _securityRepository.setAppLockEnabled(true);
    if (enableBiometrics) {
      await _securityRepository.setBiometricsEnabled(true);
    }

    emit(state.copyWith(
      isInitialized: true,
      isAppLockEnabled: true,
      hasPinSet: true,
      isBiometricsEnabled: enableBiometrics,
      isLocked: false,
      clearError: true,
    ));
  }

  Future<bool> disableAppLock(String pin) async {
    final isValid = await _securityRepository.verifyPin(pin);
    if (!isValid) {
      emit(state.copyWith(errorMessage: 'Incorrect PIN. Cannot disable app lock.'));
      return false;
    }

    await _securityRepository.setAppLockEnabled(false);
    await _securityRepository.setBiometricsEnabled(false);
    await _securityRepository.clearPin();

    emit(state.copyWith(
      isAppLockEnabled: false,
      hasPinSet: false,
      isBiometricsEnabled: false,
      isLocked: false,
      clearError: true,
    ));
    return true;
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    final isValid = await _securityRepository.verifyPin(oldPin);
    if (!isValid) {
      emit(state.copyWith(errorMessage: 'Incorrect current PIN.'));
      return false;
    }

    await _securityRepository.setPin(newPin);
    emit(state.copyWith(clearError: true));
    return true;
  }

  Future<void> toggleBiometrics(bool enabled) async {
    await _securityRepository.setBiometricsEnabled(enabled);
    emit(state.copyWith(isBiometricsEnabled: enabled));
  }
}
