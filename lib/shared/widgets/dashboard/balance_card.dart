import 'package:flutter/material.dart';
import 'package:moneymanager/constants/app_colors.dart';
import 'package:moneymanager/utils/currency_helper.dart';
import 'package:moneymanager/utils/responsive_helper.dart';

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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.responsive(
            context,
            mobile: 20.0,
            tablet: 24.0,
            desktop: 28.0,
          ),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.responsive(
              context,
              mobile: 20.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveHelper.responsive(
              context,
              mobile: 24.0,
              tablet: 28.0,
              desktop: 32.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 0.75)),
              _buildBalanceAmount(context),
              SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 1.25)),
              _buildIncomeExpenseRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            color: (consumptionData['color'] as Color).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            consumptionData['text'] as String,
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

  Widget _buildBalanceAmount(BuildContext context) {
    return Text(
      CurrencyHelper.format(balance),
      style: TextStyle(
        color: Colors.white,
        fontSize: ResponsiveHelper.getFontSize(
          context,
          ResponsiveHelper.isDesktop(context) ? 48 : 36,
        ),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildIncomeExpenseRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildBalanceItem(
            'Expense',
            expense,
            Icons.arrow_downward,
            Colors.white,
            context,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context, scale: 1.25)),
        Expanded(
          child: _buildBalanceItem(
            'Income',
            income,
            Icons.arrow_upward,
            Colors.white,
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceItem(
    String title,
    double amount,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveHelper.getFontSize(context, 16),
            ),
            SizedBox(width: ResponsiveHelper.getSpacing(context, scale: 0.25)),
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: ResponsiveHelper.getFontSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyHelper.format(amount),
          style: TextStyle(
            color: color,
            fontSize: ResponsiveHelper.getFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
