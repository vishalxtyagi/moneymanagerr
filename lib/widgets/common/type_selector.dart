import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/styles.dart';

class AppTypeSelector<T> extends StatelessWidget {
  final T selectedValue;
  final List<T> values;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;
  final Color Function(T)? colorBuilder;
  final ValueChanged<T> onChanged;

  const AppTypeSelector({
    super.key,
    required this.selectedValue,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
    this.iconBuilder,
    this.colorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: values
            .map((value) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: _TypeButton<T>(
                      value: value,
                      label: labelBuilder(value),
                      icon: iconBuilder?.call(value),
                      color: colorBuilder?.call(value),
                      isSelected: value == selectedValue,
                      onTap: () => onChanged(value),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _TypeButton<T> extends StatelessWidget {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    final textColor = isSelected ? Colors.white : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        hoverColor: isSelected 
            ? activeColor.withOpacity(0.1)
            : activeColor.withOpacity(0.05),
        splashColor: activeColor.withOpacity(0.2),
        highlightColor: activeColor.withOpacity(0.1),
        child: AnimatedContainer(
          duration: AppStyles.fastAnimation,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            boxShadow: isSelected ? [
              BoxShadow(
                color: activeColor.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 18,
                  color: textColor,
                ),
              if (icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
