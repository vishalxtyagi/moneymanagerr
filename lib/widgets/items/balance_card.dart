import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/models/analytics_model.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:moneymanager/core/utils/context_util.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.analytics});

  final AnalyticsModel analytics;

  @override
  Widget build(BuildContext context) {
    
    // Pre-calculate values to avoid computation in build
    final padding = context.spacing(1.5);
    final radius = context.spacing(1.25);
    final balanceFontSize = context.fontSize(36);
    final iconSize = context.fontSize(16);
    
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
              ),

              SizedBox(height: context.spacing(0.75)),

              // Balance amount with optimized text
              Text(
                balanceText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: balanceFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: context.spacing(1.25)),

              // Income & Expense Row with optimized layout
              _IncomeExpenseRow(
                expenseText: expenseText,
                incomeText: incomeText,
                iconSize: iconSize,
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
  });

  final ConsumptionData consumptionData;

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
  });

  final String expenseText;
  final String incomeText;
  final double iconSize;

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
                  SizedBox(width: context.spacing(0.25)),
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

        SizedBox(width: context.spacing(1.25)),

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
                  SizedBox(width: context.spacing(0.25)),
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
