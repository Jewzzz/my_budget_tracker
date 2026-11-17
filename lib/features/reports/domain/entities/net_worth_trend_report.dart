import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';

class NetWorthDataPoint extends Equatable {
  final DateTime date;
  final String label;
  final Money netWorth;

  const NetWorthDataPoint({
    required this.date,
    required this.label,
    required this.netWorth,
  });

  @override
  List<Object?> get props => [date, label, netWorth];
}

class NetWorthTrendReport extends Equatable {
  final Money currentNetWorth;
  final Money netChange;
  final List<NetWorthDataPoint> points;

  const NetWorthTrendReport({
    required this.currentNetWorth,
    required this.netChange,
    required this.points,
  });

  @override
  List<Object?> get props => [currentNetWorth, netChange, points];
}
