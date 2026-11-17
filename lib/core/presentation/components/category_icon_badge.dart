import 'package:flutter/material.dart';

enum CategoryBadgeSize {
  small(containerSize: 32, iconSize: 18),
  medium(containerSize: 40, iconSize: 20),
  large(containerSize: 48, iconSize: 24);

  final double containerSize;
  final double iconSize;

  const CategoryBadgeSize({
    required this.containerSize,
    required this.iconSize,
  });
}

class CategoryIconBadge extends StatelessWidget {
  final String iconName;
  final Color color;
  final CategoryBadgeSize size;

  const CategoryIconBadge({
    super.key,
    required this.iconName,
    required this.color,
    this.size = CategoryBadgeSize.medium,
  });

  static IconData resolveIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'work':
        return Icons.work_outlined;
      case 'trending_up':
        return Icons.trending_up_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'savings':
        return Icons.savings_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'payments':
        return Icons.payments_outlined;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'swap_horiz':
        return Icons.swap_horiz_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconData = resolveIcon(iconName);

    return Container(
      width: size.containerSize,
      height: size.containerSize,
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        size: size.iconSize,
        color: color,
      ),
    );
  }
}
