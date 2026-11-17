import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/features/security/domain/repositories/security_repository.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_state.dart';

class MockSecurityRepository extends Mock implements SecurityRepository {}

void main() {
  group('SecurityCubit Unit Tests', () {
    late SecurityRepository mockRepository;

    setUp(() {
      mockRepository = MockSecurityRepository();

      when(() => mockRepository.isAppLockEnabled()).thenAnswer((_) async => false);
      when(() => mockRepository.isBiometricsEnabled()).thenAnswer((_) async => false);
      when(() => mockRepository.canCheckBiometrics()).thenAnswer((_) async => true);
      when(() => mockRepository.hasPinSet()).thenAnswer((_) async => false);
      when(() => mockRepository.setAppLockEnabled(any())).thenAnswer((_) async {});
      when(() => mockRepository.setBiometricsEnabled(any())).thenAnswer((_) async {});
      when(() => mockRepository.setPin(any())).thenAnswer((_) async {});
      when(() => mockRepository.clearPin()).thenAnswer((_) async {});
    });

    test('initial state has default unlocked values', () {
      final cubit = SecurityCubit(mockRepository);
      expect(cubit.state, const SecurityState.initial());
      cubit.close();
    });

    blocTest<SecurityCubit, SecurityState>(
      'initialize loads repository flags and locks app when app lock is enabled with PIN set',
      build: () {
        when(() => mockRepository.isAppLockEnabled()).thenAnswer((_) async => true);
        when(() => mockRepository.hasPinSet()).thenAnswer((_) async => true);
        when(() => mockRepository.isBiometricsEnabled()).thenAnswer((_) async => true);
        when(() => mockRepository.canCheckBiometrics()).thenAnswer((_) async => true);
        return SecurityCubit(mockRepository);
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const SecurityState(
          isInitialized: true,
          isAppLockEnabled: true,
          hasPinSet: true,
          isBiometricsEnabled: true,
          isBiometricsAvailable: true,
          isLocked: true,
        ),
      ],
    );

    blocTest<SecurityCubit, SecurityState>(
      'unlockWithPin unlocks app when PIN is verified',
      build: () {
        when(() => mockRepository.verifyPin('1234')).thenAnswer((_) async => true);
        return SecurityCubit(mockRepository);
      },
      seed: () => const SecurityState(
        isInitialized: true,
        isAppLockEnabled: true,
        hasPinSet: true,
        isLocked: true,
      ),
      act: (cubit) => cubit.unlockWithPin('1234'),
      expect: () => [
        const SecurityState(
          isInitialized: true,
          isAppLockEnabled: true,
          hasPinSet: true,
          isLocked: false,
          errorMessage: null,
        ),
      ],
    );

    blocTest<SecurityCubit, SecurityState>(
      'unlockWithPin sets errorMessage and remains locked when PIN is incorrect',
      build: () {
        when(() => mockRepository.verifyPin('9999')).thenAnswer((_) async => false);
        return SecurityCubit(mockRepository);
      },
      seed: () => const SecurityState(
        isInitialized: true,
        isAppLockEnabled: true,
        hasPinSet: true,
        isLocked: true,
      ),
      act: (cubit) => cubit.unlockWithPin('9999'),
      expect: () => [
        const SecurityState(
          isInitialized: true,
          isAppLockEnabled: true,
          hasPinSet: true,
          isLocked: true,
          errorMessage: 'Incorrect PIN. Please try again.',
        ),
      ],
    );

    blocTest<SecurityCubit, SecurityState>(
      'unlockWithBiometrics unlocks app on successful biometric verification',
      build: () {
        when(() => mockRepository.authenticateBiometrics(reason: any(named: 'reason')))
            .thenAnswer((_) async => true);
        return SecurityCubit(mockRepository);
      },
      seed: () => const SecurityState(
        isInitialized: true,
        isAppLockEnabled: true,
        hasPinSet: true,
        isBiometricsEnabled: true,
        isBiometricsAvailable: true,
        isLocked: true,
      ),
      act: (cubit) => cubit.unlockWithBiometrics(),
      expect: () => [
        const SecurityState(
          isInitialized: true,
          isAppLockEnabled: true,
          hasPinSet: true,
          isBiometricsEnabled: true,
          isBiometricsAvailable: true,
          isLocked: false,
          errorMessage: null,
        ),
      ],
    );

    blocTest<SecurityCubit, SecurityState>(
      'lockApp engages lock when app lock is enabled',
      build: () => SecurityCubit(mockRepository),
      seed: () => const SecurityState(
        isInitialized: true,
        isAppLockEnabled: true,
        hasPinSet: true,
        isLocked: false,
      ),
      act: (cubit) => cubit.lockApp(),
      expect: () => [
        const SecurityState(
          isInitialized: true,
          isAppLockEnabled: true,
          hasPinSet: true,
          isLocked: true,
        ),
      ],
    );

    blocTest<SecurityCubit, SecurityState>(
      'lockApp does not lock when app lock is disabled',
      build: () => SecurityCubit(mockRepository),
      seed: () => const SecurityState(
        isInitialized: true,
        isAppLockEnabled: false,
        isLocked: false,
      ),
      act: (cubit) => cubit.lockApp(),
      expect: () => [],
    );

    blocTest<SecurityCubit, SecurityState>(
      'enableAppLock sets PIN and updates repository',
      build: () => SecurityCubit(mockRepository),
      act: (cubit) => cubit.enableAppLock('1234', enableBiometrics: true),
      expect: () => [
        const SecurityState(
          isInitialized: true,
          isAppLockEnabled: true,
          hasPinSet: true,
          isBiometricsEnabled: true,
          isLocked: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.setPin('1234')).called(1);
        verify(() => mockRepository.setAppLockEnabled(true)).called(1);
        verify(() => mockRepository.setBiometricsEnabled(true)).called(1);
      },
    );

    blocTest<SecurityCubit, SecurityState>(
      'disableAppLock verifies PIN and disables lock and clears stored PIN',
      build: () {
        when(() => mockRepository.verifyPin('1234')).thenAnswer((_) async => true);
        return SecurityCubit(mockRepository);
      },
      seed: () => const SecurityState(
        isInitialized: true,
        isAppLockEnabled: true,
        hasPinSet: true,
        isBiometricsEnabled: true,
        isLocked: false,
      ),
      act: (cubit) => cubit.disableAppLock('1234'),
      expect: () => [
        const SecurityState(
          isInitialized: true,
          isAppLockEnabled: false,
          hasPinSet: false,
          isBiometricsEnabled: false,
          isLocked: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.setAppLockEnabled(false)).called(1);
        verify(() => mockRepository.setBiometricsEnabled(false)).called(1);
        verify(() => mockRepository.clearPin()).called(1);
      },
    );
  });
}
