import 'package:flutter/material.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/widgets/common/card.dart';

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    
    // Pre-calculate values to avoid computation in build
    final iconSize = context.fontSize(16);
    final spacing = context.spacing(0.5);
    final valueFontSize = context.fontSize(16);
    final titleFontSize = context.fontSize(12);
    
    // Pre-calculate colors
    final iconBgColor = color.withOpacity(0.1);
    
    // Build optimized content with cached values
    final content = _StatisticContent(
      title: title,
      value: value,
      icon: icon,
      color: color,
      iconSize: iconSize,
      spacing: spacing,
      valueFontSize: valueFontSize,
      titleFontSize: titleFontSize,
      iconBgColor: iconBgColor,
    );

    if (onTap == null) {
      return AppCard(child: content);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(child: content),
    );
  }
}

// Optimized content component
class _StatisticContent extends StatelessWidget {
  const _StatisticContent({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconSize,
    required this.spacing,
    required this.valueFontSize,
    required this.titleFontSize,
    required this.iconBgColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double iconSize;
  final double spacing;
  final double valueFontSize;
  final double titleFontSize;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: iconSize,
          backgroundColor: iconBgColor,
          child: Icon(icon, color: color, size: iconSize),
        ),
        SizedBox(height: spacing),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
