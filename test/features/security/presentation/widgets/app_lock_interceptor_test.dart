import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_state.dart';
import 'package:my_budget_tracker/features/security/presentation/widgets/app_lock_interceptor.dart';
import 'package:my_budget_tracker/features/security/presentation/widgets/lock_screen.dart';

class MockSecurityCubit extends MockCubit<SecurityState> implements SecurityCubit {}

void main() {
  group('AppLockInterceptor Widget Tests', () {
    late SecurityCubit mockCubit;

    setUp(() {
      mockCubit = MockSecurityCubit();
      when(() => mockCubit.initialize()).thenAnswer((_) async {});
      when(() => mockCubit.lockApp()).thenReturn(null);
      when(() => mockCubit.unlockWithPin(any())).thenAnswer((_) async => true);
      when(() => mockCubit.unlockWithBiometrics()).thenAnswer((_) async => true);
    });

    Widget buildTestWidget(SecurityState state) {
      when(() => mockCubit.state).thenReturn(state);

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<SecurityCubit>.value(
          value: mockCubit,
          child: const AppLockInterceptor(
            child: Scaffold(
              body: Text('Protected Financial Data'),
            ),
          ),
        ),
      );
    }

    testWidgets('renders child content when app is unlocked', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SecurityState(
            isInitialized: true,
            isAppLockEnabled: true,
            hasPinSet: true,
            isLocked: false,
          ),
        ),
      );

      expect(find.text('Protected Financial Data'), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('intercepts and renders LockScreen when isLocked is true', (tester) async {
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

      expect(find.text('Protected Financial Data'), findsNothing);
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('Budget Tracker Locked'), findsOneWidget);
    });

    testWidgets('calls lockApp when app lifecycle enters paused state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SecurityState(
            isInitialized: true,
            isAppLockEnabled: true,
            hasPinSet: true,
            isLocked: false,
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      verify(() => mockCubit.lockApp()).called(1);
    });
  });
}
