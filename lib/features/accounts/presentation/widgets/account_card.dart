import 'package:flutter/material.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/account.dart';
import 'account_details_sheet.dart';

class AccountCard extends StatelessWidget {
  final Account account;

  const AccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = Color(account.color);
    final isNegative = account.currentBalance.isNegative;

    // Distinct account type badges
    final (Color badgeBg, Color badgeFg) = switch (account.type) {
      AccountType.checking => (
        theme.colorScheme.surfaceContainerHighest.withAlpha(160),
        theme.colorScheme.onSurfaceVariant
      ),
      AccountType.savings => (
        AppColors.savings.withAlpha(35),
        const Color(0xFFD97706) // Accessible Amber/Gold
      ),
      AccountType.creditCard => (
        Colors.purple.withAlpha(35),
        Colors.purple.shade700
      ),
      AccountType.cash => (
        AppColors.income.withAlpha(35),
        AppColors.income
      ),
    };

    return SizedBox(
      width: 190,
      child: AppCard(
        borderColor: isNegative ? theme.colorScheme.error.withAlpha(150) : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AccountDetailsSheet(account: account),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CategoryIconBadge(
                  iconName: account.icon,
                  color: cardColor,
                  size: CategoryBadgeSize.medium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    account.type.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyText(
                          amount: account.currentBalance,
                          autoColor: isNegative,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (isNegative) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
