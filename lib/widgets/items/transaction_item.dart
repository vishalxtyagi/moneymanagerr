import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/constants/styles.dart';
import 'package:moneymanager/models/category_model.dart';
import 'package:moneymanager/models/transaction_model.dart';
import 'package:moneymanager/utils/category_util.dart';
import 'package:moneymanager/utils/currency_util.dart';
import 'package:moneymanager/utils/context_util.dart';

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

  static final _dateFormatter = DateFormat('MMM dd');

  @override
  Widget build(BuildContext context) {
    
    // Cache frequently used values to avoid repeated computation
    final icon = CategoryUtil.getIconByIndex(category.iconIdx);
    final padding = context.responsiveValue(mobile: 16.0, tablet: 20.0, desktop: 24.0);
    final primaryFontSize = context.fontSize(16);
    final secondaryFontSize = context.fontSize(12);
    
    // Pre-format date and amount strings
    final dateText = _dateFormatter.format(transaction.date);
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
            SizedBox(width: context.spacing()),
            
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
                  SizedBox(height: context.spacing(0.25)),
                  
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
            SizedBox(width: context.spacing()),
            
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
                    padding: EdgeInsets.only(top: context.spacing(0.25)),
                    child: Icon(
                      Icons.note,
                      size: context.fontSize(14),
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
