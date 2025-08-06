import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/models/analytics_model.dart';
import 'package:moneymanager/core/providers/transaction_provider.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    final padding = responsive.spacing(scale: 1.5);
    final radius = responsive.spacing(scale: 1.25);
    final analytics = AnalyticsModel.from(context.read<TransactionProvider>(), null);

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
              // Header
              Row(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: analytics.consumptionData.color.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      analytics.consumptionData.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: responsive.spacing(scale: 0.75)),

              // Balance
              Text(
                CurrencyUtil.format(analytics.balance),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.fontSize(36),
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: responsive.spacing(scale: 1.25)),

              // Income & Expense Row
              Row(
                children: [
                  // Expense
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_downward,
                                color: Colors.white,
                                size: responsive.fontSize(16)),
                            SizedBox(width: responsive.spacing(scale: 0.25)),
                            Text('Expense', style: AppStyles.labelStyle),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyUtil.format(analytics.expense),
                          style: AppStyles.amountStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: responsive.spacing(scale: 1.25)),

                  // Income
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_upward,
                                color: Colors.white,
                                size: responsive.fontSize(16)),
                            SizedBox(width: responsive.spacing(scale: 0.25)),
                            Text('Income', style: AppStyles.labelStyle),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyUtil.format(analytics.income),
                          style: AppStyles.amountStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
