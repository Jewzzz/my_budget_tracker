import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/features/security/data/repositories/security_repository_impl.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  group('SecurityRepositoryImpl Unit Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late MockLocalAuthentication mockLocalAuth;
    late SecurityRepositoryImpl repository;

    final storageMap = <String, String>{};

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockLocalAuth = MockLocalAuthentication();
      storageMap.clear();

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return storageMap[key];
      });

      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String?;
        if (value != null) {
          storageMap[key] = value;
        } else {
          storageMap.remove(key);
        }
      });

      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        storageMap.remove(key);
      });

      repository = SecurityRepositoryImpl(
        secureStorage: mockStorage,
        localAuth: mockLocalAuth,
      );
    });

    group('PIN Management', () {
      test('hasPinSet returns false when no PIN is stored', () async {
        expect(await repository.hasPinSet(), isFalse);
      });

      test('setPin validates 4-to-6 digit format and securely stores salted hash', () async {
        await repository.setPin('1234');

        expect(await repository.hasPinSet(), isTrue);
        expect(storageMap.containsKey(SecurityRepositoryImpl.keyPinHash), isTrue);
        expect(storageMap.containsKey(SecurityRepositoryImpl.keyPinSalt), isTrue);

        // Raw PIN must never be stored in plain text
        expect(storageMap.containsValue('1234'), isFalse);
      });

      test('setPin throws ArgumentError if PIN is invalid format', () async {
        expect(() => repository.setPin('12'), throwsArgumentError);
        expect(() => repository.setPin('1234567'), throwsArgumentError);
        expect(() => repository.setPin('abcd'), throwsArgumentError);
      });

      test('verifyPin returns true for correct PIN and false for incorrect PIN', () async {
        await repository.setPin('5678');

        expect(await repository.verifyPin('5678'), isTrue);
        expect(await repository.verifyPin('1234'), isFalse);
        expect(await repository.verifyPin('56789'), isFalse);
      });

      test('clearPin removes stored hash and salt', () async {
        await repository.setPin('1234');
        expect(await repository.hasPinSet(), isTrue);

        await repository.clearPin();
        expect(await repository.hasPinSet(), isFalse);
        expect(storageMap.containsKey(SecurityRepositoryImpl.keyPinHash), isFalse);
        expect(storageMap.containsKey(SecurityRepositoryImpl.keyPinSalt), isFalse);
      });
    });

    group('App Lock & Biometrics Toggles', () {
      test('isAppLockEnabled defaults to false and persists updates', () async {
        expect(await repository.isAppLockEnabled(), isFalse);

        await repository.setAppLockEnabled(true);
        expect(await repository.isAppLockEnabled(), isTrue);

        await repository.setAppLockEnabled(false);
        expect(await repository.isAppLockEnabled(), isFalse);
      });

      test('isBiometricsEnabled defaults to false and persists updates', () async {
        expect(await repository.isBiometricsEnabled(), isFalse);

        await repository.setBiometricsEnabled(true);
        expect(await repository.isBiometricsEnabled(), isTrue);

        await repository.setBiometricsEnabled(false);
        expect(await repository.isBiometricsEnabled(), isFalse);
      });
    });

    group('Biometric Authentication', () {
      test('canCheckBiometrics delegates to LocalAuthentication hardware checks', () async {
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);

        expect(await repository.canCheckBiometrics(), isTrue);

        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        expect(await repository.canCheckBiometrics(), isFalse);
      });

      test('authenticateBiometrics delegates to LocalAuthentication.authenticate', () async {
        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              biometricOnly: any(named: 'biometricOnly'),
            )).thenAnswer((_) async => true);

        final result = await repository.authenticateBiometrics(
          reason: 'Unlock Budget Tracker',
        );

        expect(result, isTrue);
        verify(() => mockLocalAuth.authenticate(
              localizedReason: 'Unlock Budget Tracker',
              biometricOnly: true,
            )).called(1);
      });
    });
  });
}
