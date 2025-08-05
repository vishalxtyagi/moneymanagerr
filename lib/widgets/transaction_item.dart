import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/models/transaction_model.dart';
import 'package:moneymanager/core/providers/category_provider.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:moneymanager/core/utils/responsive_helper.dart';
import 'package:moneymanager/core/utils/category_util.dart';
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
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(
              ResponsiveHelper.responsive(context, mobile: 16.0, tablet: 20.0, desktop: 24.0),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: CategoryUtil.getColor(transaction.category).withOpacity(0.1),
                  child: Icon(
                    Iconsax.category,
                    color: CategoryUtil.getColor(transaction.category),
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
                      CurrencyUtil.formatSigned(transaction.amount, transaction.type),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: transaction.type == 'expense' ? AppColors.error : AppColors.success,
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