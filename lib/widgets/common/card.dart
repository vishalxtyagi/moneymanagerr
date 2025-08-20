import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/utils/context_util.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(context.spacing(0.8));
    final contentPadding = padding ?? context.screenPadding;
    final cardColor = color ?? AppColors.card;
    final cardElevation = elevation ?? AppStyles.elevation;

    final cardContent = Card(
      color: cardColor,
      elevation: cardElevation,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Padding(
        padding: contentPadding,
        child: child,
      ),
    );

    if (onTap == null) {
      return cardContent;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: cardContent,
    );
  }
}
