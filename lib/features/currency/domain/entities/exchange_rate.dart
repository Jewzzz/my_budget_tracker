import 'package:equatable/equatable.dart';

class ExchangeRate extends Equatable {
  final String baseCurrency;
  final String targetCurrency;
  final int rateScaled; // Multiplied by 10^8
  final DateTime updatedAt;

  const ExchangeRate({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rateScaled,
    required this.updatedAt,
  });

  double get rateAsDouble => rateScaled / 100000000.0;

  @override
  List<Object?> get props => [
        baseCurrency.toUpperCase(),
        targetCurrency.toUpperCase(),
        rateScaled,
        updatedAt,
      ];
}
