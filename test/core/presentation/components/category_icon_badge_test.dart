import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/presentation/components/category_icon_badge.dart';

void main() {
  group('CategoryIconBadge Component Tests', () {
    testWidgets('maps known icon strings to correct Outlined icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CategoryIconBadge(iconName: 'shopping_cart', color: Colors.green),
                CategoryIconBadge(iconName: 'restaurant', color: Colors.blue),
                CategoryIconBadge(iconName: 'account_balance', color: Colors.purple),
                CategoryIconBadge(iconName: 'unknown_icon_xyz', color: Colors.orange),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });

    testWidgets('renders different badge size variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CategoryIconBadge(
                  iconName: 'home',
                  color: Colors.blue,
                  size: CategoryBadgeSize.small,
                ),
                CategoryIconBadge(
                  iconName: 'home',
                  color: Colors.blue,
                  size: CategoryBadgeSize.medium,
                ),
                CategoryIconBadge(
                  iconName: 'home',
                  color: Colors.blue,
                  size: CategoryBadgeSize.large,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home_outlined), findsNWidgets(3));
    });
  });
}
