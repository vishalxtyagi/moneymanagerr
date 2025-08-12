import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/constants/styles.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  @override
  Widget build(BuildContext context) {
    // Pre-calculate values to avoid lookups in build
    final dim = _buttonDimensions[size]!;
    final color = _buttonColors[type]!;
    final showBorder = type == ButtonType.outlined;
    
    // Pre-create button style to avoid recreation
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: color.bg,
      foregroundColor: color.fg,
      elevation: showBorder ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        side: showBorder
            ? const BorderSide(color: AppColors.primary)
            : BorderSide.none,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: dim.horizontalPadding,
        vertical: dim.verticalPadding,
      ),
    );

    return SizedBox(
      width: width,
      height: dim.height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: isLoading 
            ? _LoadingIndicator(color: color.fg)
            : _ButtonContent(
                text: text,
                icon: icon,
                dim: dim,
                color: color,
              ),
      ),
    );
  }
}

// Optimized loading indicator component
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.color});
  
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color,
      ),
    );
  }
}

// Optimized button content component
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.text,
    required this.icon,
    required this.dim,
    required this.color,
  });

  final String text;
  final IconData? icon;
  final _ButtonDimensions dim;
  final _ButtonColors color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: dim.iconSize, color: color.fg),
          ),
        Text(
          text,
          style: TextStyle(
            fontSize: dim.fontSize,
            fontWeight: FontWeight.w600,
            color: color.fg,
          ),
        ),
      ],
    );
  }
}

class _ButtonDimensions {
  final double height;
  final double fontSize;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;

  const _ButtonDimensions({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.horizontalPadding,
    required this.verticalPadding,
  });
}

class _ButtonColors {
  final Color bg;
  final Color fg;
  const _ButtonColors({required this.bg, required this.fg});
}

const _buttonDimensions = {
  ButtonSize.sm: _ButtonDimensions(
    height: 40,
    fontSize: 14,
    iconSize: 16,
    horizontalPadding: 16,
    verticalPadding: 8,
  ),
  ButtonSize.md: _ButtonDimensions(
    height: 48,
    fontSize: 16,
    iconSize: 18,
    horizontalPadding: 20,
    verticalPadding: 12,
  ),
  ButtonSize.lg: _ButtonDimensions(
    height: 56,
    fontSize: 18,
    iconSize: 20,
    horizontalPadding: 24,
    verticalPadding: 16,
  ),
};

const _buttonColors = {
  ButtonType.primary: _ButtonColors(
    bg: AppColors.primary,
    fg: AppColors.textOnPrimary,
  ),
  ButtonType.secondary: _ButtonColors(
    bg: AppColors.secondary,
    fg: AppColors.textOnPrimary,
  ),
  ButtonType.success: _ButtonColors(
    bg: AppColors.success,
    fg: AppColors.textOnPrimary,
  ),
  ButtonType.error: _ButtonColors(
    bg: AppColors.error,
    fg: AppColors.textOnPrimary,
  ),
  ButtonType.warning: _ButtonColors(
    bg: AppColors.warning,
    fg: AppColors.textOnPrimary,
  ),
  ButtonType.outlined: _ButtonColors(
    bg: Colors.transparent,
    fg: AppColors.primary,
  ),
  ButtonType.text: _ButtonColors(
    bg: Colors.transparent,
    fg: AppColors.primary,
  ),
};
