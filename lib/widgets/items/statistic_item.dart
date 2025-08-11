import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';
import 'package:moneymanager/widgets/common/card.dart';

class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    final iconSize = responsive.fontSize(16);
    final spacing = responsive.spacing(scale: 0.5);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: iconSize,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: iconSize),
        ),
        SizedBox(height: spacing),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(16),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: responsive.fontSize(12),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return AppCard(child: content);
    }

    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
