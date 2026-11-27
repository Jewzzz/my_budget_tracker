import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_state.dart';
import 'package:my_budget_tracker/features/accounts/presentation/widgets/dashboard_accounts_section.dart';

class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}

void main() {
  group('DashboardAccountsSection Widget Tests', () {
    late AccountsCubit cubit;

    final testAccount = Account(
      id: 'acc-1',
      name: 'Main Checking',
      type: AccountType.checking,
      initialBalance: const Money(50000), // $500.00
      currentBalance: const Money(50000),
      isArchived: false,
      icon: 'account_balance',
      color: 0xFF1E3A8A,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      cubit = MockAccountsCubit();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: BlocProvider<AccountsCubit>.value(
            value: cubit,
            child: const DashboardAccountsSection(),
          ),
        ),
      );
    }

    testWidgets('renders empty state when no accounts exist', (tester) async {
      when(() => cubit.state).thenReturn(
        const AccountsLoaded(
          accounts: [],
          totalBalance: Money.zero,
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('No Accounts Yet'), findsOneWidget);
      expect(find.text('Add Account'), findsNWidgets(2)); // Header action + Empty state button
    });

    testWidgets('renders total net worth and account card with balance', (tester) async {
      when(() => cubit.state).thenReturn(
        AccountsLoaded(
          accounts: [testAccount],
          totalBalance: const Money(50000),
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text(r'$ 500.00'), findsNWidgets(2)); // Total balance + Account card balance
      expect(find.text('Main Checking'), findsOneWidget);
      expect(find.text('Checking'), findsOneWidget);
    });
  });
}
