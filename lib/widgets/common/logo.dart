import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/generated/assets.dart';

class AppLogo extends StatelessWidget {
  final LogoType type;
  final double size;

  const AppLogo({
    super.key,
    this.type = LogoType.light,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final asset = type == LogoType.light
        ? Assets.imagesLogoLight
        : Assets.imagesLogoDark;

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
