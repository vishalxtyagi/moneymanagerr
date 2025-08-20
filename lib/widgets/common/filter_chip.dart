import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/utils/context_util.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? context.colors.primary;
    final backgroundColor = isSelected ? themeColor : Colors.grey.shade100;
    final borderColor = isSelected ? themeColor : Colors.grey.shade300;
    final textColor = isSelected ? Colors.white : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      child: AnimatedContainer(
        duration: AppStyles.fastAnimation,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
