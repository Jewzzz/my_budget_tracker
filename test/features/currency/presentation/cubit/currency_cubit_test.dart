import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/currency/domain/entities/exchange_rate.dart';
import 'package:my_budget_tracker/features/currency/domain/repositories/currency_repository.dart';
import 'package:my_budget_tracker/features/currency/presentation/cubit/currency_cubit.dart';
import 'package:my_budget_tracker/features/currency/presentation/cubit/currency_state.dart';

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

void main() {
  group('CurrencyCubit Unit Tests', () {
    late MockCurrencyRepository mockRepository;

    final testRate = ExchangeRate(
      baseCurrency: 'USD',
      targetCurrency: 'EUR',
      rateScaled: 92000000,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      mockRepository = MockCurrencyRepository();

      when(() => mockRepository.getPrimaryReportingCurrency())
          .thenAnswer((_) async => 'USD');
      when(() => mockRepository.getExchangeRates())
          .thenAnswer((_) async => [testRate]);
      when(() => mockRepository.watchPrimaryReportingCurrency())
          .thenAnswer((_) => Stream.value('USD'));
      when(() => mockRepository.watchExchangeRates())
          .thenAnswer((_) => Stream.value([testRate]));
    });

    test('initial state is CurrencyState with default USD', () {
      final cubit = CurrencyCubit(mockRepository);
      expect(cubit.state.primaryCurrency, Money.defaultCurrency);
      expect(cubit.state.isLoading, isFalse);
    });

    blocTest<CurrencyCubit, CurrencyState>(
      'loadCurrencySettings emits loaded state with rates',
      build: () => CurrencyCubit(mockRepository),
      act: (cubit) => cubit.loadCurrencySettings(),
      expect: () => [
        const CurrencyState(isLoading: true),
        CurrencyState(
          primaryCurrency: 'USD',
          rates: [testRate],
          isLoading: false,
        ),
      ],
    );

    blocTest<CurrencyCubit, CurrencyState>(
      'setPrimaryCurrency calls repository and updates state',
      build: () {
        when(() => mockRepository.setPrimaryReportingCurrency('EUR'))
            .thenAnswer((_) async {});
        return CurrencyCubit(mockRepository);
      },
      act: (cubit) => cubit.setPrimaryCurrency('EUR'),
      expect: () => [
        const CurrencyState(primaryCurrency: 'EUR'),
      ],
      verify: (_) {
        verify(() => mockRepository.setPrimaryReportingCurrency('EUR')).called(1);
      },
    );

    blocTest<CurrencyCubit, CurrencyState>(
      'setExchangeRate calls repository with scaled rate',
      build: () {
        when(() => mockRepository.setExchangeRate(
              baseCurrency: 'USD',
              targetCurrency: 'LKR',
              rateScaled: 30000000000,
            )).thenAnswer((_) async {});
        return CurrencyCubit(mockRepository);
      },
      act: (cubit) => cubit.setExchangeRate(
        baseCurrency: 'USD',
        targetCurrency: 'LKR',
        rateScaled: 30000000000,
      ),
      verify: (_) {
        verify(() => mockRepository.setExchangeRate(
              baseCurrency: 'USD',
              targetCurrency: 'LKR',
              rateScaled: 30000000000,
            )).called(1);
      },
    );
  });
}
