import 'package:flutter/material.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/styles.dart';

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
    final themeColor = color ?? AppColors.primary;
    final backgroundColor = isSelected ? themeColor : AppColors.surface;
    final borderColor = isSelected ? themeColor : AppColors.border;
    final textColor = isSelected ? Colors.white : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        hoverColor: isSelected
            ? themeColor.withOpacity(0.1)
            : themeColor.withOpacity(0.05),
        splashColor: themeColor.withOpacity(0.2),
        highlightColor: themeColor.withOpacity(0.1),
        child: AnimatedContainer(
          duration: AppStyles.fastAnimation,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            border: Border.all(color: borderColor),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: themeColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
