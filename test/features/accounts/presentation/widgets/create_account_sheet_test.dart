import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_state.dart';
import 'package:my_budget_tracker/features/accounts/presentation/widgets/create_account_sheet.dart';
import 'package:my_budget_tracker/features/currency/domain/repositories/currency_repository.dart';
import 'package:my_budget_tracker/features/currency/presentation/cubit/currency_cubit.dart';

class MockAccountsCubit extends Mock implements AccountsCubit {}
class MockCurrencyRepository extends Mock implements CurrencyRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Account(
        id: 'fallback-id',
        name: 'Fallback',
        type: AccountType.checking,
        currencyCode: 'USD',
        initialBalance: Money.zero,
        currentBalance: Money.zero,
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  });

  group('CreateAccountSheet Widget Tests', () {
    late MockAccountsCubit mockAccountsCubit;
    late MockCurrencyRepository mockCurrencyRepo;
    late CurrencyCubit currencyCubit;

    setUp(() {
      mockAccountsCubit = MockAccountsCubit();
      mockCurrencyRepo = MockCurrencyRepository();

      when(() => mockAccountsCubit.state)
          .thenReturn(const AccountsLoaded(accounts: [], totalBalance: Money.zero));
      when(() => mockAccountsCubit.stream)
          .thenAnswer((_) => const Stream.empty());

      when(() => mockCurrencyRepo.getPrimaryReportingCurrency())
          .thenAnswer((_) async => 'USD');
      when(() => mockCurrencyRepo.getExchangeRates())
          .thenAnswer((_) async => []);
      when(() => mockCurrencyRepo.watchPrimaryReportingCurrency())
          .thenAnswer((_) => Stream.value('USD'));
      when(() => mockCurrencyRepo.watchExchangeRates())
          .thenAnswer((_) => Stream.value([]));

      currencyCubit = CurrencyCubit(mockCurrencyRepo);
      when(() => mockAccountsCubit.createAccount(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      currencyCubit.close();
    });

    testWidgets('renders currency selector and submits account with selected currency', (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: mockAccountsCubit),
            BlocProvider<CurrencyCubit>.value(value: currencyCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: CreateAccountSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Account Currency'), findsOneWidget);

      // Enter account name
      await tester.enterText(find.widgetWithText(TextFormField, 'Account Name'), 'Euro Travel Card');

      // Tap submit
      await tester.tap(find.text('Save Account'));
      await tester.pumpAndSettle();

      verify(() => mockAccountsCubit.createAccount(any(that: isA<Account>().having(
            (a) => a.name,
            'name',
            'Euro Travel Card',
          ).having(
            (a) => a.currencyCode,
            'currencyCode',
            'USD',
          )))).called(1);
    });
  });
}
