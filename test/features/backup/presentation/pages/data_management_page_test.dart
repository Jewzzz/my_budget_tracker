import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/features/backup/presentation/cubit/data_management_cubit.dart';
import 'package:my_budget_tracker/features/backup/presentation/cubit/data_management_state.dart';
import 'package:my_budget_tracker/features/backup/presentation/pages/data_management_page.dart';

class MockDataManagementCubit extends MockCubit<DataManagementState> implements DataManagementCubit {}

void main() {
  group('DataManagementPage Widget Tests', () {
    late DataManagementCubit mockCubit;

    setUp(() {
      mockCubit = MockDataManagementCubit();
      when(() => mockCubit.exportBackup(share: any(named: 'share'))).thenAnswer((_) async {});
      when(() => mockCubit.exportTransactionsCsv(share: any(named: 'share'))).thenAnswer((_) async {});
      when(() => mockCubit.restoreFromSelectedFile(explicitContent: any(named: 'explicitContent')))
          .thenAnswer((_) async => true);
    });

    Widget buildTestWidget(DataManagementState state) {
      when(() => mockCubit.state).thenReturn(state);

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<DataManagementCubit>.value(
          value: mockCubit,
          child: const DataManagementPage(),
        ),
      );
    }

    testWidgets('renders all backup, restore, and CSV export options', (tester) async {
      await tester.pumpWidget(buildTestWidget(const DataManagementState()));

      expect(find.text('Data Backup & Export'), findsOneWidget);
      expect(find.text('Export Backup'), findsOneWidget);
      expect(find.text('Restore from Backup'), findsOneWidget);
      expect(find.text('Export Transactions (CSV)'), findsOneWidget);
    });

    testWidgets('tapping Export Backup calls cubit.exportBackup', (tester) async {
      await tester.pumpWidget(buildTestWidget(const DataManagementState()));

      await tester.tap(find.text('Export Backup'));
      await tester.pump();

      verify(() => mockCubit.exportBackup()).called(1);
    });

    testWidgets('tapping Export Transactions calls cubit.exportTransactionsCsv', (tester) async {
      await tester.pumpWidget(buildTestWidget(const DataManagementState()));

      await tester.tap(find.text('Export Transactions (CSV)'));
      await tester.pump();

      verify(() => mockCubit.exportTransactionsCsv()).called(1);
    });

    testWidgets('tapping Restore Backup opens confirmation dialog, and confirming triggers restore', (tester) async {
      await tester.pumpWidget(buildTestWidget(const DataManagementState()));

      await tester.tap(find.text('Restore from Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Restore Database Backup?'), findsOneWidget);
      expect(find.textContaining('This action will overwrite your current accounts'), findsOneWidget);

      await tester.tap(find.text('Proceed with Restore'));
      await tester.pumpAndSettle();

      verify(() => mockCubit.restoreFromSelectedFile()).called(1);
    });

    testWidgets('shows loading indicator when status is loading', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const DataManagementState(
            status: DataManagementStatus.loading,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when status is failure', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const DataManagementState(
            status: DataManagementStatus.failure,
            message: 'Checksum verification failed',
          ),
        ),
      );

      expect(find.textContaining('Checksum verification failed'), findsOneWidget);
    });
  });
}
