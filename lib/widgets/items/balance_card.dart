import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final Map<String, dynamic> consumptionData;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    required this.consumptionData,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    final padding = responsive.value(mobile: 24.0, tablet: 28.0, desktop: 32.0);
    final radius = responsive.value(mobile: 20.0, tablet: 24.0, desktop: 28.0);

    final Color tagColor = (consumptionData['color'] as Color).withOpacity(0.8);
    final String tagText = consumptionData['text'] as String;

    final TextStyle labelStyle = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: responsive.fontSize(14),
      fontWeight: FontWeight.w500,
    );

    final TextStyle amountStyle = TextStyle(
      color: Colors.white,
      fontSize: responsive.fontSize(18),
      fontWeight: FontWeight.bold,
    );

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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tagText,
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
                CurrencyUtil.format(balance),
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
                            Icon(Icons.arrow_downward, color: Colors.white, size: responsive.fontSize(16)),
                            SizedBox(width: responsive.spacing(scale: 0.25)),
                            Text('Expense', style: labelStyle),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyUtil.format(expense),
                          style: amountStyle,
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
                            Icon(Icons.arrow_upward, color: Colors.white, size: responsive.fontSize(16)),
                            SizedBox(width: responsive.spacing(scale: 0.25)),
                            Text('Income', style: labelStyle),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyUtil.format(income),
                          style: amountStyle,
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
