import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/core/constants/colors.dart';

class CategoryUtil {
  CategoryUtil._();

  static const IconData defaultIcon = Iconsax.category;
  static const int defaultIconIndex = 0;

  static const List<IconData> availableIcons = [
    // General
    Iconsax.category,
    Iconsax.more,

    // Food & Dining
    Iconsax.cake,
    Iconsax.coffee,

    // Transportation
    Iconsax.car,
    Iconsax.gas_station,
    Iconsax.airplane,

    // Shopping & Entertainment
    Iconsax.shopping_bag,
    Iconsax.bag_2,
    Iconsax.game,

    // Bills & Utilities
    Iconsax.receipt_1,
    Iconsax.call,
    Iconsax.wifi,
    Iconsax.flash_1,
    Iconsax.drop,

    // Health & Personal
    Iconsax.health,
    Iconsax.heart,
    Iconsax.activity,

    // Education & Work
    Iconsax.teacher,
    Iconsax.building_4,
    Iconsax.profile_2user,

    // Home & Living
    Iconsax.home,
    Iconsax.home_2,
    Iconsax.shop,
    Iconsax.pet,

    // Finance & Income
    Iconsax.money_3,
    Iconsax.chart_21,
    Iconsax.gift,
    Iconsax.percentage_circle,
    Iconsax.security_safe,
  ];

  static IconData getIconByIndex(int index) {
    if (index < 0 || index >= availableIcons.length) {
      return availableIcons[0];
    }
    return availableIcons[index];
  }

  static int getIconIndex(IconData icon) {
    final index = availableIcons.indexOf(icon);
    return index == -1 ? 0 : index;
  }

  static Color getColor(String name) {
    const colors = AppColors.colorPalette;
    return colors[name.hashCode % colors.length];
  }
}
