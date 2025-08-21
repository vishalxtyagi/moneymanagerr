import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/utils/currency_util.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/widgets/common/card.dart';

/// Optimized summary cards section - extracted and reusable
class AppSummaryCards extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final bool isDesktop;
  final VoidCallback? onIncomeCardTap;
  final VoidCallback? onExpenseCardTap;

  const AppSummaryCards({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    this.isDesktop = false,
    this.onIncomeCardTap,
    this.onExpenseCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final consumptionRate = income > 0 ? (expense / income) * 100 : 0;

    final summaryCards = [
      _SummaryCard(
        title: 'Balance',
        value: balance,
        color: balance >= 0 ? AppColors.success : AppColors.error,
        icon: Iconsax.wallet_3,
      ),
      _SummaryCard(
        title: 'Income',
        value: income,
        color: AppColors.success,
        icon: Iconsax.arrow_up_2,
        onTap: onIncomeCardTap,
      ),
      _SummaryCard(
        title: 'Expense',
        value: expense,
        color: AppColors.error,
        icon: Iconsax.arrow_down_2,
        onTap: onExpenseCardTap,
      ),
      _SummaryCard(
        title: 'Spend Rate',
        value: consumptionRate.toDouble(),
        color: AppColors.warning,
        icon: Iconsax.percentage_circle,
        isPercentage: true,
      ),
    ];

    if (isDesktop || context.isDesktop) {
      return Row(
        children: summaryCards.map((card) => Expanded(child: card)).toList(),
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: context.spacing(),
        mainAxisSpacing: context.spacing(),
        childAspectRatio: 1.35,
        children: summaryCards,
      );
    }
  }
}

/// Optimized individual summary card widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;
  final bool isPercentage;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isPercentage = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                fontSize: context.fontSize(14),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing()),
        Text(
          isPercentage
              ? '${value.toStringAsFixed(1)}%'
              : CurrencyUtil.formatCompact(value),
          style: TextStyle(
            overflow: TextOverflow.ellipsis,
            fontSize: context.fontSize(24),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );

    return AppCard(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: cardContent,
              ),
            )
          : cardContent,
    );
  }
}
