import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_state.dart';
import 'package:my_budget_tracker/features/security/presentation/widgets/lock_screen.dart';

class MockSecurityCubit extends MockCubit<SecurityState> implements SecurityCubit {}

void main() {
  group('LockScreen Widget Tests', () {
    late SecurityCubit mockCubit;

    setUp(() {
      mockCubit = MockSecurityCubit();
      when(() => mockCubit.unlockWithPin(any())).thenAnswer((_) async => true);
      when(() => mockCubit.unlockWithBiometrics()).thenAnswer((_) async => true);
    });

    Widget buildTestWidget(SecurityState state) {
      when(() => mockCubit.state).thenReturn(state);

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<SecurityCubit>.value(
          value: mockCubit,
          child: const LockScreen(),
        ),
      );
    }

    testWidgets('renders locked header and numeric keypad (0-9)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SecurityState(
            isInitialized: true,
            isAppLockEnabled: true,
            hasPinSet: true,
            isLocked: true,
          ),
        ),
      );

      expect(find.text('Budget Tracker Locked'), findsOneWidget);
      expect(find.text('Enter PIN to continue'), findsOneWidget);

      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('tapping 4 digits calls unlockWithPin', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SecurityState(
            isInitialized: true,
            isAppLockEnabled: true,
            hasPinSet: true,
            isLocked: true,
          ),
        ),
      );

      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();

      verify(() => mockCubit.unlockWithPin('1234')).called(1);
    });

    testWidgets('shows error message when state has errorMessage', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SecurityState(
            isInitialized: true,
            isAppLockEnabled: true,
            hasPinSet: true,
            isLocked: true,
            errorMessage: 'Incorrect PIN. Please try again.',
          ),
        ),
      );

      expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
    });

    testWidgets('renders biometric button and triggers unlockWithBiometrics on mount and on tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SecurityState(
            isInitialized: true,
            isAppLockEnabled: true,
            hasPinSet: true,
            isBiometricsEnabled: true,
            isBiometricsAvailable: true,
            isLocked: true,
          ),
        ),
      );

      // Triggered once on initial build
      verify(() => mockCubit.unlockWithBiometrics()).called(1);

      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pump();

      // Triggered second time on button tap
      verify(() => mockCubit.unlockWithBiometrics()).called(1);
    });
  });
}
