import 'package:flutter/material.dart';
import 'package:moneymanager/constants/colors.dart';

class AppSimpleHeader extends StatelessWidget {
  final String title;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const AppSimpleHeader({
    super.key,
    required this.title,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.padding = const EdgeInsets.only(bottom: 8),
  }) : assert(title != '');

  TextStyle _textStyle() {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(title, style: _textStyle()),
    );
  }
}
