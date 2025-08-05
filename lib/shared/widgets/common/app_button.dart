import 'package:flutter/material.dart';
import 'package:moneymanager/constants/constants.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getButtonStyle(),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getTextColor(),
                ),
              )
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(text, style: _getTextStyle()),
        ],
      );
    }
    return Text(text, style: _getTextStyle());
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _getBackgroundColor(),
      foregroundColor: _getTextColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: type == ButtonType.outlined 
            ? BorderSide(color: _getBorderColor()) 
            : BorderSide.none,
      ),
      elevation: type == ButtonType.outlined ? 0 : 2,
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(),
        vertical: _getVerticalPadding(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case ButtonType.primary:
        return AppColors.primary;
      case ButtonType.secondary:
        return AppColors.secondary;
      case ButtonType.success:
        return AppColors.success;
      case ButtonType.error:
        return AppColors.error;
      case ButtonType.warning:
        return AppColors.warning;
      case ButtonType.outlined:
        return Colors.transparent;
      case ButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
      case ButtonType.success:
      case ButtonType.error:
      case ButtonType.warning:
        return AppColors.textOnPrimary;
      case ButtonType.outlined:
      case ButtonType.text:
        return AppColors.primary;
    }
  }

  Color _getBorderColor() {
    return AppColors.primary;
  }

  TextStyle _getTextStyle() {
    return TextStyle(
      fontSize: _getFontSize(),
      fontWeight: FontWeight.w600,
      color: _getTextColor(),
    );
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getVerticalPadding() {
    switch (size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 16;
    }
  }
}

enum ButtonType {
  primary,
  secondary,
  success,
  error,
  warning,
  outlined,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}
