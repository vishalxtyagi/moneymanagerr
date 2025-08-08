import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/models/category_model.dart';
import 'package:moneymanager/core/models/transaction_model.dart';
import 'package:moneymanager/core/utils/category_util.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel category;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    final icon = CategoryUtil.getIconByIndex(category.iconIdx);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      child: Padding(
        padding: EdgeInsets.all(
          responsive.value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: category.color.withOpacity(0.1),
              child: Icon(
                icon,
                color: category.color,
                size: 20,
              ),
            ),
            SizedBox(width: responsive.spacing()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.spacing(scale: 0.25)),
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM dd').format(transaction.date),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: responsive.fontSize(12),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Flexible(
                        child: Text(
                          transaction.category,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: responsive.fontSize(12),
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
            SizedBox(width: responsive.spacing()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtil.formatSigned(
                      transaction.amount, transaction.type),
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.bold,
                    color: transaction.type == TransactionType.expense
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
                if ((transaction.note ?? '').isNotEmpty)
                  Padding(
                    padding:
                        EdgeInsets.only(top: responsive.spacing(scale: 0.25)),
                    child: Icon(
                      Icons.note,
                      size: responsive.fontSize(14),
                      color: AppColors.textDisabled,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
