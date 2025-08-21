import 'package:flutter/material.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/constants/styles.dart';

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
    final showBorder = type == ButtonType.outlined || type == ButtonType.google;
    final borderColor =
        type == ButtonType.google ? Colors.grey.shade300 : AppColors.primary;
    final baseElevation =
        type == ButtonType.google ? 2.0 : (showBorder ? 0.0 : 2.0);

    // Pre-create button style with hover effects
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            if (type == ButtonType.outlined || type == ButtonType.google) {
              return color.bg == Colors.transparent
                  ? AppColors.primary.withOpacity(0.05)
                  : color.bg;
            }
            // Darken the background color slightly on hover
            return Color.lerp(color.bg, Colors.black, 0.1) ?? color.bg;
          }
          return color.bg;
        },
      ),
      foregroundColor: WidgetStateProperty.all<Color>(color.fg),
      elevation: WidgetStateProperty.resolveWith<double>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return baseElevation + 2.0;
          }
          if (states.contains(WidgetState.pressed)) {
            return baseElevation + 1.0;
          }
          return baseElevation;
        },
      ),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          side: showBorder ? BorderSide(color: borderColor) : BorderSide.none,
        ),
      ),
      padding: WidgetStateProperty.all<EdgeInsets>(
        EdgeInsets.symmetric(
          horizontal: dim.horizontalPadding,
          vertical: dim.verticalPadding,
        ),
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return type == ButtonType.outlined || type == ButtonType.google
                ? AppColors.primary.withOpacity(0.1)
                : Colors.white.withOpacity(0.2);
          }
          return null;
        },
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
            overflow: TextOverflow.ellipsis,
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
  ButtonType.google: _ButtonColors(
    bg: Colors.white,
    fg: Colors.black87,
  ),
};
