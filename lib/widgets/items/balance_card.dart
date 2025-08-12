import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/models/analytics_model.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.analytics});

  final AnalyticsModel analytics;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    
    // Pre-calculate values to avoid computation in build
    final padding = responsive.spacing(scale: 1.5);
    final radius = responsive.spacing(scale: 1.25);
    final balanceFontSize = responsive.fontSize(36);
    final iconSize = responsive.fontSize(16);
    
    // Pre-format currency strings
    final balanceText = CurrencyUtil.format(analytics.balance);
    final expenseText = CurrencyUtil.format(analytics.expense);
    final incomeText = CurrencyUtil.format(analytics.income);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Ink(
        decoration: AppStyles.gradientDecoration,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with const styling
              _BalanceHeader(
                consumptionData: analytics.consumptionData,
                responsive: responsive,
              ),

              SizedBox(height: responsive.spacing(scale: 0.75)),

              // Balance amount with optimized text
              Text(
                balanceText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: balanceFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: responsive.spacing(scale: 1.25)),

              // Income & Expense Row with optimized layout
              _IncomeExpenseRow(
                expenseText: expenseText,
                incomeText: incomeText,
                iconSize: iconSize,
                responsive: responsive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Optimized header component
class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.consumptionData,
    required this.responsive,
  });

  final ConsumptionData consumptionData;
  final ResponsiveUtil responsive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total Balance',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: consumptionData.color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            consumptionData.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Optimized income/expense row component
class _IncomeExpenseRow extends StatelessWidget {
  const _IncomeExpenseRow({
    required this.expenseText,
    required this.incomeText,
    required this.iconSize,
    required this.responsive,
  });

  final String expenseText;
  final String incomeText;
  final double iconSize;
  final ResponsiveUtil responsive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Expense section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  SizedBox(width: responsive.spacing(scale: 0.25)),
                  const Text('Expense', style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                expenseText,
                style: AppStyles.amountStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        SizedBox(width: responsive.spacing(scale: 1.25)),

        // Income section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  SizedBox(width: responsive.spacing(scale: 0.25)),
                  const Text('Income', style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                incomeText,
                style: AppStyles.amountStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
