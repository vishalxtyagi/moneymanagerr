import 'package:flutter/material.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/styles.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.initialValue,
    this.inputFormatters,
    this.showClearButton = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final bool showClearButton;

  @override
  Widget build(BuildContext context) {
    // Pre-calculate values to avoid computation in build
    final borderRadius = BorderRadius.circular(AppStyles.borderRadius);
    final fillColor = enabled ? AppColors.surface : AppColors.scaffoldBackground;
    
    // Determine the suffix icon - either clear button or custom suffixIcon
    Widget? effectiveSuffixIcon = suffixIcon;
    if (showClearButton && controller != null) {
      effectiveSuffixIcon = ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller!,
        builder: (context, value, child) {
          return value.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    controller!.clear();
                    onChanged?.call('');
                  },
                )
              : const SizedBox.shrink();
        },
      );
    }
    
    // Pre-create input decoration to avoid recreation
    final inputDecoration = InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: effectiveSuffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppStyles.sm,
        horizontal: AppStyles.sm,
      ),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.textDisabled),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optimized label with cached style
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Optimized text form field
        _CustomTextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          decoration: inputDecoration,
        ),
      ],
    );
  }
}

// Optimized text form field component
class _CustomTextFormField extends StatelessWidget {
  const _CustomTextFormField({
    required this.controller,
    required this.initialValue,
    required this.validator,
    required this.onChanged,
    required this.keyboardType,
    required this.obscureText,
    required this.maxLines,
    required this.maxLength,
    required this.enabled,
    required this.readOnly,
    required this.onTap,
    required this.inputFormatters,
    required this.decoration,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      decoration: decoration,
    );
  }
}
