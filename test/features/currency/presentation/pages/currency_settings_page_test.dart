import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/features/currency/domain/entities/exchange_rate.dart';
import 'package:my_budget_tracker/features/currency/domain/repositories/currency_repository.dart';
import 'package:my_budget_tracker/features/currency/presentation/cubit/currency_cubit.dart';
import 'package:my_budget_tracker/features/currency/presentation/pages/currency_settings_page.dart';

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

void main() {
  group('CurrencySettingsPage Widget Tests', () {
    late MockCurrencyRepository mockRepo;
    late CurrencyCubit currencyCubit;

    setUp(() {
      mockRepo = MockCurrencyRepository();

      when(() => mockRepo.getPrimaryReportingCurrency())
          .thenAnswer((_) async => 'USD');
      when(() => mockRepo.getExchangeRates()).thenAnswer(
        (_) async => [
          ExchangeRate(
            baseCurrency: 'EUR',
            targetCurrency: 'USD',
            rateScaled: 108000000,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      when(() => mockRepo.watchPrimaryReportingCurrency())
          .thenAnswer((_) => Stream.value('USD'));
      when(() => mockRepo.watchExchangeRates()).thenAnswer(
        (_) => Stream.value([
          ExchangeRate(
            baseCurrency: 'EUR',
            targetCurrency: 'USD',
            rateScaled: 108000000,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ]),
      );
      when(() => mockRepo.setPrimaryReportingCurrency(any()))
          .thenAnswer((_) async {});

      currencyCubit = CurrencyCubit(mockRepo);
    });

    tearDown(() {
      currencyCubit.close();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<CurrencyCubit>.value(
          value: currencyCubit,
          child: const CurrencySettingsPage(),
        ),
      );
    }

    testWidgets('renders primary currency and exchange rates list', (tester) async {
      await currencyCubit.loadCurrencySettings();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Currency & Exchange Rates'), findsOneWidget);
      expect(find.text('Primary Reporting Currency'), findsOneWidget);
      expect(find.text('USD - US Dollar'), findsOneWidget);
      expect(find.text('EUR → USD'), findsOneWidget);
    });

    testWidgets('tapping primary reporting currency opens selection dialog and updates preference', (tester) async {
      await currencyCubit.loadCurrencySettings();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Primary Reporting Currency'));
      await tester.pumpAndSettle();

      expect(find.text('High-level dashboards, monthly budgets, and reports will consolidate into this currency.'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.setPrimaryReportingCurrency('USD')).called(1);
    });
  });
}
