import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/features/security/data/repositories/security_repository_impl.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:my_budget_tracker/features/security/presentation/widgets/app_lock_interceptor.dart';
import 'package:my_budget_tracker/features/security/presentation/widgets/lock_screen.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  group('Security End-to-End Integration Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late MockLocalAuthentication mockLocalAuth;
    late SecurityRepositoryImpl repository;
    late SecurityCubit securityCubit;

    final storage = <String, String>{};

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockLocalAuth = MockLocalAuthentication();
      storage.clear();

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return storage[key];
      });

      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String?;
        if (value != null) {
          storage[key] = value;
        } else {
          storage.remove(key);
        }
      });

      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        storage.remove(key);
      });

      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
          )).thenAnswer((_) async => true);

      repository = SecurityRepositoryImpl(
        secureStorage: mockStorage,
        localAuth: mockLocalAuth,
      );

      securityCubit = SecurityCubit(repository);
    });

    tearDown(() {
      securityCubit.close();
    });

    Widget buildTestApp() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<SecurityCubit>.value(
          value: securityCubit,
          child: const AppLockInterceptor(
            child: Scaffold(
              body: Center(
                child: Text('Confidential Financial Ledger'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('end-to-end security cycle: enable App Lock -> background app locks screen -> unlock with PIN', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Initially unlocked
      expect(find.text('Confidential Financial Ledger'), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);

      // 1. Enable App Lock with PIN "4321" (without auto-biometric unlock)
      await securityCubit.enableAppLock('4321', enableBiometrics: false);
      await tester.pumpAndSettle();

      expect(storage.containsKey(SecurityRepositoryImpl.keyPinHash), isTrue);
      expect(storage[SecurityRepositoryImpl.keyAppLockEnabled], 'true');

      // 2. Simulate app backgrounding (paused) and subsequent resume
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Verify Lock Screen intercepts the app
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('Budget Tracker Locked'), findsOneWidget);
      expect(find.text('Confidential Financial Ledger'), findsNothing);

      // 3. Enter wrong PIN "1111"
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Verify still locked with error feedback
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
      expect(find.text('Confidential Financial Ledger'), findsNothing);

      // 4. Enter correct PIN "4321"
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Verify unlocked and confidential data revealed
      expect(find.byType(LockScreen), findsNothing);
      expect(find.text('Confidential Financial Ledger'), findsOneWidget);
    });

    testWidgets('biometric authentication unlocks app on resume', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Enable App Lock with biometrics enabled
      await securityCubit.enableAppLock('4321', enableBiometrics: true);
      await tester.pumpAndSettle();

      // Background app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // On build, biometric authentication triggers and unlocks app
      await tester.pumpAndSettle();

      expect(find.byType(LockScreen), findsNothing);
      expect(find.text('Confidential Financial Ledger'), findsOneWidget);
    });
  });
}
