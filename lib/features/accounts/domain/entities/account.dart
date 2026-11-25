import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';

enum AccountType {
  checking,
  savings,
  cash,
  creditCard;

  String get displayName {
    switch (this) {
      case AccountType.checking:
        return 'Checking';
      case AccountType.savings:
        return 'Savings';
      case AccountType.cash:
        return 'Cash';
      case AccountType.creditCard:
        return 'Credit Card';
    }
  }

  static AccountType fromString(String value) {
    return AccountType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AccountType.checking,
    );
  }
}

class Account extends Equatable {
  final String id;
  final String name;
  final AccountType type;
  final String currencyCode;
  final Money initialBalance;
  final Money currentBalance;
  final bool isArchived;
  final String icon;
  final int color;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.currencyCode = Money.defaultCurrency,
    required this.initialBalance,
    required this.currentBalance,
    this.isArchived = false,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  /// Enforces the mathematical balance invariant:
  /// Current balance must equal initial balance + net transactional movements.
  static Money calculateExpectedBalance({
    required Money initialBalance,
    required Money netMovements,
  }) {
    return initialBalance + netMovements;
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? currencyCode,
    Money? initialBalance,
    Money? currentBalance,
    bool? isArchived,
    String? icon,
    int? color,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isArchived: isArchived ?? this.isArchived,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        currencyCode,
        initialBalance,
        currentBalance,
        isArchived,
        icon,
        color,
        createdAt,
      ];
}
