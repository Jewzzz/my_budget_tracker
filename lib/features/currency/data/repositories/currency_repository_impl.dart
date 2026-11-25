import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/value_objects/iso_currency.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/repositories/currency_repository.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final AppDatabase database;
  final FlutterSecureStorage secureStorage;

  static const String keyPrimaryCurrency = 'pref_primary_reporting_currency';
  static const int _scaleFactor = 100000000; // 10^8

  final StreamController<String> _currencyController =
      StreamController<String>.broadcast();

  CurrencyRepositoryImpl({
    required this.database,
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<String> getPrimaryReportingCurrency() async {
    final value = await secureStorage.read(key: keyPrimaryCurrency);
    if (value != null && value.trim().isNotEmpty) {
      return value.trim().toUpperCase();
    }
    return Money.defaultCurrency;
  }

  @override
  Future<void> setPrimaryReportingCurrency(String currencyCode) async {
    final code = currencyCode.trim().toUpperCase();
    if (!IsoCurrency.isSupported(code)) {
      throw UnsupportedCurrencyFailure('Currency $currencyCode is not supported');
    }
    await secureStorage.write(key: keyPrimaryCurrency, value: code);
    _currencyController.add(code);
  }

  @override
  Stream<String> watchPrimaryReportingCurrency() async* {
    yield await getPrimaryReportingCurrency();
    yield* _currencyController.stream;
  }

  @override
  Future<List<ExchangeRate>> getExchangeRates() async {
    final rows = await database.select(database.exchangeRates).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<ExchangeRate>> watchExchangeRates() {
    return database
        .select(database.exchangeRates)
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<int?> getExchangeRateScaled({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    final base = baseCurrency.trim().toUpperCase();
    final target = targetCurrency.trim().toUpperCase();

    if (base == target) {
      return _scaleFactor;
    }

    // 1. Direct rate check
    final directRow = await (database.select(database.exchangeRates)
          ..where((tbl) =>
              tbl.baseCurrency.equals(base) & tbl.targetCurrency.equals(target)))
        .getSingleOrNull();

    if (directRow != null) {
      return directRow.rateScaled;
    }

    // 2. Inverse rate check
    final inverseRow = await (database.select(database.exchangeRates)
          ..where((tbl) =>
              tbl.baseCurrency.equals(target) & tbl.targetCurrency.equals(base)))
        .getSingleOrNull();

    if (inverseRow != null && inverseRow.rateScaled > 0) {
      final bigScale = BigInt.from(_scaleFactor);
      final bigInv = BigInt.from(inverseRow.rateScaled);
      final numerator = bigScale * bigScale;
      return (numerator ~/ bigInv).toInt();
    }

    // 3. Triangulation via USD
    if (base != 'USD' && target != 'USD') {
      final rateBaseToUsd = await getExchangeRateScaled(
        baseCurrency: base,
        targetCurrency: 'USD',
      );
      final rateUsdToTarget = await getExchangeRateScaled(
        baseCurrency: 'USD',
        targetCurrency: target,
      );

      if (rateBaseToUsd != null && rateUsdToTarget != null) {
        final big1 = BigInt.from(rateBaseToUsd);
        final big2 = BigInt.from(rateUsdToTarget);
        final bigScale = BigInt.from(_scaleFactor);
        return ((big1 * big2) ~/ bigScale).toInt();
      }
    }

    return null;
  }

  @override
  Future<Money> convertAmount({
    required Money amount,
    required String targetCurrency,
  }) async {
    final target = targetCurrency.trim().toUpperCase();
    if (amount.currencyCode.toUpperCase() == target) {
      return amount;
    }

    final rateScaled = await getExchangeRateScaled(
      baseCurrency: amount.currencyCode,
      targetCurrency: target,
    );

    if (rateScaled == null) {
      throw UnsupportedCurrencyFailure(
        'No exchange rate available from ${amount.currencyCode} to $target',
      );
    }

    return Money.convert(
      from: amount,
      toCurrency: target,
      rateScaled: rateScaled,
    );
  }

  @override
  Future<void> setExchangeRate({
    required String baseCurrency,
    required String targetCurrency,
    required int rateScaled,
  }) async {
    final base = baseCurrency.trim().toUpperCase();
    final target = targetCurrency.trim().toUpperCase();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    await database.into(database.exchangeRates).insertOnConflictUpdate(
          ExchangeRatesCompanion.insert(
            baseCurrency: base,
            targetCurrency: target,
            rateScaled: rateScaled,
            updatedAt: nowMs,
          ),
        );
  }

  ExchangeRate _toEntity(ExchangeRateRow row) {
    return ExchangeRate(
      baseCurrency: row.baseCurrency,
      targetCurrency: row.targetCurrency,
      rateScaled: row.rateScaled,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }
}
