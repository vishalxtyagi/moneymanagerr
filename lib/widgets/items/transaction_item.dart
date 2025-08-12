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
  const TransactionItem({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
  });

  final TransactionModel transaction;
  final CategoryModel category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    
    // Cache frequently used values to avoid repeated computation
    final icon = CategoryUtil.getIconByIndex(category.iconIdx);
    final padding = responsive.value(mobile: 16.0, tablet: 20.0, desktop: 24.0);
    final primaryFontSize = responsive.fontSize(16);
    final secondaryFontSize = responsive.fontSize(12);
    
    // Pre-format date and amount strings
    final dateText = DateFormat('MMM dd').format(transaction.date);
    final amountText = CurrencyUtil.formatSigned(transaction.amount, transaction.type);
    
    // Pre-determine colors
    final amountColor = transaction.type == TransactionType.expense
        ? AppColors.error
        : AppColors.success;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            // Category Icon with optimized decoration
            CircleAvatar(
              radius: 20,
              backgroundColor: category.color.withOpacity(0.1),
              child: Icon(icon, color: category.color, size: 20),
            ),
            SizedBox(width: responsive.spacing()),
            
            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontSize: primaryFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.spacing(scale: 0.25)),
                  
                  // Date and Category row with optimized layout
                  Row(
                    children: [
                      Text(
                        dateText,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: secondaryFontSize,
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
                            fontSize: secondaryFontSize,
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
            
            // Amount and Note with const conditions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: primaryFontSize,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                if ((transaction.note ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: responsive.spacing(scale: 0.25)),
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
