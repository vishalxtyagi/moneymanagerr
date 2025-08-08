import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/styles.dart';

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) getLabel;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final String? hint;
  final Widget? prefixIcon;

  const AppDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.getLabel,
    required this.onChanged,
    this.validator,
    this.hint,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(getLabel(item)),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppStyles.sm,
              horizontal: AppStyles.sm,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
