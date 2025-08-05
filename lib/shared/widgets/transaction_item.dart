import 'package:flutter/material.dart';
import 'package:moneymanager/shared/models/transaction.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/utils/currency_helper.dart';
import 'package:moneymanager/utils/responsive_helper.dart';
import 'package:moneymanager/constants/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Padding(
            padding: EdgeInsets.all(
              ResponsiveHelper.responsive(context, mobile: 16.0, tablet: 20.0, desktop: 24.0),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: categoryProvider.getCategoryColor(transaction.category).withOpacity(0.1),
                  child: Icon(
                    categoryProvider.getCategoryIcon(transaction.category),
                    color: categoryProvider.getCategoryColor(transaction.category),
                    size: 20,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getSpacing(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 0.25)),
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM dd').format(transaction.date),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: ResponsiveHelper.getFontSize(context, 12),
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                          Flexible(
                            child: Text(
                              transaction.category,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: ResponsiveHelper.getFontSize(context, 12),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.formatSigned(transaction.amount, transaction.type),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: transaction.type == 'expense' ? AppColors.expense : AppColors.income,
                      ),
                    ),
                    if (transaction.note?.isNotEmpty == true)
                      Icon(
                        Icons.note,
                        size: ResponsiveHelper.getFontSize(context, 14),
                        color: AppColors.textDisabled,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}