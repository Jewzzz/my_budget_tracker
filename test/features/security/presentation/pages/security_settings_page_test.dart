import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_state.dart';
import 'package:my_budget_tracker/features/security/presentation/pages/security_settings_page.dart';

class MockSecurityCubit extends MockCubit<SecurityState> implements SecurityCubit {}

void main() {
  group('SecuritySettingsPage Widget Tests', () {
    late SecurityCubit mockCubit;

    setUp(() {
      mockCubit = MockSecurityCubit();
      when(() => mockCubit.enableAppLock(any(), enableBiometrics: any(named: 'enableBiometrics')))
          .thenAnswer((_) async {});
      when(() => mockCubit.disableAppLock(any())).thenAnswer((_) async => true);
      when(() => mockCubit.toggleBiometrics(any())).thenAnswer((_) async {});
    });

    Widget buildTestWidget(SecurityState state) {
      when(() => mockCubit.state).thenReturn(state);

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<SecurityCubit>.value(
          value: mockCubit,
          child: const SecuritySettingsPage(),
        ),
      );
    }

    testWidgets('renders security settings with App Lock and Biometric options', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SecurityState(
            isInitialized: true,
            isAppLockEnabled: false,
            hasPinSet: false,
            isBiometricsAvailable: true,
          ),
        ),
      );

      expect(find.text('Security Settings'), findsOneWidget);
      expect(find.text('App Lock'), findsOneWidget);
      expect(find.text('Biometric Unlock'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('shows Change PIN option when App Lock is enabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SecurityState(
            isInitialized: true,
            isAppLockEnabled: true,
            hasPinSet: true,
            isBiometricsAvailable: true,
          ),
        ),
      );

      expect(find.text('Change PIN'), findsOneWidget);
    });
  });
}
